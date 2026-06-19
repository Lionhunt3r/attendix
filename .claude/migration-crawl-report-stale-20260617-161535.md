# Migration Crawl Report
**Datum:** 2026-06-17
**Scope:** full (alle 10 Batches)
**Vorheriger Report:** `.claude/migration-crawl-report-20260617-*.md` (archiviert, datiert 2026-03-04)

## Zusammenfassung

| Metrik | Wert |
|--------|------|
| Gescannte Ionic Pages | ~37 |
| Gescannte Flutter Pages | ~40 |
| Durchschnittlicher Score | **78%** |
| Gesamt-Findings | **252** |

| Kategorie | KRITISCH | HOCH | MITTEL | NIEDRIG | Gesamt |
|-----------|----------|------|--------|---------|--------|
| Missing Feature | 1 | 28 | 53 | 64 | 146 |
| Bug | 2 | 13 | 23 | 16 | 54 |
| UX Gap | 0 | 0 | 13 | 28 | 41 |
| Service Gap | 1 | 1 | 6 | 3 | 11 |
| **Gesamt** | **4** | **42** | **95** | **111** | **252** |

## Vergleich mit vorherigem Report (2026-03-04)

| Metrik | Vorher | Jetzt | Δ |
|--------|--------|-------|------|
| Findings | 190 | 252 | +62 |
| KRITISCH | 0 (alle gefixt) | 4 | +4 ⚠️ |
| HOCH | 0 (alle gefixt) | 42 | +42 ⚠️ |
| MITTEL | 5 offen | 95 | +90 |
| NIEDRIG | 28 offen | 111 | +83 |

**Erklärung:**
- Der vorherige Report wurde fast vollständig abgearbeitet (157/190 = 84%).
- Der **neue, tiefere Crawl** mit `model: opus` hat zahlreiche bisher unentdeckte Findings ans Licht gebracht — vor allem Repository-Bypass-Patterns, die in der ersten Runde nicht systematisch geprüft wurden.
- **Ionic-Projekt selbst hat keine neuen Commits seit 2026-02-23** — die neuen Findings sind also ausnahmslos bereits existierende Lücken/Bugs in der Flutter-Implementierung, die jetzt entdeckt wurden.

---

## Top-10 Action Items (priorisiert)

1. **[MC-001] B7-C001 Calendar-Subscription Webhook-URL falsch** — KRITISCH — 0.5h
   *Calendar-Abo führt auf 404, Feature ist faktisch broken*

2. **[MC-002] B4-018 SongViewer Public-Page komplett fehlt** — KRITISCH — 8h
   *Share-Links auf Songs sind tot — keine öffentliche Read-Only-View existiert*

3. **[MC-003] B7-P001 Profilbild-Upload komplett fehlt** — KRITISCH — 8h
   *User können kein Passbild hochladen, kein Image-Picker, kein Storage-Upload*

4. **[MC-004] B1-008 Tenant-Erstellung ohne Transaktion** — KRITISCH — 4h
   *3 Inserts (tenants, tenantUsers, instruments) ohne atomare Klammer → verwaiste Daten möglich*

5. **[MC-005] B2-020 attendance_detail_page: 11x direkter Supabase-Bypass** — HOCH — 3h
   *Notes, Deadline, Times, Songs, Image, Checklist — alle umgehen Repository*

6. **[MC-006] Repository-Bypass-Audit (Sammelposten)** — HOCH — 12h
   *Mind. 20 Stellen identifiziert: B3-022/023/024/028, B5-009/023, B6-005/017/027, B7-G006/P002/U003, B8-019, B10-008/009 u.a.*

7. **[MC-007] B7-S001 Stammdaten-Card auf Settings fehlt** — HOCH — 3h
   *UX-Regression: Profilfoto/Name/Geburtstag prominent vs. versteckt unter "Profil"*

8. **[MC-008] Settings-Page: 6 fehlende Buttons (B7-S002-S008)** — HOCH — 14h
   *Statistiken, Export, Werkhistorie, Ablaufpläne, Admins, Handover — alle unzugänglich*

