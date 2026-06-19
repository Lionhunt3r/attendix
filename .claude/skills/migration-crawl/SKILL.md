---
name: migration-crawl
description: Systematischer Page-für-Page Vergleich aller Ionic Pages mit Flutter-Äquivalenten. Startet 10 parallele Agents und generiert priorisierten Markdown-Report als Task-Katalog.
argument-hint: [full|batch-number] - optional, Standard ist full
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, TaskCreate, TaskUpdate, TaskList, AskUserQuestion, TaskOutput
---

# Migration Crawl - Systematischer Ionic→Flutter Page-Vergleich

Crawlt alle ~52 Ionic Pages und vergleicht sie systematisch mit ihren Flutter-Äquivalenten. Identifiziert fehlende Features, Bugs, UX-Lücken und Service-Gaps.

**Argumente:** $ARGUMENTS

---

## PHASE 0: SETUP

### 0.0 Ionic-Repo aktuell halten (KRITISCH!)

**WICHTIG:** Vor jedem Crawl prüfen, ob das Ionic-Repo aktuell ist!

```bash
# Status checken
git -C /Users/I576226/repositories/attendance fetch --all 2>&1
BEHIND=$(git -C /Users/I576226/repositories/attendance status -uno | grep -c "behind")
if [ "$BEHIND" -gt 0 ]; then
  echo "FEHLER: Ionic-Repo ist hinten dran! User fragen ob pull gemacht werden soll."
  # Bei Zustimmung: git stash; git pull --ff-only; git stash pop
fi
```

Ein veraltetes Ionic-Repo führt zu falschen Findings: Features die "fehlen" sind ggf. nur lokal noch nicht synchronisiert. Ein 160-Commit-Rückstand wurde im Crawl 2026-06-17 entdeckt.

### 0.1 Scope bestimmen

Falls `$ARGUMENTS` leer oder "full":
- Alle 11 Batches scannen (10 Standard + 1 für neue Pages)

Falls `$ARGUMENTS` eine Batch-Nummer (z.B. "3"):
- Nur diesen Batch scannen

### 0.2 Bestehenden Report archivieren

```bash
if [ -f .claude/migration-crawl-report.md ]; then
  mv .claude/migration-crawl-report.md ".claude/migration-crawl-report-$(date +%Y%m%d-%H%M%S).md"
fi
```

### 0.3 Pfade verifizieren

```bash
# Ionic Projekt prüfen
ls /Users/I576226/repositories/attendance/src/app/ > /dev/null 2>&1 || echo "FEHLER: Ionic-Projekt nicht gefunden!"

# Flutter Projekt prüfen
ls /Users/I576226/repositories/attendix/lib/features/ > /dev/null 2>&1 || echo "FEHLER: Flutter-Projekt nicht gefunden!"
```

### 0.4 Tasks erstellen

```
TaskCreate(subject: "Batch 1-11 scannen", description: "11 page-crawler Agents parallel starten", activeForm: "Starte Page-Crawler Agents")
TaskCreate(subject: "Ergebnisse aggregieren", description: "Alle Agent-Outputs sammeln, deduplizieren, priorisieren", activeForm: "Aggregiere Ergebnisse")
TaskCreate(subject: "Report generieren", description: "Markdown-Report in .claude/migration-crawl-report.md erstellen", activeForm: "Generiere Report")
TaskCreate(subject: "Abschluss", description: "Zusammenfassung anzeigen, Top-5 Action Items", activeForm: "Schließe Migration Crawl ab")
```

---

## PHASE 1: PARALLEL SCANS

**WICHTIG: Alle 11 Agents PARALLEL starten mit `run_in_background: true`!**

### Batch-Zuordnung

| Batch | Ionic Pages | Flutter Pages |
|-------|-------------|---------------|
| 1 | Login, Login/Legal-Modal, Register, Tenant-Register, Legal, App-Redirect | Login, Register, Tenant-Registration, Tenant-Create |
| 2 | Att-List, Attendance Detail, Status-Info | Attendance List, Attendance Detail, Attendance Create |
| 3 | People List, Person Detail, Members, Bulk-Edit | People List, Person Detail, Person Create, Members |
| 4 | Songs List, Song Detail, Song Viewer (Public) | Songs List, Song Detail, Song Create, Song Edit |
| 5 | Self-Service Overview, Signout, Parents | Self-Service Overview, Parents Portal |
| 6 | Planning, Plan-Viewer, Statistics, History, Export | Planning, Statistics, History, Export |
| 7 | Settings, General, Notifications, Delete-Account, Files, Role-Permissions | Settings, General Settings, Notifications, Profile, User Management |
| 8 | Types, Type Detail, Shifts, Shift Detail | Attendance Types, Attendance Type Edit, Shifts List, Shift Detail |
| 9 | Instruments, Teachers | Instruments List, Teachers List |
| 10 | Meetings List, Meeting Detail, Handover, Handover Detail, Voice-Leader | Meetings List, Meeting Detail, Voice Leader |
| 11 | **NEW PAGES + SERVICES** (siehe unten) | (vermutlich alle fehlend) |

