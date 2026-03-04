import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';

/// Utility class for converting between Quill Delta JSON and Document objects.
///
/// Handles three input formats:
/// - Quill Delta JSON array: `[{"insert":"Hello\n"}]`
/// - Quill Delta JSON object: `{"ops":[{"insert":"Hello\n"}]}`
/// - Plain text fallback for legacy data
class QuillUtils {
  QuillUtils._();

  /// Creates a [Document] from a notes string stored in the database.
  ///
  /// Supports:
  /// - `null` or empty → empty Document
  /// - JSON array `[{"insert":"..."}]` → Quill Delta
  /// - JSON object `{"ops":[...]}` → Quill Delta
  /// - Plain text → Document with text content
  static Document documentFromNotesString(String? notes) {
    if (notes == null || notes.trim().isEmpty) {
      return Document();
    }

    try {
      final trimmed = notes.trim();
      final decoded = jsonDecode(trimmed);

      if (decoded is List) {
        // Array form: [{"insert":"Hello\n"}]
        return Document.fromJson(decoded.cast<Map<String, dynamic>>());
      } else if (decoded is Map) {
        // Object form: {"ops":[{"insert":"Hello\n"}]}
        final ops = decoded['ops'];
        if (ops is List) {
          return Document.fromJson(ops.cast<Map<String, dynamic>>());
        }
      }
    } catch (_) {
      // Not valid JSON — treat as plain text
    }

    // Plain text fallback
    return Document()..insert(0, notes);
  }

  /// Serializes a [Document] back to a JSON string for database storage.
  ///
  /// Returns the ops array as a JSON string (compatible with quill.js),
  /// or `null` if the document is empty.
  static String? notesStringFromDocument(Document doc) {
    if (isDocumentEmpty(doc)) return null;
    return jsonEncode(doc.toDelta().toJson());
  }

  /// Checks whether a [Document] is effectively empty (only contains a newline).
  static bool isDocumentEmpty(Document doc) {
    final delta = doc.toDelta();
    if (delta.isEmpty) return true;
    // A "blank" Quill document has exactly one insert op with just "\n"
    if (delta.length == 1) {
      final op = delta.first;
      if (op.isInsert && op.data == '\n') return true;
    }
    return false;
  }
}