9. **[MC-009] B6-012 include_in_average ignoriert** — HOCH — 1h
   *Statistik berechnet Durchschnitt über ALLE Anwesenheiten — verfälscht Ergebnisse*

10. **[MC-010] Custom-Reason-Dialog kaputt (4× gleicher Bug)** — HOCH — 5h
    *B5-006/007/021/022: Bulk + Single-Sign-Out mit "Sonstiger Grund" funktioniert nicht*

---

## KRITISCHE Findings

### [MC-001] Calendar-Subscription Webhook-URL falsch (B7-C001)
- **Typ:** BUG
- **Page:** Calendar Subscription
- **Ionic:** `settings.page.ts:600` — `https://n8n.srv1053762.hstgr.cloud/webhook/attendix?tenantId=X`
- **Flutter:** `calendar_subscription_page.dart:21` — `https://attendix.de/api/calendar/X.ics`
- **Effort:** 0.5h
- **Fix:** URL-Konstante anpassen
- **Status:** [ ] Offen

### [MC-002] SongViewer Public-Page fehlt (B4-018)
- **Typ:** MISSING_FEATURE
- **Page:** Song-Viewer (`/songs/:sharingId`)
- **Ionic:** `song-viewer/song-viewer.page.ts` (komplette Datei)
- **Flutter:** keine Route, keine Page, keine Repository-Methode
- **Effort:** 8h
- **Fix:** Public Read-Only Songs-Page bauen + `getTenantBySongSharingId()` im Repository
- **Status:** [ ] Offen
- **Folgefindings:** B4-019, B4-020 (Share-Links erzeugen tote Links)

### [MC-003] Profilbild-Upload komplett fehlend (B7-P001)
- **Typ:** MISSING_FEATURE
- **Page:** Profile (Stammdaten)
- **Ionic:** `settings.page.ts:644-720` mit `changeImg()` ActionSheet, max 2MB Validierung
- **Flutter:** `profile_page.dart:265-282` — nur Initialen-Avatar
- **Effort:** 8h
- **Fix:** image_picker + Supabase Storage Upload + Größenvalidierung + Action-Sheet
- **Status:** [ ] Offen

### [MC-004] Tenant-Erstellung ohne Transaktion (B1-008)
- **Typ:** BUG
- **Page:** Tenant Create
- **Ionic:** `register.page.ts:48-49` (db.createInstance, zentraler Service)
- **Flutter:** `tenant_create_page.dart:425-501` — 3 direkte Inserts ohne Rollback
- **Effort:** 4h
- **Fix:** Supabase RPC oder Compensating Transactions im TenantRepository
- **Status:** [ ] Offen

---

## HOCH-Priorität Findings (42)

### Repository-Bypass-Cluster (15 Findings)

Stellen wo direkt `supabase.from(...)` in UI/Page/Provider statt Repository genutzt wird:

| ID | Page/Datei | Effort |
|----|------------|--------|
| B2-020 | attendance_detail_page.dart (11 Calls) | 3h |
| B3-022 | person_detail_page.dart (personProvider) | 1h |
| B3-023 | person_detail_page.dart (_saveChanges, snake/camel mix) | 1h |
| B3-024 | person_detail_page.dart (kein Notifier) | 1.5h |
| B3-028 | members_providers.dart | 1.5h |
| B4-011 | copy_to_tenant_sheet.dart | 2h |
| B5-024 | parents_providers.dart force-unwrap tenant.id! | 0.25h |
| B6-005 | planning_page.dart (_savePlan, _toggleSharePlan) | 1.5h |
| B6-017 | history_page.dart (_addEntries, _deleteEntry) | 2h |
| B7-G006 | general_settings_page.dart (_saveSettings) | 1h |
| B7-P002 | profile_page.dart (_loadProfile, _saveProfile) | 2h |
| B7-U003 | user_management_page.dart (tenantUsersProvider) | 3h |
| B8-019 | copy_shift_to_tenant_sheet.dart | 2h |
| B10-007 | handover_sheet.dart (Tenants-Liste) | 1.5h |
| B10-008/009 | handover_sheet.dart (Groups + Roles) | 1.5h |