### Batch 11: Neue Pages + Cross-Cutting Services

Diese Pages/Services kamen mit Ionic v4.0.5+ dazu und fehlen in Flutter typischerweise komplett:

**Neue Pages:**
- `dashboard/` — Usage-Analytics-Dashboard (Super-Admin)
- `people/bulk-edit/` — Bulk-Edit für Personen
- `settings/delete-account/` — DSGVO Konto-Löschung
- `settings/files/` — Tenant File Storage
- `settings/role-permissions/` — Konfigurierbare Permissions
- `legal/` — Datenschutz/Impressum
- `login/legal-modal/` — DSGVO Consent
- `app-redirect/` — Native App Sharing

**Neue Services (Querschnitt!):**
- `services/push/` — Firebase Messaging Integration
- `services/audio-player/` — Recordings abspielen
- `services/files/` — Tenant Storage CRUD
- `services/legal/` — DSGVO-Inhalte aus DB
- `services/role-permission/` — `tenant_role_permissions` Tabelle
- `services/tracking/` — `usage_events` Telemetrie

### Agent-Prompts

**Batch 1: Auth Pages**
```
Agent(
  subagent_type: "page-crawler",
  model: "opus",
  description: "Crawl Auth Pages",
  prompt: "Vergleiche diese Ionic Pages mit ihren Flutter-Äquivalenten. Batch 1: Auth Pages.

PAGE MAPPINGS:
1. Ionic: /Users/I576226/repositories/attendance/src/app/login/login.page.ts (+login.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/auth/presentation/pages/login_page.dart

2. Ionic: /Users/I576226/repositories/attendance/src/app/register/register.page.ts (+register.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/auth/presentation/pages/register_page.dart

3. Ionic: /Users/I576226/repositories/attendance/src/app/register/tenant-register/tenant-register.page.ts (+tenant-register.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/registration/presentation/pages/tenant_registration_page.dart

PRÜFE:
- Alle Form-Felder und Validierungen
- Error-Handling (falsche Credentials, Netzwerk-Fehler)
- Navigation nach Login/Register
- Password Reset Flow
- Tenant-Erstellung Workflow
- Loading States während Auth

Liefere strukturierten JSON-Output gemäß page-crawler Output-Format. Nutze Prefix 'B1-' für Finding-IDs.",
  run_in_background: true
)
```

**Batch 2: Attendance Pages**
```
Agent(
  subagent_type: "page-crawler",
  model: "opus",
  description: "Crawl Attendance Pages",
  prompt: "Vergleiche diese Ionic Pages mit ihren Flutter-Äquivalenten. Batch 2: Attendance Pages.

PAGE MAPPINGS:
1. Ionic: /Users/I576226/repositories/attendance/src/app/attendance/att-list/att-list.page.ts (+att-list.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/attendance/presentation/pages/attendance_list_page.dart

2. Ionic: /Users/I576226/repositories/attendance/src/app/attendance/attendance/attendance.page.ts (+attendance.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/attendance/presentation/pages/attendance_detail_page.dart
   Flutter (Create): /Users/I576226/repositories/attendix/lib/features/attendance/presentation/pages/attendance_create_page.dart

ZUSÄTZLICH PRÜFEN:
- Provider: /Users/I576226/repositories/attendix/lib/core/providers/attendance_providers.dart
- Repository: /Users/I576226/repositories/attendix/lib/data/repositories/attendance_repository.dart
- Ionic Service: /Users/I576226/repositories/attendance/src/app/services/attendance.service.ts
- Widgets in: /Users/I576226/repositories/attendix/lib/features/attendance/presentation/widgets/

PRÜFE:
- CRUD-Operationen (Create, Read, Update, Delete)
- Realtime-Updates (Supabase Realtime)
- Pull-to-Refresh
- Anwesenheitsstatus ändern (Anwesend, Abwesend, Entschuldigt, Verspätet)
- Checklisten-Feature
- Werke-Zuordnung
- Statistik-Anzeige
- Filter und Sortierung
- Bulk-Aktionen
- Toasts/Feedback nach Aktionen

Liefere strukturierten JSON-Output gemäß page-crawler Output-Format. Nutze Prefix 'B2-' für Finding-IDs.",
  run_in_background: true
)
```

