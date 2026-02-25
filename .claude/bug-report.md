# Bug Report - Attendix
Generiert: 2026-02-25
Scope: Full Codebase Scan

## Zusammenfassung

| Kategorie | KRITISCH | HOCH | MITTEL | NIEDRIG | Gesamt |
|-----------|----------|------|--------|---------|--------|
| Security | 4 | 4 | 3 | 1 | 12 |
| Business-Logik | 2 | 3 | 4 | 3 | 12 |
| Funktional | 2 | 4 | 5 | 4 | 15 |
| Runtime | 3 | 7 | 7 | 4 | 21 |
| **Gesamt** | **11** | **18** | **19** | **12** | **60** |

## Handlungsempfehlungen

1. **SOFORT:** 11 kritische Bugs fixen (besonders Multi-Tenant Security SEC-001, SEC-002, SEC-004!)
2. **Diese Woche:** 18 hohe Bugs fixen
3. **Backlog:** 31 mittlere/niedrige Bugs

---

## KRITISCH

### SEC-001: createPersonAttendances ohne tenantId-Validierung
- **Kategorie:** Security / Multi-Tenant
- **Datei:** `lib/data/repositories/attendance_repository.dart:189-209`
- **Problem:** Die Methode fuegt person_attendances ohne tenant-Validierung ein. Angreifer kann beliebige attendance_id/person_id Kombinationen angeben.
- **Impact:** Cross-Tenant Datenmanipulation
- **Fix:** Vor Insert validieren dass attendance_id zum currentTenantId gehoert
- **Status:** [ ] Offen

### SEC-002: CrossTenantService.getPersonAttendancesForTenant ohne tenantId-Filter
- **Kategorie:** Security / Multi-Tenant
- **Datei:** `lib/core/services/cross_tenant_service.dart:60-88`
- **Problem:** Query filtert nur nach person_id, nicht nach tenantId. Der tenantId Parameter wird gar nicht verwendet!
- **Impact:** Cross-Tenant Datenleck - Anwesenheitsdaten aller Tenants auslesbar
- **Fix:** `.eq('attendance.tenantId', tenantId)` hinzufuegen
- **Status:** [ ] Offen

### SEC-003: statistics_providers - person_attendances ohne tenantId-Filter
- **Kategorie:** Security / Multi-Tenant
- **Datei:** `lib/core/providers/statistics_providers.dart:92-97`
- **Problem:** Query auf person_attendances verwendet nur inFilter ohne direkte tenant-Validierung
- **Impact:** Information Disclosure bei manipulierten attendanceIds
- **Fix:** Defense-in-Depth: `.eq('attendance.tenantId', tenantId)` hinzufuegen
- **Status:** [ ] Offen

### SEC-004: linkTenantToOrganisation ohne Berechtigungspruefung
- **Kategorie:** Security / Authorization
- **Datei:** `lib/data/repositories/organisation_repository.dart:35-44`
- **Problem:** Jeder Benutzer kann beliebige Tenants zu Organisationen hinzufuegen ohne Admin-Check
- **Impact:** Privilege Escalation - Zugriff auf fremde Tenants
- **Fix:** Pruefen ob User Admin-Rolle fuer tenantId hat
- **Status:** [ ] Offen

### RT-001: Force Unwrap auf `_config` ohne ausreichenden Guard
- **Kategorie:** Runtime / Null-Safety
- **Datei:** `lib/features/notifications/presentation/pages/notifications_page.dart:71`
- **Problem:** Race condition - `_config` kann zwischen Check und Verwendung null werden
- **Impact:** App-Crash
- **Fix:** Lokale Variable nach null-Check verwenden
- **Status:** [ ] Offen

### RT-002: Force Unwrap auf `segment!` ohne Guard
- **Kategorie:** Runtime / Null-Safety
- **Datei:** `lib/features/shifts/presentation/widgets/shift_preview_sheet.dart:306-310`
- **Problem:** `segment!` nach null-Check, aber Race Condition moeglich
- **Impact:** App-Crash
- **Fix:** Lokale Variable verwenden
- **Status:** [ ] Offen

### RT-003: `int.parse()` auf Time-String ohne Validierung
- **Kategorie:** Runtime / Type-Safety
- **Datei:** `lib/features/attendance/presentation/pages/attendance_create_page.dart:762-763`
- **Problem:** FormatException wenn startTime nicht "HH:MM" Format hat
- **Impact:** App-Crash bei fehlerhaften Daten
- **Fix:** `int.tryParse()` mit Fallback verwenden
- **Status:** [ ] Offen

