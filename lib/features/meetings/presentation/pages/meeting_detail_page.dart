import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/meeting_providers.dart';
import '../../../../core/providers/conductor_providers.dart';
import '../../../../core/providers/player_providers.dart';
import '../../../../core/providers/tenant_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/person/person.dart';
import '../../../../shared/widgets/loading/list_skeleton.dart';

/// Meeting detail page for viewing/editing a meeting
class MeetingDetailPage extends ConsumerStatefulWidget {
  const MeetingDetailPage({super.key, required this.meetingId});

  final int meetingId;

  @override
  ConsumerState<MeetingDetailPage> createState() => _MeetingDetailPageState();
}

class _MeetingDetailPageState extends ConsumerState<MeetingDetailPage> {
  bool _isEditMode = false;
  final _notesController = TextEditingController();
  List<int> _selectedAttendeeIds = [];
  bool _hasChanges = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _initializeFromMeeting() {
    final meetingAsync = ref.read(meetingByIdProvider(widget.meetingId));
    meetingAsync.whenData((meeting) {
      if (meeting != null && !_hasChanges) {
        _notesController.text = meeting.notes ?? '';
        _selectedAttendeeIds = List.from(meeting.attendeeIds ?? []);
        // Auto-enable edit mode if no notes yet
        if (meeting.notes == null || meeting.notes!.isEmpty) {
          setState(() => _isEditMode = true);
        }
      }
    });
  }

  Future<void> _save() async {
    final notifier = ref.read(meetingNotifierProvider.notifier);
    final result = await notifier.updateMeeting(
      widget.meetingId,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      attendeeIds: _selectedAttendeeIds,
    );

    if (result != null && mounted) {
      ToastHelper.showSuccess(context, 'Sitzung gespeichert');
      setState(() {
        _isEditMode = false;
        _hasChanges = false;
      });
    } else if (mounted) {
      ToastHelper.showError(context, 'Fehler beim Speichern');
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetingAsync = ref.watch(meetingByIdProvider(widget.meetingId));
    final tenant = ref.watch(currentTenantProvider);
    final isGeneral = tenant?.type == 'general';

    // Use conductors for orchestra/choir, all players for general tenants
    final attendeesAsync = isGeneral
        ? ref.watch(playersProvider)
        : ref.watch(activeConductorsProvider);

    // Initialize form values when meeting loads
    ref.listen(meetingByIdProvider(widget.meetingId), (previous, next) {
      _initializeFromMeeting();
    });

    return Scaffold(
      appBar: AppBar(
        title: meetingAsync.whenOrNull(
          data: (meeting) => meeting != null
              ? Text(DateFormat('dd.MM.yyyy').format(DateTime.parse(meeting.date)))
              : const Text('Sitzung'),
        ) ?? const Text('Sitzung'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditMode = true),
              tooltip: 'Bearbeiten',
            ),
        ],
      ),
      body: meetingAsync.when(
        loading: () => const ListSkeleton(itemCount: 3),
        error: (e, _) => _buildErrorState(e),
        data: (meeting) {
          if (meeting == null) {
            return _buildNotFoundState();
          }

          // Initialize on first load
          if (!_hasChanges && _selectedAttendeeIds.isEmpty && (meeting.attendeeIds?.isNotEmpty ?? false)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _notesController.text = meeting.notes ?? '';
                  _selectedAttendeeIds = List.from(meeting.attendeeIds ?? []);
                });
              }
            });
          }

          return attendeesAsync.when(
            loading: () => const ListSkeleton(itemCount: 3),
            error: (e, _) => _buildErrorState(e),
            data: (attendees) => _buildContent(meeting.date, attendees),
          );
        },
      ),
      floatingActionButton: _isEditMode
          ? FloatingActionButton.extended(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Speichern'),
            )
          : null,
    );
  }

  Widget _buildContent(String date, List<Person> availableAttendees) {
    // RT-005: Use safe pattern instead of invalid default object
    final selectedNames = _selectedAttendeeIds
        .map((id) {
          final person = availableAttendees.where((p) => p.id == id).firstOrNull;
          return person != null
              ? '${person.firstName} ${person.lastName}'.trim()
              : 'Unbekannt';
        })
        .join(', ');

    if (_isEditMode) {
      return _buildEditMode(availableAttendees);
    }

    return _buildViewMode(selectedNames);
  }

  Widget _buildViewMode(String attendeeNames) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attendees section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppDimensions.paddingS),
                      Text(
                        'Anwesende Personen',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(
                    attendeeNames.isNotEmpty ? attendeeNames : 'Keine Teilnehmer ausgewählt',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: attendeeNames.isEmpty ? AppColors.medium : null,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),

          // Notes section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notes, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppDimensions.paddingS),
                      Text(
                        'Notizen',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(
                    _notesController.text.isNotEmpty
                        ? _notesController.text
                        : 'Keine Notizen vorhanden',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _notesController.text.isEmpty ? AppColors.medium : null,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode(List<Person> availableAttendees) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attendees selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppDimensions.paddingS),
                      Text(
                        'Anwesende Personen',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  Wrap(
                    spacing: AppDimensions.paddingS,
                    runSpacing: AppDimensions.paddingS,
                    children: availableAttendees
                        .where((person) => person.id != null) // BL-001: Filter out invalid persons
                        .map((person) {
                      final isSelected = _selectedAttendeeIds.contains(person.id);
                      return FilterChip(
                        label: Text('${person.firstName} ${person.lastName}'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _hasChanges = true;
                            if (selected) {
                              _selectedAttendeeIds.add(person.id!);
                            } else {
                              _selectedAttendeeIds.remove(person.id);
                            }
                          });
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                  if (availableAttendees.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
                      child: Text(
                        'Keine Personen verfügbar',
                        style: TextStyle(color: AppColors.medium),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),

          // Notes editor
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notes, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppDimensions.paddingS),
                      Text(
                        'Notizen',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Notizen eingeben...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 10,
                    minLines: 5,
                    onChanged: (_) => setState(() => _hasChanges = true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
          const SizedBox(height: AppDimensions.paddingM),
          Text('Fehler: $error'),
          const SizedBox(height: AppDimensions.paddingM),
          ElevatedButton(
            onPressed: () => ref.invalidate(meetingByIdProvider(widget.meetingId)),
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 64, color: AppColors.medium),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            'Sitzung nicht gefunden',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Zurück'),
          ),
        ],
      ),
    );
  }
}