**Batch 3: People Pages**
```
Agent(
  subagent_type: "page-crawler",
  model: "opus",
  description: "Crawl People Pages",
  prompt: "Vergleiche diese Ionic Pages mit ihren Flutter-Äquivalenten. Batch 3: People Pages.

PAGE MAPPINGS:
1. Ionic: /Users/I576226/repositories/attendance/src/app/people/list/list.page.ts (+list.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/people/presentation/pages/people_list_page.dart

2. Ionic: /Users/I576226/repositories/attendance/src/app/people/person/person.page.ts (+person.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/people/presentation/pages/person_detail_page.dart
   Flutter (Create): /Users/I576226/repositories/attendix/lib/features/people/presentation/pages/person_create_page.dart

3. Ionic: /Users/I576226/repositories/attendance/src/app/people/members/members.page.ts (+members.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/members/presentation/pages/members_page.dart

ZUSÄTZLICH PRÜFEN:
- Provider: /Users/I576226/repositories/attendix/lib/core/providers/player_providers.dart
- Repository: /Users/I576226/repositories/attendix/lib/data/repositories/player_repository.dart
- Ionic Service: /Users/I576226/repositories/attendance/src/app/services/player.service.ts
- Widgets in: /Users/I576226/repositories/attendix/lib/features/people/presentation/widgets/

PRÜFE:
- CRUD-Operationen für Personen
- Suche/Filter in der Liste
- Gruppen-Zuordnung
- Instrument-Zuordnung
- Archivierung/Pausierung
- Stimme-Zuordnung
- Kontaktdaten (Telefon, Email)
- Profilbild/Passbild
- Accordion-Sections in Person Detail
- Rollen-Anzeige

Liefere strukturierten JSON-Output gemäß page-crawler Output-Format. Nutze Prefix 'B3-' für Finding-IDs.",
  run_in_background: true
)
```

**Batch 4: Songs Pages**
```
Agent(
  subagent_type: "page-crawler",
  model: "opus",
  description: "Crawl Songs Pages",
  prompt: "Vergleiche diese Ionic Pages mit ihren Flutter-Äquivalenten. Batch 4: Songs Pages.

PAGE MAPPINGS:
1. Ionic: /Users/I576226/repositories/attendance/src/app/songs/songs.page.ts (+songs.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/songs/presentation/pages/songs_list_page.dart

2. Ionic: /Users/I576226/repositories/attendance/src/app/songs/song/song.page.ts (+song.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/songs/presentation/pages/song_detail_page.dart
   Flutter (Create): /Users/I576226/repositories/attendix/lib/features/songs/presentation/pages/song_create_page.dart
   Flutter (Edit): /Users/I576226/repositories/attendix/lib/features/songs/presentation/pages/song_edit_page.dart

3. Ionic: /Users/I576226/repositories/attendance/src/app/song-viewer/song-viewer.page.ts (+song-viewer.page.html)
   Flutter: Prüfe ob Song-Viewer Page/Widget existiert in lib/features/songs/

ZUSÄTZLICH PRÜFEN:
- Provider: /Users/I576226/repositories/attendix/lib/core/providers/song_providers.dart
- Repository: /Users/I576226/repositories/attendix/lib/data/repositories/song_repository.dart
- Ionic Service: /Users/I576226/repositories/attendance/src/app/services/song.service.ts
- Widgets in: /Users/I576226/repositories/attendix/lib/features/songs/presentation/widgets/

PRÜFE:
- CRUD-Operationen für Songs
- Datei-Upload/Download/Delete (Noten-PDFs)
- PDF-Viewer / Image-Viewer
- Inline-Bearbeitung
- Besetzungs-Chips
- Filter (Gattung, Besetzung, etc.)
- Suche
- Telegram-Versand
- Share-Link
- Smart Print (Kopien pro Instrument)
- ZIP-Download
- Copy to Tenant

Liefere strukturierten JSON-Output gemäß page-crawler Output-Format. Nutze Prefix 'B4-' für Finding-IDs.",
  run_in_background: true
)
```