### BL-001: Unsichere `.first` Zugriffe ohne Pruefung auf leere Liste
- **Kategorie:** Business-Logik / Null-Safety
- **Dateien:**
  - `lib/features/planning/presentation/pages/planning_page.dart:167-168`
  - `lib/features/parents/presentation/pages/parents_portal_page.dart:317`
  - `lib/core/services/song_file_service.dart:28`
  - `lib/features/self_service/presentation/widgets/song_options_sheet.dart:89-90`
  - `lib/features/settings/presentation/pages/attendance_type_edit_page.dart:99`
  - `lib/features/attendance/presentation/pages/attendance_create_page.dart:158`
  - `lib/features/songs/presentation/pages/song_detail_page.dart:1005-1007`
- **Problem:** `.first` auf Listen ohne vorherige Pruefung oder mit Race Condition
- **Impact:** App-Crash mit `StateError: No element`
- **Fix:** `firstOrNull` verwenden oder Guard direkt vor Zugriff
- **Status:** [ ] Offen

### BL-002: Division durch Null in Statistik-Berechnungen
- **Kategorie:** Business-Logik / Runtime
- **Datei:** `lib/core/providers/statistics_providers.dart:546`
- **Problem:** `reduce()` auf potentiell leerer Liste ohne Check
- **Impact:** Runtime Error
- **Fix:** `isNotEmpty` Check vor `reduce()`
- **Status:** [ ] Offen

### FN-001: TextEditingController Memory Leak in Dialogen
- **Kategorie:** Funktional / Memory
- **Dateien:**
  - `lib/features/shifts/presentation/pages/shifts_list_page.dart:128-129`
  - `lib/features/planning/presentation/pages/planning_page.dart:500-502`
  - `lib/features/shifts/presentation/pages/shift_detail_page.dart:449-453`
  - `lib/features/settings/presentation/pages/general_settings_page.dart:704, 847`
  - `lib/features/people/presentation/pages/people_list_page.dart:572`
- **Problem:** Controller werden in Dialogen lokal erstellt aber nie disposed
- **Impact:** Memory Leak, potentieller Crash bei langem Gebrauch
- **Fix:** StatefulBuilder mit dispose oder eigenes StatefulWidget
- **Status:** [ ] Offen

### FN-002: Fehlende Form-Validierung vor Submit in Dialog
- **Kategorie:** Funktional / UX
- **Datei:** `lib/features/shifts/presentation/pages/shifts_list_page.dart:163-166`
- **Problem:** TextFields haben keine validator, User bekommt kein Feedback
- **Impact:** Schlechte UX
- **Fix:** TextFormField mit validator und Form-Key
- **Status:** [ ] Offen

---

## HOCH

### SEC-005: Organisation-Queries ohne Zugriffsvalidierung
- **Kategorie:** Security / Authorization
- **Datei:** `lib/data/repositories/organisation_repository.dart:96-111`
- **Problem:** `getInstancesOfOrganisation()` prueft nicht ob User Mitglied ist
- **Impact:** Information Disclosure
- **Fix:** Zugriffspruefung hinzufuegen
- **Status:** [ ] Offen

### SEC-006: getAllPersonsFromOrganisation ohne granulare Berechtigung
- **Kategorie:** Security / Multi-Tenant
- **Datei:** `lib/data/repositories/organisation_repository.dart:114-135`
- **Problem:** Laedt alle Personen aus allen Tenants einer Organisation
- **Impact:** Mass Data Exposure
- **Fix:** Nur zugaengliche Tenants zurueckgeben
- **Status:** [ ] Offen

### SEC-007: getLinkedTenants laedt alle tenant_group_tenants
- **Kategorie:** Security / Information Disclosure
- **Datei:** `lib/data/repositories/organisation_repository.dart:201-228`
- **Problem:** Laedt ALLE tenant_group_tenants ohne Filterung
- **Impact:** Organisationsstruktur aller Tenants exponiert
- **Fix:** Nur eigene tenant_groups laden
- **Status:** [ ] Offen