**Gesamteffort:** ~25h — als ein großer Refactoring-Batch sinnvoll

### People (B3-001 bis B3-015) — 10 Findings

| ID | Titel | Effort |
|----|-------|--------|
| B3-001 | Filter "Mitglied anderer Instanz" fehlt | 4h |
| B3-002 | Custom-Felder (additional_fields) in Liste/Filter fehlen | 6h |
| B3-011 | Cross-Instance-Lookup beim Anlegen fehlt | 4h |
| B3-012 | Daten-Übernahme aus anderen Instanzen fehlt | 3h |
| B3-013 | Stimmführer-Rollen-Bestätigungsdialog (3-Wege) fehlt | 3h |
| B3-014 | Auto-Rollen-Wechsel bei Hauptgruppen-Wechsel fehlt | 2h |
| B3-015 | Account-Erstellen-Dialog beim E-Mail-Hinzufügen fehlt | 2h |
| B3-027 | Members-Page Einteilung-Filter fehlt | 3h |

### Settings-Section-Lücken (8 Findings)

| ID | Titel | Effort |
|----|-------|--------|
| B7-S001 | Stammdaten-Card auf Settings fehlt | 3h |
| B7-S002 | Statistiken Button fehlt | 1h |
| B7-S003 | Export Button fehlt | 1h |
| B7-S004 | Werkhistorie Button fehlt | 1h |
| B7-S005 | Ablaufpläne Button fehlt | 1h |
| B7-S007 | Admin-Verwaltung (Email-Einladung) fehlt | 4h |
| B7-S008 | Personenübergabe Button fehlt | 4h |
| B7-S009 | Instanz-Wechsler Sheet fehlt | 3h |
| B7-S010 | Passwort ändern direkt in Settings | 1h |
| B7-S014 | Telegram Support URL falsch (Bot statt Owner) | 0.25h |
| B7-G001 | evaluate-critical-rules Edge-Function-Aufruf | 0.5h |
| B7-G002 | BFECG_CHURCH Field-Type fehlt | 1h |
| B7-U001 | Add Admin via Email-Einladung fehlt | 3h |
| B7-U002 | Remove User Action fehlt | 3h |

### Sonstige HOCH-Findings (12)

| ID | Titel | Page | Effort |
|----|-------|------|--------|
| B1-009 | Tenant-Default-Felder fehlen (timezone, withExcuses, betaProgram) | Tenant Create | 0.5h |
| B2-010 | Realtime-Channel für attendance-Tabelle fehlt | Attendance Detail | 2h |
| B2-011 | ATTENDANCE_STATUS_MAPPING (8 Varianten) unmigriert | Attendance Detail | 2h |
| B4-001 | Public Song-Viewer Route fehlt | Songs | 8h |
| B4-002 | getTenantBySongSharingId fehlt | Tenant Repo | 1h |
| B4-008 | Liedtext-Format-Warnung beim Upload fehlt | Song Detail | 1h |
| B4-019 | Share-Link in songs_list erzeugt toten Link | Songs List | 0.5h |
| B4-020 | Share-Link im Detail erzeugt toten Link | Song Detail | 0.5h |
| B5-006 | _showCustomReasonDialog hat doppeltes Navigator.pop | Self-Service | 1h |
| B5-007 | Sign-Out 'Sonstiger Grund' aus BottomSheet kaputt | Self-Service | 2h |
| B5-014 | Noten-Datei-Optionen pro Song unvollständig | Self-Service | 2h |
| B5-015 | printAllCurrentFiles (PDF-Merge) fehlt komplett | Self-Service | 8h |
| B5-021 | _showBulkSignOutDialog 'Sonstiger Grund' bricht Bulk | Parents | 1.5h |
| B5-024 | parentChildrenProvider force-unwrap auf tenant.id! | Parents | 0.25h |
| B6-012 | include_in_average wird nicht beachtet (verfälscht Stats) | Statistics | 1h |
| B6-023 | Export filtert ausgetretene/pausierende Spieler aus | Export | 0.5h |
| B7-P003 | additional_fields im Profil fehlen | Profile | 4h |
| B7-P004 | _getRoleName mit veralteten Hardcoded-Integers | Profile | 0.5h |
| B8-017 | isUsed-Schutz für Feste Schichten fehlt | Shift Detail | 1h |
| B9-008 | AI-Synonym-Generation komplett fehlend | Instrument | 6h |
| B9-012 | Teacher-Detail Spielerliste-Accordion fehlt | Teacher | 2h |