**Batch 5: Self-Service Pages**
```
Agent(
  subagent_type: "page-crawler",
  model: "opus",
  description: "Crawl Self-Service Pages",
  prompt: "Vergleiche diese Ionic Pages mit ihren Flutter-Äquivalenten. Batch 5: Self-Service Pages.

PAGE MAPPINGS:
1. Ionic: /Users/I576226/repositories/attendance/src/app/selfService/overview/overview.page.ts (+overview.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/self_service/presentation/pages/self_service_overview_page.dart

2. Ionic: /Users/I576226/repositories/attendance/src/app/selfService/signout/signout.page.ts (+signout.page.html)
   Flutter: Prüfe ob eine Sign-Out Page existiert (evtl. in self_service oder settings)

3. Ionic: /Users/I576226/repositories/attendance/src/app/selfService/parents/parents.page.ts (+parents.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/parents/presentation/pages/parents_portal_page.dart

ZUSÄTZLICH PRÜFEN:
- Provider: /Users/I576226/repositories/attendix/lib/core/providers/sign_in_out_providers.dart (falls vorhanden)
- Repository: /Users/I576226/repositories/attendix/lib/data/repositories/sign_in_out_repository.dart
- Ionic Service: /Users/I576226/repositories/attendance/src/app/services/sign-in-out.service.ts

PRÜFE:
- Abmeldung mit Grund
- Abmelde-Zeitraum (Datum von/bis)
- Eltern-Portal Funktionalität
- Kinder-Zuordnung
- Übersicht eigener Abwesenheiten
- Anwesenheitsstatistik
- Kalender-Ansicht

Liefere strukturierten JSON-Output gemäß page-crawler Output-Format. Nutze Prefix 'B5-' für Finding-IDs.",
  run_in_background: true
)
```

**Batch 6: Planning/Stats/History/Export Pages**
```
Agent(
  subagent_type: "page-crawler",
  model: "opus",
  description: "Crawl Planning Pages",
  prompt: "Vergleiche diese Ionic Pages mit ihren Flutter-Äquivalenten. Batch 6: Planning, Statistics, History, Export.

PAGE MAPPINGS:
1. Ionic: /Users/I576226/repositories/attendance/src/app/planning/planning.page.ts (+planning.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/planning/presentation/pages/planning_page.dart

2. Ionic: /Users/I576226/repositories/attendance/src/app/stats/stats.page.ts (+stats.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/statistics/presentation/pages/statistics_page.dart

3. Ionic: /Users/I576226/repositories/attendance/src/app/history/history.page.ts (+history.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/history/presentation/pages/history_page.dart

4. Ionic: /Users/I576226/repositories/attendance/src/app/export/export.page.ts (+export.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/export/presentation/pages/export_page.dart

ZUSÄTZLICH PRÜFEN:
- Provider: /Users/I576226/repositories/attendix/lib/core/providers/planning_providers.dart (falls vorhanden)
- Provider: /Users/I576226/repositories/attendix/lib/core/providers/statistics_providers.dart (falls vorhanden)
- Widgets in: /Users/I576226/repositories/attendix/lib/features/planning/presentation/widgets/
- Widgets in: /Users/I576226/repositories/attendix/lib/features/statistics/presentation/widgets/

PRÜFE:
- Planning: Ablaufplan erstellen/bearbeiten, Drag-and-Drop, Telegram-Versand
- Statistics: Alle 7 Chart-Typen, Filter, Datumsbereich
- History: Vergangene Anwesenheiten, Pagination, Filter
- Export: CSV/PDF Export, Datumsbereich, Format-Optionen
- Registerprobenplan

Liefere strukturierten JSON-Output gemäß page-crawler Output-Format. Nutze Prefix 'B6-' für Finding-IDs.",
  run_in_background: true
)
```