### SEC-008: self_service_providers ohne tenantId Filter
- **Kategorie:** Security / Multi-Tenant
- **Datei:** `lib/core/providers/self_service_providers.dart:166-181`
- **Problem:** Query filtert nur nach appId, nicht nach tenantId
- **Impact:** Identitaetsverwechslung zwischen Tenants
- **Fix:** tenantId-Filter hinzufuegen
- **Status:** [ ] Offen

### RT-004: `DateTime.parse()` ohne try-catch auf DB-Daten
- **Kategorie:** Runtime / Type-Safety
- **Datei:** `lib/core/services/holiday_service.dart:109-110`
- **Problem:** FormatException bei ungueltigem Datumsformat
- **Impact:** App-Crash
- **Fix:** `DateTime.tryParse()` verwenden
- **Status:** [ ] Offen

### RT-005: `.firstWhere()` orElse erstellt invalides Default-Objekt
- **Kategorie:** Runtime / Type-Safety
- **Datei:** `lib/features/meetings/presentation/pages/meeting_detail_page.dart:146-152`
- **Problem:** Default Person mit `tenantId: 0` kann DB-Probleme verursachen
- **Impact:** Dateninkonsistenz
- **Fix:** `firstWhereOrNull` verwenden
- **Status:** [ ] Offen

### RT-006: Force Unwrap `_profileData!` nach async Operation
- **Kategorie:** Runtime / Null-Safety
- **Datei:** `lib/features/profile/presentation/pages/profile_page.dart:92-94, 141`
- **Problem:** Race condition bei schnellem Screen-Wechsel
- **Impact:** App-Crash
- **Fix:** Null-safe Zugriff `_profileData?['firstName'] ?? ''`
- **Status:** [ ] Offen

### RT-009: `tenant!.id!` Double Force Unwrap
- **Kategorie:** Runtime / Null-Safety
- **Datei:** `lib/core/providers/tenant_providers.dart:107`
- **Problem:** Double Force Unwrap kann crashen
- **Impact:** App-Crash
- **Fix:** Lokale Variable mit null-Check
- **Status:** [ ] Offen

### RT-010: `organisation!.id!` Double Force Unwrap
- **Kategorie:** Runtime / Null-Safety
- **Datei:** `lib/data/repositories/organisation_repository.dart:187`
- **Problem:** Race condition bei concurrent DB-Operationen
- **Impact:** App-Crash
- **Fix:** Lokale Variable verwenden
- **Status:** [ ] Offen

### RT-007: `_copyInfos![index]` ohne Bounds-Check
- **Kategorie:** Runtime / Collection
- **Datei:** `lib/features/songs/presentation/widgets/smart_print_dialog.dart:64, 202`
- **Problem:** IndexOutOfBoundsException moeglich
- **Impact:** App-Crash
- **Fix:** Bounds-Check oder defensive Kopie
- **Status:** [ ] Offen

### RT-008: `widget.song.files![i]` ohne Length-Check
- **Kategorie:** Runtime / Collection
- **Datei:** `lib/features/songs/presentation/widgets/copy_to_tenant_sheet.dart:292`
- **Problem:** Concurrent modification moeglich
- **Impact:** App-Crash
- **Fix:** Lokale Kopie erstellen
- **Status:** [ ] Offen

### BL-003: Fehlende Rollen-Pruefung in Meetings UI
- **Kategorie:** Business-Logik / Authorization
- **Datei:** `lib/features/meetings/presentation/pages/meetings_list_page.dart:85-89`
- **Problem:** FAB zum Erstellen wird fuer alle Rollen angezeigt
- **Impact:** Schlechte UX (Aktion scheitert auf Backend)
- **Fix:** `role.canEdit` Check hinzufuegen
- **Status:** [ ] Offen

### BL-004: `_savePlan` ohne tenantId Validierung
- **Kategorie:** Business-Logik / Security
- **Datei:** `lib/features/planning/presentation/pages/planning_page.dart:567-582`
- **Problem:** Update ohne tenantId im WHERE-Clause
- **Impact:** Potentielle Cross-Tenant Manipulation
- **Fix:** `.eq('tenantId', tenantId)` hinzufuegen
- **Status:** [ ] Offen

### BL-005: Meeting-Erstellung ohne Duplikat-Check
- **Kategorie:** Business-Logik / Validation
- **Datei:** `lib/data/repositories/meeting_repository.dart:52-71`
- **Problem:** Keine Pruefung ob Meeting am gleichen Datum existiert
- **Impact:** Versehentliche Duplikate
- **Fix:** `meetingExistsOnDate()` Check hinzufuegen
- **Status:** [ ] Offen