---

## MITTEL-Priorität Findings (95)

(Vollständige Liste — verkürzt gruppiert)

### Sign-Out / Self-Service (11)
B5-001, B5-002, B5-003, B5-008, B5-010, B5-011, B5-012, B5-016, B5-019, B5-020, B5-022

### Attendance Detail/Create (17)
B2-003, B2-004, B2-006, B2-007, B2-012, B2-013, B2-014, B2-015, B2-016, B2-017, B2-021, B2-022, B2-023, B2-026, B2-027, B2-029, B2-030, B2-032

### Planning/Stats/History/Export (13)
B6-001, B6-002, B6-006, B6-007, B6-010, B6-013, B6-018, B6-019, B6-021, B6-024, B6-025, B6-027, B6-028 (Service Gap)

### People (11)
B3-003, B3-004, B3-005, B3-006, B3-007, B3-008, B3-016, B3-017, B3-018, B3-019, B3-025

### Settings (13)
B7-S011, B7-S012, B7-S013, B7-S015, B7-S016, B7-G003, B7-G004, B7-G005, B7-G007, B7-G008, B7-G009, B7-N001, B7-P005, B7-P006, B7-U004

### Types/Shifts (6)
B8-003, B8-004, B8-010, B8-011, B8-012, B8-018, B8-020, B8-021

### Songs (8)
B4-003, B4-004, B4-009, B4-010, B4-012, B4-013, B4-014, B4-015

### Instruments/Teachers (4)
B9-001, B9-002, B9-007, B9-013

### Meetings/Handover (6)
B10-002, B10-005, B10-006, B10-008, B10-009, B10-013

### Auth (4)
B1-005, B1-010, B1-011, B1-015

---

## NIEDRIG-Priorität Findings (101)

(Sammlung — für ruhige Sprints / Cleanup-Batches)

Alle übrigen B*-IDs nicht oben gelistet. Beispiele:
- UI-Polish (Sticky-Headers, Singular/Plural, Badges)
- Helper-Texte fehlen
- Haptic-Feedback fehlt
- iOS-spezifische Fallbacks
- Kosmetische Toggle-Inkonsistenzen

---

## Page-für-Page Übersicht

### Auth (Score: 81%)

#### Login (88%)
- ✅ E-Mail/Passwort, Demo-Login, Auto-Tenant-Navigation, AuthException-Mapping
- 🟡 B1-001 Repository-Bypass, B1-002 schwächere E-Mail-Validierung, B1-003 keine autofillHints

#### Register (85%)
- ✅ Validierung, Passwort-Toggle, lokalisierte Errors
- 🟡 B1-004 redundant zu Tenant-Register, B1-005 Existing-User-Detection fehlt, B1-006 Bypass, B1-007 kein "E-Mail erneut senden"

#### Tenant Create (70%)
- 🔴 **B1-008 Keine Transaktion → verwaiste Daten möglich (KRITISCH)**
- 🟠 B1-009 Default-Felder fehlen, B1-010-016 verschiedene UX-Lücken

### Attendance (Score: 83%)

#### Attendance List (82%)
- ✅ Realtime, Slidable, Kalender-View, Skeleton, Role-Check
- 🟠 B2-001 Legenden-Modal fehlt, B2-002 Add-Modal fehlt
- 🟡 B2-003 Viewer-Modus fehlt, B2-004 X von Y anwesend fehlt