**Batch 7: Settings Pages**
```
Agent(
  subagent_type: "page-crawler",
  model: "opus",
  description: "Crawl Settings Pages",
  prompt: "Vergleiche diese Ionic Pages mit ihren Flutter-Äquivalenten. Batch 7: Settings Pages.

PAGE MAPPINGS:
1. Ionic: /Users/I576226/repositories/attendance/src/app/settings/settings/settings.page.ts (+settings.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/settings/presentation/pages/settings_page.dart

2. Ionic: /Users/I576226/repositories/attendance/src/app/settings/general/general.page.ts (+general.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/settings/presentation/pages/general_settings_page.dart

3. Ionic: /Users/I576226/repositories/attendance/src/app/notifications/notifications.page.ts (+notifications.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/notifications/presentation/pages/notifications_page.dart
   Flutter: /Users/I576226/repositories/attendix/lib/features/settings/presentation/pages/notification_settings_page.dart

ZUSÄTZLICH PRÜFEN:
- Profile Page: /Users/I576226/repositories/attendix/lib/features/profile/presentation/pages/profile_page.dart
- User Management: /Users/I576226/repositories/attendix/lib/features/settings/presentation/pages/user_management_page.dart
- Calendar Subscription: /Users/I576226/repositories/attendix/lib/features/settings/presentation/pages/calendar_subscription_page.dart
- Pending Players: /Users/I576226/repositories/attendix/lib/features/settings/presentation/pages/pending_players_page.dart
- Left Players: /Users/I576226/repositories/attendix/lib/features/settings/presentation/pages/left_players_page.dart

PRÜFE:
- Settings-Menü Vollständigkeit
- General Settings: Gruppenname, Beschreibung, Logo
- Notification Settings
- Profil bearbeiten (Meine Stammdaten)
- Passwort ändern
- User Management (Rollen zuweisen)
- Kalender-Abo

Liefere strukturierten JSON-Output gemäß page-crawler Output-Format. Nutze Prefix 'B7-' für Finding-IDs.",
  run_in_background: true
)
```

**Batch 8: Types & Shifts Pages**
```
Agent(
  subagent_type: "page-crawler",
  model: "opus",
  description: "Crawl Types & Shifts Pages",
  prompt: "Vergleiche diese Ionic Pages mit ihren Flutter-Äquivalenten. Batch 8: Attendance Types & Shifts.

PAGE MAPPINGS:
1. Ionic: /Users/I576226/repositories/attendance/src/app/settings/general/types/types.page.ts (+types.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/settings/presentation/pages/attendance_types_page.dart

2. Ionic: /Users/I576226/repositories/attendance/src/app/settings/general/type/type.page.ts (+type.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/settings/presentation/pages/attendance_type_edit_page.dart

3. Ionic: /Users/I576226/repositories/attendance/src/app/settings/general/shifts/shifts.page.ts (+shifts.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/shifts/presentation/pages/shifts_list_page.dart

4. Ionic: /Users/I576226/repositories/attendance/src/app/settings/general/shifts/shift/shift.page.ts (+shift.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/shifts/presentation/pages/shift_detail_page.dart

ZUSÄTZLICH PRÜFEN:
- Ionic Service: /Users/I576226/repositories/attendance/src/app/services/attendance-type.service.ts
- Ionic Service: /Users/I576226/repositories/attendance/src/app/services/shift.service.ts
- Repository: /Users/I576226/repositories/attendix/lib/data/repositories/attendance_type_repository.dart
- Repository: /Users/I576226/repositories/attendix/lib/data/repositories/shift_repository.dart

PRÜFE:
- Attendance Types: CRUD, Farbe zuweisen, Default-Typ
- Shifts: CRUD, Schicht-Instanzen, Zeitplanung
- Copy to Tenant für Shifts
- Cross-Tenant Shifts
- Feste Schichten (Shift Instances)

Liefere strukturierten JSON-Output gemäß page-crawler Output-Format. Nutze Prefix 'B8-' für Finding-IDs.",
  run_in_background: true
)
```

**Batch 9: Instruments & Teachers Pages**
```
Agent(
  subagent_type: "page-crawler",
  model: "opus",
  description: "Crawl Instruments & Teachers",
  prompt: "Vergleiche diese Ionic Pages mit ihren Flutter-Äquivalenten. Batch 9: Instruments & Teachers.

PAGE MAPPINGS:
1. Ionic: /Users/I576226/repositories/attendance/src/app/instruments/instrument-list/instrument-list.page.ts (+instrument-list.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/instruments/presentation/pages/instruments_list_page.dart

2. Ionic: /Users/I576226/repositories/attendance/src/app/instruments/instrument/instrument.page.ts (+instrument.page.html)
   Flutter: Prüfe ob Instrument-Detail Page existiert

3. Ionic: /Users/I576226/repositories/attendance/src/app/teachers/teachers.page.ts (+teachers.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/teachers/presentation/pages/teachers_list_page.dart

4. Ionic: /Users/I576226/repositories/attendance/src/app/teacher/teacher.page.ts (+teacher.page.html)
   Flutter: Prüfe ob Teacher-Detail Page existiert

ZUSÄTZLICH PRÜFEN:
- Repository: /Users/I576226/repositories/attendix/lib/data/repositories/instrument_repository.dart (falls vorhanden)
- Repository: /Users/I576226/repositories/attendix/lib/data/repositories/teacher_repository.dart
- Provider: /Users/I576226/repositories/attendix/lib/core/providers/instrument_providers.dart (falls vorhanden)
- Provider: /Users/I576226/repositories/attendix/lib/core/providers/teacher_providers.dart

PRÜFE:
- Instrumente: CRUD, Gruppen-Zuordnung, Sortierung
- Instrumente: Detail-Ansicht mit zugeordneten Spielern
- Teachers: CRUD, Kontaktdaten
- Teachers: Detail-Ansicht

Liefere strukturierten JSON-Output gemäß page-crawler Output-Format. Nutze Prefix 'B9-' für Finding-IDs.",
  run_in_background: true
)
```