### FN-003: Inkonsistente Verwendung von context.pop vs Navigator.pop
- **Kategorie:** Funktional / Navigation
- **Dateien:**
  - `lib/features/shifts/presentation/pages/shifts_list_page.dart:159`
  - `lib/features/planning/presentation/pages/planning_page.dart:535,544,735,790`
  - `lib/features/notifications/presentation/pages/notifications_page.dart:292`
- **Problem:** Mischung von go_router und Navigator kann zu unerwartetem Verhalten fuehren
- **Impact:** Navigation-Bugs
- **Fix:** Konsistent Navigator.pop fuer Dialoge, context.pop fuer Pages
- **Status:** [ ] Offen

### FN-004: ref.refresh() statt ref.invalidate() in RefreshIndicator
- **Kategorie:** Funktional / State Management
- **Dateien:**
  - `lib/features/people/presentation/pages/people_list_page.dart:387, 468`
  - `lib/features/attendance/presentation/pages/attendance_list_page.dart:188`
  - `lib/features/instruments/presentation/pages/instruments_list_page.dart:88`
- **Problem:** RefreshIndicator schliesst zu frueh
- **Impact:** UX - User denkt Refresh ist fertig
- **Fix:** `ref.invalidate()` + `await ref.read(provider.future)`
- **Status:** [ ] Offen

### FN-005: Fehlende key bei ListView.builder Items
- **Kategorie:** Funktional / Widget
- **Datei:** `lib/features/shifts/presentation/pages/shifts_list_page.dart:61-68`
- **Problem:** Widgets koennen falsch wiederverwendet werden
- **Impact:** UI-Glitches bei Listen-Updates
- **Fix:** `key: ValueKey(item.id)` hinzufuegen
- **Status:** [ ] Offen

### FN-006: context.mounted Check inkonsistent
- **Kategorie:** Funktional / Async
- **Datei:** `lib/features/tenant_selection/presentation/pages/tenant_selection_page.dart:141`
- **Problem:** Mischung von Extension und State.mounted
- **Impact:** Potentielle Laufzeitfehler
- **Fix:** Konsistent `if (mounted)` in StatefulWidget verwenden
- **Status:** [ ] Offen

---

## MITTEL

### SEC-009: Debug-Logs mit sensitiven Daten
- **Kategorie:** Security / Data Exposure
- **Dateien:** `lib/data/repositories/base_repository.dart:27-28`, `lib/core/providers/tenant_providers.dart:95-96`
- **Problem:** Stack Traces in Production-Logs
- **Fix:** In Production keine Stack Traces loggen
- **Status:** [ ] Offen

### SEC-010: Router erlaubt /register/:id ohne Auth
- **Kategorie:** Security / Authentication
- **Datei:** `lib/core/router/app_router.dart:68-71`
- **Problem:** Tenant-ID Enumeration moeglich
- **Fix:** Rate-Limiting implementieren
- **Status:** [ ] Offen

### SEC-011: Church-Repository ohne Tenant-Isolation
- **Kategorie:** Security / Design
- **Datei:** `lib/data/repositories/church_repository.dart:17-31`
- **Problem:** Churches sind global sichtbar (by design)
- **Fix:** Pruefen ob erwuenscht
- **Status:** [ ] Offen

### RT-011: `response['id'] as int` ohne Null-Check
- **Kategorie:** Runtime / JSON Parsing
- **Datei:** `lib/features/attendance/presentation/pages/attendance_create_page.dart:809`
- **Problem:** TypeError bei fehlendem Feld
- **Fix:** `as int?` mit Exception
- **Status:** [ ] Offen

### RT-012: `response['role'] as int?` Fallback zu 99
- **Kategorie:** Runtime / JSON Parsing
- **Datei:** `lib/features/auth/presentation/pages/login_page.dart:133`
- **Problem:** Stille Degradierung zu Role.none
- **Fix:** Explizite Fehlerbehandlung
- **Status:** [ ] Offen

### RT-013: `.split(':')` ohne Laengencheck
- **Kategorie:** Runtime / Type-Safety
- **Datei:** `lib/data/models/shift/shift_definition.dart:27-31`
- **Problem:** IndexError bei fehlerhaftem Format
- **Fix:** Laengencheck hinzufuegen
- **Status:** [ ] Offen

