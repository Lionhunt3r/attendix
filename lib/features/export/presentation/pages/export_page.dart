import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/tenant_providers.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/attendance/attendance.dart';
import '../../../../data/repositories/attendance_repository.dart';
import '../../../../data/repositories/player_repository.dart';

/// Default fields for player export
const _defaultPlayerFields = ['Vorname', 'Nachname', 'Geburtsdatum', 'Gruppe'];
const _defaultAttendanceFields = ['Vorname', 'Nachname', 'Gruppe'];

/// All available fields
const _allFields = [
  'Vorname',
  'Nachname',
  'Geburtsdatum',
  'Gruppe',
  'Email',
  'Telefon',
];

/// Export Page
///
/// Allows exporting player lists and attendance data to PDF or Excel.
class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({super.key});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  String _exportType = 'pdf';
  String _contentType = 'player';
  List<String> _selectedFields = [..._defaultPlayerFields];
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Export type selector
            _buildSection(
              title: 'Format',
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'pdf', label: Text('PDF')),
                  ButtonSegment(value: 'excel', label: Text('Excel')),
                ],
                selected: {_exportType},
                onSelectionChanged: (value) {
                  setState(() => _exportType = value.first);
                },
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),

            // Content type selector
            _buildSection(
              title: 'Inhalt',
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'player', label: Text('Spielerliste')),
                  ButtonSegment(value: 'attendance', label: Text('Anwesenheit')),
                ],
                selected: {_contentType},
                onSelectionChanged: (value) {
                  setState(() {
                    _contentType = value.first;
                    _selectedFields = value.first == 'player'
                        ? [..._defaultPlayerFields]
                        : [..._defaultAttendanceFields];
                  });
                },
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),

            // Field selection
            _buildSection(
              title: 'Felder',
              child: Column(
                children: [
                  // Selected fields (reorderable)
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedFields.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = _selectedFields.removeAt(oldIndex);
                        _selectedFields.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final field = _selectedFields[index];
                      return Card(
                        key: ValueKey(field),
                        margin: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          leading: const Icon(Icons.drag_handle),
                          title: Text(field),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              setState(() {
                                _selectedFields.remove(field);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Add field button
                  PopupMenuButton<String>(
                    onSelected: (field) {
                      setState(() {
                        if (!_selectedFields.contains(field)) {
                          _selectedFields.add(field);
                        }
                      });
                    },
                    itemBuilder: (context) {
                      return _allFields
                          .where((f) => !_selectedFields.contains(f))
                          .map((f) => PopupMenuItem(
                                value: f,
                                child: Text(f),
                              ))
                          .toList();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.medium),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add),
                          SizedBox(width: 8),
                          Text('Feld hinzufügen'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingXL),

            // Export button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _export,
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_exportType == 'pdf'
                        ? Icons.picture_as_pdf
                        : Icons.table_chart),
                label: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Text(_isExporting ? 'Exportiere...' : 'Exportieren'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.medium,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Future<void> _export() async {
    if (_selectedFields.isEmpty) {
      ToastHelper.showError(context, 'Bitte mindestens ein Feld auswählen');
      return;
    }

    setState(() => _isExporting = true);

    try {
      final tenant = ref.read(currentTenantProvider);
      final tenantName = tenant?.shortName ?? 'Export';

      // Load data
      final playerRepo = ref.read(playerRepositoryProvider);
      final tenantId = ref.read(currentTenantIdProvider);

      if (tenantId == null) {
        throw Exception('Kein Tenant ausgewählt');
      }

      playerRepo.setTenantId(tenantId);
      final players = await playerRepo.getPlayers();

      // Filter active players
      final activePlayers = players
          .where((p) => (p.left == null || p.left!.isEmpty) && !p.paused)
          .toList();

      final exportService = ExportService();

      if (_contentType == 'player') {
        if (_exportType == 'pdf') {
          await exportService.exportPlayerListPdf(
            context: context,
            players: activePlayers,
            fields: _selectedFields,
            tenantName: tenantName,
          );
        } else {
          final bytes = await exportService.exportPlayerListExcel(
            players: activePlayers,
            fields: _selectedFields,
            tenantName: tenantName,
          );
          await _saveAndShareExcel(bytes, '${tenantName}_Spielerliste');
        }
      } else {
        // Load attendance data
        final attendanceRepo = ref.read(attendanceRepositoryProvider);
        attendanceRepo.setTenantId(tenantId);

        final attendances = await attendanceRepo.getAttendances(
          since: DateTime.now().subtract(const Duration(days: 365)),
          limit: 100,
        );

        // Filter past attendances
        final now = DateTime.now();
        final pastAttendances = attendances.where((a) {
          final date = DateTime.tryParse(a.date);
          return date != null && date.isBefore(now);
        }).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        // Load person attendances
        final supabase = ref.read(supabaseClientProvider);
        final attendanceIds =
            pastAttendances.map((a) => a.id).whereType<int>().toList();

        List<PersonAttendance> personAttendances = [];
        if (attendanceIds.isNotEmpty) {
          final response = await supabase
              .from('person_attendances')
              .select()
              .inFilter('attendance_id', attendanceIds);

          personAttendances = (response as List)
              .map((e) => PersonAttendance.fromJson(e))
              .toList();
        }

        if (_exportType == 'pdf') {
          await exportService.exportAttendancePdf(
            context: context,
            players: activePlayers,
            attendances: pastAttendances,
            personAttendances: personAttendances,
            fields: _selectedFields,
            tenantName: tenantName,
          );
        } else {
          final bytes = await exportService.exportAttendanceExcel(
            players: activePlayers,
            attendances: pastAttendances,
            personAttendances: personAttendances,
            fields: _selectedFields,
            tenantName: tenantName,
          );
          await _saveAndShareExcel(bytes, '${tenantName}_Anwesenheit');
        }
      }

      if (mounted) {
        ToastHelper.showSuccess(context, 'Export erfolgreich');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler beim Export: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _saveAndShareExcel(List<int> bytes, String baseName) async {
    final date = DateFormat('dd_MM_yyyy').format(DateTime.now());
    final fileName = '${baseName}_$date.xlsx';

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: fileName,
    );
  }
}
