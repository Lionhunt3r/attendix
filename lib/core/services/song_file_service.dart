import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../providers/tenant_providers.dart';

/// Service for managing song file uploads to Supabase Storage
class SongFileService {
  final SupabaseClient _supabase;
  final int? _tenantId;

  SongFileService(this._supabase, this._tenantId);

  static const String _bucketName = 'songs';

  /// Pick a file (PDF, PNG, JPG)
  Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: kIsWeb, // For web, we need bytes
    );

    if (result == null || result.files.isEmpty) return null;
    return result.files.first;
  }

  /// Generate a safe filename
  String _encodeFilename(String filename) {
    final ext = filename.split('.').last;
    String name = filename.substring(0, filename.length - ext.length - 1);

    // Sanitize the filename
    name = name
        .replaceAll(RegExp(r'[\u0300-\u036f]'), '') // Remove diacritics
        .replaceAll(RegExp(r'[^\w\s-]'), '-') // Replace non-word chars
        .replaceAll(RegExp(r'\s+'), '-') // Replace spaces
        .replaceAll(RegExp(r'-+'), '-') // Multiple hyphens to single
        .replaceAll(RegExp(r'^-+|-+$'), ''); // Trim hyphens

    // Add random number
    final randomNumber = 100 + (DateTime.now().millisecondsSinceEpoch % 900);
    return '${name}_$randomNumber.$ext';
  }

  /// Upload a file to Supabase Storage
  /// Returns the public URL of the uploaded file
  Future<String> uploadFile({
    required int songId,
    required PlatformFile file,
    int? instrumentId,
    String? note,
  }) async {
    if (_tenantId == null) {
      throw Exception('Kein Tenant ausgewählt');
    }

    // Generate unique storage path
    final fileId = _encodeFilename(file.name);
    final storagePath = 'songs/$_tenantId/$songId/$fileId';

    // Get file bytes
    Uint8List fileBytes;
    if (kIsWeb) {
      if (file.bytes == null) {
        throw Exception('Datei-Bytes nicht verfügbar');
      }
      fileBytes = file.bytes!;
    } else {
      if (file.path == null) {
        throw Exception('Dateipfad nicht verfügbar');
      }
      fileBytes = await File(file.path!).readAsBytes();
    }

    // Upload to storage
    await _supabase.storage.from(_bucketName).uploadBinary(
          storagePath,
          fileBytes,
          fileOptions: FileOptions(
            contentType: _getContentType(file.extension ?? 'pdf'),
            upsert: true,
          ),
        );

    // Get public URL
    final url = _supabase.storage.from(_bucketName).getPublicUrl(storagePath);

    // Get current song to update files array
    final songResponse = await _supabase
        .from('songs')
        .select('files')
        .eq('id', songId)
        .eq('tenantId', _tenantId)
        .single();

    // Build new files array
    final existingFiles = (songResponse['files'] as List?) ?? [];
    final newFile = {
      'storageName': fileId,
      'fileName': file.name,
      'fileType': file.extension ?? 'pdf',
      'url': url,
      'instrumentId': instrumentId,
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
    };

    final updatedFiles = [...existingFiles, newFile];

    // Update song with new files array
    await _supabase.from('songs').update({
      'files': updatedFiles,
    }).eq('id', songId).eq('tenantId', _tenantId);

    return url;
  }

  /// Delete a file from storage and song's files array
  Future<void> deleteFile({
    required int songId,
    required String storageName,
  }) async {
    if (_tenantId == null) {
      throw Exception('Kein Tenant ausgewählt');
    }

    // Delete from storage
    final storagePath = 'songs/$_tenantId/$songId/$storageName';
    try {
      await _supabase.storage.from(_bucketName).remove([storagePath]);
    } catch (e) {
      // File might not exist in storage, continue anyway
    }

    // Get current song files
    final songResponse = await _supabase
        .from('songs')
        .select('files')
        .eq('id', songId)
        .eq('tenantId', _tenantId)
        .single();

    final existingFiles = (songResponse['files'] as List?) ?? [];

    // Remove the file from the array
    final updatedFiles = existingFiles
        .where((f) => f['storageName'] != storageName)
        .toList();

    // Update song
    await _supabase.from('songs').update({
      'files': updatedFiles,
    }).eq('id', songId).eq('tenantId', _tenantId);
  }

  /// Delete all files from a song
  Future<void> deleteAllFiles({required int songId}) async {
    if (_tenantId == null) {
      throw Exception('Kein Tenant ausgewählt');
    }

    // Get current song files
    final songResponse = await _supabase
        .from('songs')
        .select('files')
        .eq('id', songId)
        .eq('tenantId', _tenantId)
        .single();

    final existingFiles = (songResponse['files'] as List?) ?? [];

    // Delete each file from storage
    for (final file in existingFiles) {
      final storageName = file['storageName'] as String?;
      if (storageName != null) {
        final storagePath = 'songs/$_tenantId/$songId/$storageName';
        try {
          await _supabase.storage.from(_bucketName).remove([storagePath]);
        } catch (e) {
          // File might not exist in storage, continue anyway
        }
      }
    }

    // Clear files array
    await _supabase.from('songs').update({
      'files': [],
    }).eq('id', songId).eq('tenantId', _tenantId);
  }

  /// Update file category (instrumentId and note)
  Future<void> updateFileCategory({
    required int songId,
    required String storageName,
    int? instrumentId,
    String? note,
  }) async {
    if (_tenantId == null) {
      throw Exception('Kein Tenant ausgewählt');
    }

    // Get current song files
    final songResponse = await _supabase
        .from('songs')
        .select('files')
        .eq('id', songId)
        .eq('tenantId', _tenantId)
        .single();

    final existingFiles = List<Map<String, dynamic>>.from(
      (songResponse['files'] as List?) ?? [],
    );

    // Update the matching file
    for (var i = 0; i < existingFiles.length; i++) {
      if (existingFiles[i]['storageName'] == storageName) {
        existingFiles[i] = {
          ...existingFiles[i],
          'instrumentId': instrumentId,
          'note': note,
        };
        break;
      }
    }

    // Update song
    await _supabase.from('songs').update({
      'files': existingFiles,
    }).eq('id', songId).eq('tenantId', _tenantId);
  }

  /// Pick multiple files
  Future<List<PlatformFile>?> pickMultipleFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'mp3', 'wav', 'ogg', 'm4a'],
      allowMultiple: true,
      withData: kIsWeb,
    );

    if (result == null || result.files.isEmpty) return null;
    return result.files;
  }

  /// Download a file's bytes (for saving locally)
  Future<Uint8List?> downloadFileBytes(String url) async {
    try {
      // Extract storage path from URL
      // URL format: https://xxx.supabase.co/storage/v1/object/public/songs/...
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Find 'songs' in path and get everything after
      final songsIndex = pathSegments.indexOf('songs');
      if (songsIndex == -1 || songsIndex >= pathSegments.length - 1) {
        return null;
      }

      final storagePath = pathSegments.sublist(songsIndex).join('/');
      return await _supabase.storage.from(_bucketName).download(
        storagePath.replaceFirst('songs/', ''),
      );
    } catch (e, stack) {
      debugPrint('Error downloading file: $e\n$stack');
      return null;
    }
  }

  /// Get content type for file
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }
}

/// Provider for SongFileService
final songFileServiceProvider = Provider<SongFileService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);
  return SongFileService(supabase, tenant?.id);
});