### RT-014: `result['name']!` Force Unwrap auf Dialog-Result
- **Kategorie:** Runtime / Null-Safety
- **Datei:** `lib/features/shifts/presentation/pages/shifts_list_page.dart:173-174`
- **Problem:** Crash bei null-Result
- **Fix:** `?.trim() ?? ''`
- **Status:** [ ] Offen

### RT-015: `_formKey.currentState!.validate()` ohne null-Check
- **Kategorie:** Runtime / Null-Safety
- **Dateien:** `lib/features/auth/presentation/pages/forgot_password_page.dart:31`, `login_page.dart:36`, `profile_page.dart:108`
- **Problem:** currentState kann null sein
- **Fix:** `?.validate() ?? false`
- **Status:** [ ] Offen

### RT-016: `late` Variable Initialisierung
- **Kategorie:** Runtime / Initialization
- **Dateien:** `lib/features/people/presentation/pages/person_detail_page.dart:267-281`, `song_edit_page.dart:23-27`
- **Problem:** Crash wenn initState fehlschlaegt
- **Fix:** Nullable deklarieren
- **Status:** [ ] Offen

### RT-17: `.single()` statt `.maybeSingle()` auf Queries
- **Kategorie:** Runtime / Collection
- **Dateien:** 23 Vorkommen in Repositories
- **Problem:** StateError bei 0 oder >1 Ergebnissen
- **Fix:** `.maybeSingle()` verwenden
- **Status:** [ ] Offen

### BL-006: `reduce()` auf potentiell leerer Liste in Charts
- **Kategorie:** Business-Logik / Runtime
- **Datei:** `lib/features/statistics/presentation/pages/statistics_page.dart:681, 771, 862`
- **Problem:** Fragil bei Refactoring
- **Fix:** Defensive Programmierung
- **Status:** [ ] Offen

### BL-007: Fehlende Start < Ende Validierung bei Terminen
- **Kategorie:** Business-Logik / Validation
- **Datei:** `lib/features/attendance/presentation/pages/attendance_create_page.dart`
- **Problem:** Ungueltige Zeitraeume moeglich
- **Fix:** Validierung hinzufuegen
- **Status:** [ ] Offen

### BL-008: `.first` nach `.where()` ohne Pruefung
- **Kategorie:** Business-Logik / Null-Safety
- **Datei:** `lib/features/parents/data/providers/parents_providers.dart:291-295`
- **Problem:** Fragil bei Refactoring
- **Fix:** `firstOrNull` verwenden
- **Status:** [ ] Offen

### BL-009: Fehlende null-Check bei Meeting-ID
- **Kategorie:** Business-Logik / Null-Safety
- **Datei:** `lib/features/meetings/presentation/pages/meetings_list_page.dart:123-149`
- **Problem:** Potentieller Crash
- **Fix:** Expliziter null-Check
- **Status:** [ ] Offen

### FN-007: Tenant null-Check Redundanz
- **Kategorie:** Funktional / Null-Safety
- **Datei:** `lib/features/people/presentation/pages/people_list_page.dart:27, 36`
- **Problem:** tenant?.id == null waere sicherer
- **Fix:** Kombinierten Check verwenden
- **Status:** [ ] Offen

### FN-008: Fehlender Empty-State fuer Error in .when()
- **Kategorie:** Funktional / Error Handling
- **Datei:** `lib/features/people/presentation/pages/person_detail_page.dart:1155-1156`
- **Problem:** SizedBox.shrink() zeigt keinen Fehler
- **Fix:** Error-Text anzeigen
- **Status:** [ ] Offen

### FN-009: showDialog ohne barrierDismissible
- **Kategorie:** Funktional / UX
- **Datei:** `lib/features/meetings/presentation/pages/meetings_list_page.dart:94`
- **Problem:** Wichtige Dialoge versehentlich schliessbar
- **Fix:** `barrierDismissible: false`
- **Status:** [ ] Offen

### FN-010: Fehlende Tastatur-Dismiss bei Form-Scroll
- **Kategorie:** Funktional / UX
- **Datei:** `lib/features/people/presentation/pages/person_create_page.dart:119`
- **Problem:** Tastatur bleibt beim Scrollen offen
- **Fix:** `keyboardDismissBehavior: onDrag`
- **Status:** [ ] Offen