#### Attendance Detail (78%)
- ✅ Realtime, Optimistic Updates, Checklists, Songs/Plan-Akkordeons, Export
- 🟠 **B2-020 11x direkter Supabase-Bypass**
- 🟠 B2-010 Realtime-Channel attendance fehlt, B2-011 Status-Mapping fehlt

#### Attendance Create (88%)
- ✅ Multi-Date, Holiday-Highlighting, Shift-Auto-Status
- 🟠 B2-032 Duplicate-Check umgangen, B2-029 Toast inkonsistent

### People (Score: 79%)

#### People List (78%)
- ✅ Filter, Sort, View-Options persistiert, Realtime, Pause/Archive
- 🟠 **B3-001 + B3-002** (4h+6h große Cross-Instance/Custom-Field-Lücken)
- 🟡 viele kleinere Filter-/Sort-Lücken

#### Person Detail/Create (76%)
- ✅ Inline-Edit, Pause/Archive/Delete, Approve/Decline, Image, additional_fields
- 🔴 **B3-022/023/024 Repository-Bypass + camelCase/snake_case mix**
- 🟠 6 große Cross-Tenant Workflow-Features fehlen (B3-011 bis B3-015)

#### Members (82%)
- ✅ Gruppierung, Suche, Stimmführer-Badge
- 🟠 **B3-027 Einteilung-Filter komplett fehlt**, B3-028 Bypass

### Songs (Score: 53%) — Niedrigster Score

#### Songs List (80%)
- ✅ Realtime, Filter, Sortierung, Kategorien, Share-Link
- 🟠 B4-001/002 Public-Sharing fehlt, B4-019 toter Link

#### Song Detail (78%)
- ✅ Inline-Edit, File-Upload, ZIP, Smart-Print, Telegram, Copy-to-Tenant
- 🟠 B4-008/009/010 Upload-Validierungen fehlen, B4-011 Bypass, B4-012 Realtime fehlt

#### Song Viewer (0%) 🔴
- **Komplett fehlend (B4-018 KRITISCH)**

### Self-Service (Score: 74%)

#### Overview (78%)
- ✅ Cross-Tenant, Sign-In/Out/Late, Statistik, Songs/Plan
- 🟠 4× Custom-Reason-Bug (B5-006/007), B5-009 Bypass

#### Single-Tenant Signout (65%)
- 🟠 B5-014/015 Print/PDF-Merge fehlen, B5-016 Färbung fehlt
- ⚠️ Architektur: konsolidiert in Overview, valide aber Funktions-Lücken

#### Parents Portal (80%)
- ✅ Multi-Kid, Bulk-Actions, Sign-Out-Reasons
- 🟠 B5-019 Songs fehlen, B5-021/022 Custom-Reason kaputt, **B5-024 force-unwrap**

### Planning/Stats/History/Export (Score: 79%)

#### Planning (78%)
- ✅ Drag&Drop, Werke, Telegram, PDF, Registerprobenplan
- 🟠 B6-005 Bypass, B6-001 fehlende Stimmen, B6-006 silent fail, B6-007 kein Reset-Confirm

#### Statistics (88%)
- ✅ 7 Charts, Diva-Index, Altersverteilung, Cross-Tenant
- 🟠 **B6-012 include_in_average ignoriert (verfälscht alle Statistiken!)**

#### History (72%)
- ✅ Suche, Werk-Hinzufügen, Dirigent-Auswahl
- 🟠 B6-017 Bypass, B6-018 Proben-Counter fehlt, B6-019 Accordion fehlt

#### Export (80%)
- ✅ PDF/Excel, Felder-Auswahl, 8-Termine-Limit
- 🟠 B6-023 Filter-Bug, B6-024/025 Custom-Fields fehlen, B6-027 Bypass

### Settings (Score: 78%)