**Batch 10: Meetings, Handover & Voice-Leader Pages**
```
Agent(
  subagent_type: "page-crawler",
  model: "opus",
  description: "Crawl Meetings & Handover",
  prompt: "Vergleiche diese Ionic Pages mit ihren Flutter-Äquivalenten. Batch 10: Meetings, Handover, Voice-Leader.

PAGE MAPPINGS:
1. Ionic: /Users/I576226/repositories/attendance/src/app/meetings/meeting-list/meeting-list.page.ts (+meeting-list.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/meetings/presentation/pages/meetings_list_page.dart

2. Ionic: /Users/I576226/repositories/attendance/src/app/meetings/meeting/meeting.page.ts (+meeting.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/meetings/presentation/pages/meeting_detail_page.dart

3. Ionic: /Users/I576226/repositories/attendance/src/app/settings/handover/handover.page.ts (+handover.page.html)
   Flutter: Prüfe ob Handover Page existiert (evtl. in settings oder eigenes Feature)

4. Ionic: /Users/I576226/repositories/attendance/src/app/settings/handover-detail/handover-detail.page.ts (+handover-detail.page.html)
   Flutter: Prüfe ob Handover-Detail Page existiert

5. Ionic: /Users/I576226/repositories/attendance/src/app/settings/voice-leader/voice-leader.page.ts (+voice-leader.page.html)
   Flutter: /Users/I576226/repositories/attendix/lib/features/voice_leader/presentation/pages/voice_leader_page.dart

ZUSÄTZLICH PRÜFEN:
- Repository: /Users/I576226/repositories/attendix/lib/data/repositories/meeting_repository.dart
- Provider: /Users/I576226/repositories/attendix/lib/core/providers/meeting_providers.dart (falls vorhanden)
- Ionic Service: /Users/I576226/repositories/attendance/src/app/services/meeting.service.ts
- Handover-Methoden in player_repository.dart

PRÜFE:
- Meetings: CRUD, Datum/Zeit, Teilnehmer
- Meeting Detail: Agenda, Beschreibung
- Handover: Spieler-Transfer zwischen Tenants
- Handover Detail: Transfer-Status, Bestätigung
- Voice-Leader: Stimmführer zuweisen, Gruppen-Ansicht

Liefere strukturierten JSON-Output gemäß page-crawler Output-Format. Nutze Prefix 'B10-' für Finding-IDs.",
  run_in_background: true
)
```