### FN-011: RealtimeChannel Cleanup ohne await
- **Kategorie:** Funktional / Lifecycle
- **Datei:** `lib/features/attendance/presentation/pages/attendance_detail_page.dart:200`
- **Problem:** Unsubscription evtl. nicht abgeschlossen
- **Fix:** Flag setzen und spaeter cleanen
- **Status:** [ ] Offen

---

## NIEDRIG

### SEC-012: Inkonsistente tenantId-Spaltennamen
- **Kategorie:** Security / Code Quality
- **Problem:** Mischung von `tenantId` und `tenant_id`
- **Fix:** Schema vereinheitlichen
- **Status:** [ ] Offen

### RT-018: `int.parse()` bei Farbkonvertierung (bereits korrekt)
- **Kategorie:** Runtime
- **Status:** [x] Bereits behandelt

### RT-019: `List<dynamic>` Type-Casting
- **Kategorie:** Runtime / Type-Safety
- **Problem:** Dynamische Casts, geringes Risiko
- **Status:** [ ] Offen

### RT-020: DateTime.parse in generierten Dateien
- **Kategorie:** Runtime / JSON Parsing
- **Problem:** Freezed-generierter Code ohne try-catch
- **Fix:** Custom JsonConverter
- **Status:** [ ] Offen

### RT-021: Unused Local Variable
- **Kategorie:** Runtime / Code Quality
- **Datei:** `lib/data/repositories/attendance_repository.dart:413`
- **Fix:** Variable entfernen
- **Status:** [ ] Offen

### BL-010: SongFileService `.first` nach isEmpty Check
- **Kategorie:** Business-Logik / Null-Safety
- **Datei:** `lib/core/services/song_file_service.dart:27-28`
- **Problem:** Aktuell sicher, aber fragil
- **Fix:** `firstOrNull` verwenden
- **Status:** [ ] Offen

### BL-011: Inkonsistente Status-Parser
- **Kategorie:** Business-Logik / Code Quality
- **Dateien:** `attendance_repository.dart`, `statistics_providers.dart`, `parents_providers.dart`
- **Problem:** Duplizierter Code
- **Fix:** Zentrale Funktion
- **Status:** [ ] Offen

### BL-012: Fehlende Duplikat-Pruefung bei PersonAttendance
- **Kategorie:** Business-Logik / Validation
- **Datei:** `lib/data/repositories/attendance_repository.dart:188-209`
- **Problem:** Duplikate bei doppeltem Aufruf
- **Fix:** Upsert verwenden
- **Status:** [ ] Offen

### FN-012: Hartcodierte deutsche Texte
- **Kategorie:** Funktional / i18n
- **Problem:** Keine Internationalisierung
- **Fix:** flutter_localizations
- **Status:** [ ] Offen

### FN-013: Inkonsistente Icon-Groessen
- **Kategorie:** Funktional / UI
- **Problem:** Verschiedene Groessen ohne zentrale Definition
- **Fix:** In AppDimensions definieren
- **Status:** [ ] Offen

### FN-014: ref.watch in callback (potentiell)
- **Kategorie:** Funktional / State Management
- **Problem:** Unnoetige Rebuilds moeglich
- **Fix:** Code-Review
- **Status:** [ ] Offen

### FN-015: Fehlende Loading-Indication bei Buttons
- **Kategorie:** Funktional / UX
- **Datei:** `lib/features/shifts/presentation/pages/shifts_list_page.dart:162-167`
- **Problem:** Mehrfach-Klick moeglich
- **Fix:** isLoading State
- **Status:** [ ] Offen

---

## Scan-Details

- **Gescannte Bereiche:** lib/data/repositories/, lib/features/, lib/core/providers/, lib/shared/
- **Scanner verwendet:** business-logic, functional, runtime, security
- **Dauer:** ~10 Minuten (parallel)
- **Duplikate entfernt:** 3 (uebergreifende Issues konsolidiert)

## Naechste Schritte

1. **SOFORT:** Kritische Security-Bugs fixen (SEC-001, SEC-002, SEC-004) - Multi-Tenant!
2. **SOFORT:** Runtime-Crashes verhindern (RT-001, RT-002, RT-003, BL-001, BL-002)
3. **Diese Woche:** Alle HOCH-Bugs durcharbeiten
4. **Sprint-Planung:** MITTEL/NIEDRIG in Backlog aufnehmen