#### Settings Page (62%) — Niedrigster Score in Batch 7
- ✅ Tenant-Card, Pending-Badge, Logout, Feedback, Version
- 🟠 **8 große HOCH-Findings (B7-S001-S010)** — Stammdaten-Card, Stats, Export, History, Planning, Admins, Handover, Instanz-Wechsler

#### General Settings (78%)
- ✅ Saisonbeginn, Probenzeiten, Holidays, Critical Rules, Extra-Fields
- 🟠 B7-G001 Edge-Function-Aufruf fehlt, B7-G002 BFECG-Type, B7-G006 Bypass

#### Notifications (88%)
- ✅ Master-Toggle, Telegram-Verbindung, Per-Instance, Optimistic
- 🟡 nur kleinere UX-Lücken

#### Profile (65%)
- 🔴 **B7-P001 Image-Upload komplett fehlt (KRITISCH)**
- 🟠 B7-P002 Bypass, B7-P003 additional_fields fehlen, B7-P004 Hardcoded Roles

#### User Management (70%)
- ✅ Tabs, Last-Admin-Schutz, Self-Demotion-Warnung
- 🟠 B7-U001 Email-Einladung fehlt, B7-U002 Remove-Action fehlt, B7-U003 Bypass

#### Calendar Subscription (90%)
- 🔴 **B7-C001 Falsche Webhook-URL — Feature broken (KRITISCH)**

#### Pending Players (88%) ✅ Sauber migriert

#### Left Players (85%) ✅ Sauber migriert

### Types/Shifts (Score: 84%)

#### Attendance Types List (88%) ✅ Solide
#### Attendance Type Edit (80%)
- ✅ Ablaufplan-Editor, Erinnerungen, Checkliste, PopScope
- 🟠 B8-011 enum.name vs enum.value, B8-012 Delete blockiert

#### Shifts List (92%) ✅ Sauber
#### Shift Detail (78%)
- 🟠 B8-017 isUsed-Schutz, **B8-018 Cross-Tenant Update fehlt**, B8-019/020 Bypass

### Instruments/Teachers (Score: 81%)

#### Instruments List (88%) ✅ Solide, Verbesserungen ggü. Ionic
#### Instrument Detail (72%) — Dialog statt Page
- 🟠 B9-008 AI-Synonym fehlt komplett

#### Teachers List (92%) ✅ Mit Verbesserungen
#### Teacher Detail (70%)
- 🟠 B9-012 Spielerliste-Accordion fehlt

### Meetings/Handover/Voice-Leader (Score: 87%) — Höchster Score

#### Meetings List (95%) ✅ Mit Flutter-Extras
#### Meeting Detail (92%) ✅ Solide, Quill-Editor

#### Handover (78%)
- 🟠 **B10-007 Tenants-Liste falsch (Org statt UserTenants)**, B10-008/009 Bypass
- 🟡 B10-005/006/010 Filter/Editing-Features fehlen

#### Voice Leader (85%)
- 🟡 B10-013 Einteilung-Badge, B10-014/016 kleinere Lücken

---

## Patterns / Trends

### 1. Repository-Bypass ist das dominante Architektur-Problem
**Mind. 20 Stellen** im Code umgehen das Repository-Pattern und greifen direkt auf `supabaseClientProvider` zu. Häufigster Auslöser: Inline-Edit-Felder, Cross-Tenant-Operationen, Provider die "schnell" gebaut wurden.

**Vorschlag:** Großes Refactoring-Sprint — alle Stellen migrieren + Lint-Regel ergänzen.

### 2. Custom-Reason-Dialog Pattern (4× gleicher Bug)
Sign-Out-mit-Sonstiger-Grund ist in 4 verschiedenen Pages gebrochen (B5-006/007/021/022). Das BottomSheet schließt vorzeitig, der Custom-Dialog ruft signOut nur lokal auf.

**Vorschlag:** Zentralen `SignOutReasonHelper` bauen, alle 4 Stellen migrieren.