**Batch 11: Neue Pages + Cross-Cutting Services (NEU seit Ionic v4.0.5)**
```
Agent(
  subagent_type: "page-crawler",
  model: "opus",
  description: "Crawl new Ionic pages",
  prompt: "WICHTIGER NEUER SCAN: Mehrere KOMPLETT NEUE Pages und Services sind in Ionic v4.0.5 dazugekommen, die im Flutter-Projekt vermutlich noch nicht existieren.

DEINE AUFGABE: Prüfe für jede dieser neuen Ionic-Pages/Services, ob ein Flutter-Äquivalent existiert. Wenn nein → MISSING_FEATURE mit Severity HOCH (oder KRITISCH bei DSGVO/Security-Themen).

NEUE IONIC-PAGES:

1. **Dashboard** (Usage Analytics, Super-Admin)
   Ionic: /Users/I576226/repositories/attendance/src/app/dashboard/
   Flutter: Suche in lib/features/ nach dashboard

2. **Bulk-Edit für Personen**
   Ionic: /Users/I576226/repositories/attendance/src/app/people/bulk-edit/
   Flutter: lib/features/people/ — Bulk-Edit Page

3. **Delete-Account (DSGVO!)**
   Ionic: /Users/I576226/repositories/attendance/src/app/settings/delete-account/
   Flutter: lib/features/settings/

4. **Files-Settings (Tenant Storage)**
   Ionic: /Users/I576226/repositories/attendance/src/app/settings/files/
   Flutter: lib/features/settings/

5. **Role-Permissions (konfigurierbar)**
   Ionic: /Users/I576226/repositories/attendance/src/app/settings/role-permissions/
   Flutter: lib/features/settings/

6. **Legal-Page (DSGVO/Impressum)**
   Ionic: /Users/I576226/repositories/attendance/src/app/legal/
   Flutter: lib/features/

7. **Legal-Modal beim Login (DSGVO Consent)**
   Ionic: /Users/I576226/repositories/attendance/src/app/login/legal-modal/
   Flutter: lib/features/auth/

8. **App-Redirect (Native App Sharing)**
   Ionic: /Users/I576226/repositories/attendance/src/app/app-redirect/
   Flutter: lib/features/

NEUE IONIC-SERVICES (Cross-Cutting!):
- /services/push/ — Firebase Messaging (PushService) — KRITISCH bei fehlend
- /services/audio-player/ — Aufnahmen abspielen
- /services/files/ — Tenant Storage CRUD
- /services/legal/ — DSGVO-Inhalte (legal_content Tabelle)
- /services/role-permission/ — tenant_role_permissions Tabelle
- /services/tracking/ — usage_events Telemetrie

WICHTIG bei jedem Befund:
- DSGVO-Themen (Delete-Account, Legal) immer KRITISCH
- Push/Tracking als Querschnittsservices: alle Aufrufstellen identifizieren
- tenant_role_permissions: Wenn nicht angebunden → Sicherheitslücke (HOCH)
- App-Store-Compliance bewerten

Liefere strukturierten JSON-Output gemäß page-crawler Output-Format. Nutze Prefix 'B11-' für Finding-IDs.",
  run_in_background: true
)
```

### Auf Ergebnisse warten

Sammle alle 11 Agent-Outputs mit `TaskOutput`. Warte bis ALLE fertig sind bevor Phase 2 beginnt.

---

## PHASE 2: AGGREGATION

### 2.1 Ergebnisse sammeln

Aus jedem Agent-Output den JSON-Block extrahieren. Falls ein Agent keinen sauberen JSON liefert, die strukturierten Findings manuell extrahieren.

### 2.2 Findings zusammenführen

Sammle alle Findings in eine gemeinsame Liste:
- Vergib globale IDs: `MC-001`, `MC-002`, etc. (MC = Migration Crawl)
- Behalte die Batch-Referenz bei (z.B. "Quelle: Batch 2")

### 2.3 Duplikate entfernen

Prüfe auf Duplikate:
- Gleiche Datei + gleiche Zeile = Duplikat → zusammenfassen
- Gleiche Root Cause, unterschiedliche Manifestation = zusammenfassen mit Verweis
- Ähnliche Service-Gaps in verschiedenen Batches → eine Einheit

### 2.4 Priorisieren

Sortiere nach Severity:
1. **KRITISCH** - Security, Datenverlust, Core-Feature fehlt
2. **HOCH** - Wichtige Funktion fehlt, Workflow blockiert
3. **MITTEL** - UX-Verschlechterung, Edge Case
4. **NIEDRIG** - Kosmetisch, Nice-to-have

### 2.5 Scores berechnen

Pro Page:
```
pageScore = (implementedFeatures / totalIonicFeatures) × 100
```

Gesamt:
```
overallScore = average(allPageScores)
```

---

## PHASE 3: REPORT GENERIEREN

Erstelle `.claude/migration-crawl-report.md` mit folgendem Format:

```markdown
# Migration Crawl Report
Datum: [YYYY-MM-DD]
Scope: [full / Batch X]

## Zusammenfassung

| Metrik | Wert |
|--------|------|
| Gescannte Ionic Pages | [COUNT] |
| Gescannte Flutter Pages | [COUNT] |
| Durchschnittlicher Score | [SCORE]% |
| Gesamt-Findings | [COUNT] |

| Kategorie | KRITISCH | HOCH | MITTEL | NIEDRIG | Gesamt |
|-----------|----------|------|--------|---------|--------|
| Missing Feature | X | X | X | X | X |
| Bug | X | X | X | X | X |
| UX Gap | X | X | X | X | X |
| Service Gap | X | X | X | X | X |
| **Gesamt** | **X** | **X** | **X** | **X** | **X** |

## Top-5 Action Items

1. **[MC-XXX]** [Titel] — [Severity] — [Effort]
2. **[MC-XXX]** [Titel] — [Severity] — [Effort]
3. **[MC-XXX]** [Titel] — [Severity] — [Effort]
4. **[MC-XXX]** [Titel] — [Severity] — [Effort]
5. **[MC-XXX]** [Titel] — [Severity] — [Effort]

---

## Priorisierter Task-Katalog

### KRITISCH

#### [MC-001] [Titel]
- **Typ:** [MISSING_FEATURE | BUG | UX_GAP | SERVICE_GAP]
- **Ionic:** [datei:zeile] — [Beschreibung was in Ionic existiert]
- **Flutter:** [datei:zeile] — [Was fehlt oder kaputt ist]
- **Effort:** [Xh]
- **Fix:** [Kurze Beschreibung der Lösung]
- **Status:** [ ] Offen

...

### HOCH

#### [MC-XXX] [Titel]
...

### MITTEL

#### [MC-XXX] [Titel]
...

### NIEDRIG

#### [MC-XXX] [Titel]
...

---

## Page-für-Page Analyse

### [Page Name] (Score: X%)
**Ionic:** [pfad] | **Flutter:** [pfad]

Implementiert:
- [x] Feature A
- [x] Feature B
- [x] Feature C

Findings:
- [ ] [MC-XXX] [Finding Titel] ([Severity])
- [ ] [MC-XXX] [Finding Titel] ([Severity])

---

### [Next Page] (Score: X%)
...

---

## Scan-Details

- **Datum:** [YYYY-MM-DD]
- **Batches gescannt:** [1-10 / nur X]
- **Agents verwendet:** 10x page-crawler
- **Duplikate entfernt:** [COUNT]
- **False Positives entfernt:** [COUNT]

## Nächste Schritte

1. Kritische Findings mit `/fix-bug [MC-XXX]` oder `/ionic-migrate [feature]` beheben
2. Report als Referenz für Sprint-Planung nutzen
3. Nach Fixes erneut `/migration-crawl` laufen lassen für Progress-Tracking
```

---

## PHASE 4: ABSCHLUSS

### 4.1 Report speichern

```
Write(file_path: ".claude/migration-crawl-report.md", content: [REPORT])
```

### 4.2 Zusammenfassung anzeigen

```
## Migration Crawl Complete

**Overall Score: [SCORE]%**

| Kategorie | KRITISCH | HOCH | MITTEL | NIEDRIG |
|-----------|----------|------|--------|---------|
| Missing Feature | X | X | X | X |
| Bug | X | X | X | X |
| UX Gap | X | X | X | X |
| Service Gap | X | X | X | X |

**Report:** .claude/migration-crawl-report.md

**Top 5 Action Items:**
1. [MC-XXX] [Titel] — [Effort]
2. [MC-XXX] [Titel] — [Effort]
3. [MC-XXX] [Titel] — [Effort]
4. [MC-XXX] [Titel] — [Effort]
5. [MC-XXX] [Titel] — [Effort]

**Tipp:** Nutze `/ionic-migrate [feature]` oder `/fix-bug [MC-XXX]` um Findings zu beheben.
```

### 4.3 Tasks abschließen

Alle Tasks als completed markieren.

---

## Checkliste

- [ ] Scope bestimmt (full oder Batch-Nummer)
- [ ] Alter Report archiviert (falls vorhanden)
- [ ] Pfade verifiziert (Ionic + Flutter Projekt vorhanden)
- [ ] Tasks erstellt
- [ ] 10 page-crawler Agents parallel gestartet
- [ ] Auf alle Agent-Ergebnisse gewartet
- [ ] Findings zusammengeführt und dedupliziert
- [ ] Nach Priorität sortiert
- [ ] Scores berechnet
- [ ] Markdown-Report generiert
- [ ] Zusammenfassung angezeigt
- [ ] Tasks abgeschlossen

---

## Anti-Patterns (VERBOTEN!)

1. **Agents sequentiell starten** - IMMER parallel mit `run_in_background: true`!
2. **Ohne Report abschließen** - Markdown-Report ist PFLICHT!
3. **Duplikate nicht entfernen** - Gleiche Root Cause zusammenfassen!
4. **Severity inflaten** - Nicht alles ist KRITISCH! Realistische Einschätzung!
5. **Ionic-Projekt nicht lesen** - BEIDE Seiten (Ionic + Flutter) vollständig lesen!
6. **Nur Page-Code prüfen** - Provider + Repository + Widgets auch prüfen!
7. **Tabs-Page als Feature zählen** - tabs.page.ts ist nur Navigation, kein Feature!

---

## Beispiel-Aufrufe

```bash
# Vollständiger Scan aller Pages
/migration-crawl

# Nur Batch 2 (Attendance) scannen
/migration-crawl 2

# Full explicit
/migration-crawl full
```