### 3. Cross-Tenant-Operationen ohne zentrale Validierung
B8-019, B8-020, B10-007 — Schreibvorgänge in fremde Tenants ohne explizite Membership-Validierung.

**Vorschlag:** `CrossTenantService` mit zentraler Validierung + Audit-Log.

### 4. Force-Unwrap auf `tenant.id!` (immer noch)
B5-024 — selbe Klasse Bug wie der bereits gefixte (Phase 1 oder 2). Pattern wiederholt sich.

**Vorschlag:** Lint-Regel oder Code-Review-Checkliste für `tenant.id!`.

### 5. Public-Sharing-Features unvollständig
Song-Viewer (B4-018) komplett fehlend, Share-Links erzeugen tote URLs (B4-019/020). Auch Calendar-Subscription URL falsch (B7-C001).

**Vorschlag:** "Public-Routes" als eigener Migration-Sprint.

### 6. Settings-Page als Hub fehlt fast alles
Statistiken, Export, Werkhistorie, Ablaufpläne, Admins, Handover — alle nur über Umwege erreichbar (oder gar nicht). Die Flutter-Settings ist eine deutliche UX-Regression gegenüber Ionic.

**Vorschlag:** Settings-Page als ein einziger großer Sprint.

---

## Scan-Details

- **Datum:** 2026-06-17
- **Batches gescannt:** 1-10 (alle)
- **Agents verwendet:** 10× page-crawler (Opus, parallel)
- **Token-Budget:** ~1.13M Tokens (Aggregation aller Agents)
- **Laufzeit:** ~9 Minuten parallel

### Ionic-Aktivität seit letztem Crawl
**Keine neuen Commits seit 2026-02-23** — Ionic-Projekt steht still, alle 252 Findings sind bestehende Lücken in Flutter.

### Skills/Agents Status
- `migration-crawl/` und `page-crawler.md` sind aktuell (2026-03-04)
- Andere Skills (`flutter-reviewer`, `parity-audit`, `bug-hunt`) sind ~4 Monate alt — könnten Review nutzen, aber nicht-blockierend

---

## Empfohlene Sprint-Aufteilung

### Sprint 1: KRITISCH (3 Tage)
- MC-001 Calendar-URL fix (0.5h)
- MC-004 Tenant-Erstellung Transaktion (4h)
- MC-002 SongViewer Public-Page (8h)
- MC-003 Profilbild-Upload (8h)

### Sprint 2: Repository-Bypass-Refactoring (4 Tage)
- ~25h alle 15 Bypass-Stellen + Lint-Regel
- Inkl. neue Repository-Methoden (B2-026/027)

### Sprint 3: Settings-Hub-Restructuring (3 Tage)
- B7-S001 bis B7-S010 (~20h)
- Inkl. User-Management Add/Remove (B7-U001/U002)

### Sprint 4: Sign-Out-Pattern + Stats-Bug (1 Tag)
- MC-010 Custom-Reason-Helper (5h)
- B6-012 include_in_average (1h)
- B6-023 Export-Filter (0.5h)

### Sprint 5: People Cross-Instance (3 Tage)
- B3-001/002 (10h Filter)
- B3-011/012 (7h Cross-Instance)
- B3-013/014/015 (7h Workflow-Dialoge)

### Sprint 6: NIEDRIG-Cleanup (laufend)
- 101 NIEDRIG-Findings — als Tickets in Wochen-Sprints

---

## Nächste Schritte

1. **GitHub Issues erstellen** für alle KRITISCH + HOCH Findings (oder vorhandene Issues #178-210 verifizieren)
2. **Sprint 1 starten:** Mit `/fix-bug B7-C001` oder `/ionic-migrate calendar-subscription`
3. **Memory aktualisieren:** Neuer Status ("Phase 9 Migration-Crawl 2026-06-17")
4. **Skills-Review (optional):** Andere Skills auf neue Patterns updaten

**Tipp:** Nutze `/ionic-migrate [feature]` oder `/fix-bug [B*-XXX]` um Findings zu beheben.
