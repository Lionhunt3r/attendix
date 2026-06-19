# Migration Crawl Report — v4.0.5
**Datum:** 2026-06-17
**Scope:** full (11 Batches: 10 Standard + 1 NEW Pages)
**Ionic-Version:** 4.0.5 (Commit b3ea25d, 2026-06-17)
**Vorheriger Report:** stale (.claude/migration-crawl-report-stale-*.md, lief auf v3.8.3)

> ⚠️ **Wichtiger Kontext:** Der erste Re-Crawl heute lief auf einer veralteten Ionic-Codebasis (v3.8.3). Das Ionic-Repo war 160 Commits hinten dran. Nach `git pull` wurde der Crawl mit der aktuellen v4.0.5 wiederholt. Dieser Report ersetzt vollständig alle vorherigen.

## Zusammenfassung

| Metrik | Wert |
|--------|------|
| Gescannte Ionic Pages (inkl. neue) | ~52 |
| Gescannte Flutter Pages | ~40 |
| Durchschnittlicher Score | **57%** |
| Gesamt-Findings | **315** |

| Kategorie | KRITISCH | HOCH | MITTEL | NIEDRIG | Gesamt |
|-----------|----------|------|--------|---------|--------|
| Missing Feature | 22 | 64 | 75 | 41 | 202 |
| Bug | 5 | 22 | 26 | 13 | 66 |
| UX Gap | 0 | 1 | 14 | 14 | 29 |
| Service Gap | 3 | 14 | 3 | 0 | 20 |
| **Gesamt** | **30** | **101** | **118** | **66** | **315** |

### Kontext: Was hat sich seit Februar 2026 in Ionic getan?

**160 neue Commits, Sprung von v3.8.3 → v4.0.5 (Major-Release).** Komplett neue Features:

🆕 **8 neue Pages:**
- Dashboard (Usage Analytics, Super-Admin)
- People Bulk-Edit
- Settings/Delete-Account (DSGVO)
- Settings/Files (Tenant Storage)
- Settings/Role-Permissions
- Legal-Page (Datenschutz/Impressum)
- Login/Legal-Modal (DSGVO Consent)
- App-Redirect (Native App Sharing)

🆕 **6 neue Services:**
- `services/push/` — Firebase Messaging Integration
- `services/audio-player/` — Recordings abspielen
- `services/files/` — Tenant Storage CRUD
- `services/legal/` — DSGVO-Inhalte
- `services/role-permission/` — konfigurierbare Permissions
- `services/tracking/` — usage_events Telemetrie

🆕 **10+ neue SQL-Migrationen:**
- `add_shift_excused_as_present.sql`
- `add_evaluate_critical_rules_attendances.sql`
- `add_role_permission_columns.sql`
- `add_sort_order_to_instruments.sql`
- `add_sort_order_to_group_categories.sql`
- `usage_events.sql`
- `enable_rls_all_tables.sql`
- `add_unique_constraint_person_attendance.sql`
- u.a.

🔄 **Wichtige Refactorings:**
- "Better cross-tenant person matching" (mehrere Commits)
- Cold-start push deterministic two-stage fetch
- Profile section redesign mit Card-Layout
- iOS-only FAB für Ablaufplan (heute committed, b3ea25d)

---

## 🔴 KRITISCHE Findings (30)

Zusammengefasst nach Themen-Cluster:

### Cluster A: DSGVO/Legal (4 KRITISCHE) ⚠️ App-Store-Risiko

| ID | Titel | Effort |
|----|-------|--------|
| **B11-005 / B7-026** | Delete-Account-Page komplett fehlt (Recht auf Löschung Art. 17) | 4h+8h |
| **B11-012 / B11-013** | Legal-Page (Impressum/Datenschutz) fehlt + LegalService | 2h+1h |
| **B11-014** | Legal-Modal beim Login fehlt (DSGVO Consent vor Account) | 2h |
| **B7-001** | Konto-Löschen-Workflow fehlt im Settings-Hub | 8h |

### Cluster B: Push-Notifications (1 KRITISCH + 8 HOCH/MITTEL)

| ID | Titel | Effort |
|----|-------|--------|
| **B11-017** | Push-Notifications fehlen vollständig — keine `firebase_messaging`, kein `device_tokens`-Tabellen-Wiring | 16h |
| B5-001 | Push-Service für Self-Service fehlt | (Teil von B11-017) |
| B5-025 | Push-Notifications für Eltern fehlen | (Teil von B11-017) |
| B11-018 | device_tokens-Tabelle nicht angebunden | 2h |
| B11-019 | Push-Toggle in Settings ohne Funktion | 1h |
| B2-017 | Push-Service Integration fehlt für Attendance | (Teil von B11-017) |

### Cluster C: Cold-Start / Realtime / Auto-Close (4 KRITISCHE)

| ID | Titel | Effort |
|----|-------|--------|
| **B2-007** | Notiz-ActionSheet mit vordefinierten Gründen fehlt (Ionic 7255abc) | 3h |
| **B2-008** | Conductor-Wechsel im Attendance-Modal fehlt (Ionic abc98c5) | 4h |
| **B2-009** | Tenant-Change Auto-Close fehlt — **Cross-Tenant-Datenleck-Risiko** | 1.5h |
| **B2-010** | Cold-Start Push deterministic two-stage fetch fehlt — RLS-Race nach Auth-Restore | 4h |

### Cluster D: Cross-Tenant Person-Matching (2 KRITISCH + 1 HOCH)

| ID | Titel | Effort |
|----|-------|--------|
| **B3-010** | Cross-Tenant Person-Matching (Typeahead) komplett fehlt — Levenshtein, RankedMatch | 16h |
| **B3-011** | Email-Blur Cross-Tenant-Match Lookup fehlt | 6h |
| **B10-007** | Email-Vergleich case-sensitive in Flutter (vs `.ilike()` in Ionic) → Duplikate werden NICHT erkannt | 0.5h |

### Cluster E: Architektur/Tenant (2 KRITISCH)

| ID | Titel | Effort |
|----|-------|--------|
| **B1-015** | Tenant-Create umgeht Repository, fehlende Defaults (timezone, withExcuses, betaProgram) | 4h |
| **B6-011** | `include_in_average` ignoriert in Statistics → verfälschte Durchschnittsberechnung | 1h |

### Cluster F: Songs (2 KRITISCH)

| ID | Titel | Effort |
|----|-------|--------|
| **B4-001 / B4-018** | Public Song-Viewer Route + Page komplett fehlt | 8h+6h |
| **B6-025** | `additional_fields` (ExtraFields) im Export komplett fehlend | 4h |

### Cluster G: Compliance/Settings (3 KRITISCH)

| ID | Titel | Effort |
|----|-------|--------|
| **B7-002 / B7-028** | Files-Page komplett fehlt (Tenant-Datei-Browser) | 16h |
| **B7-029** | FilesService und StorageEntry Model fehlen | 6h |
| **B8-017** | updateShiftAttendances nach Copy-to-Tenant fehlt → Daten-Inkonsistenz | 3h |

### Cluster H: Bulk-Operations (1 KRITISCH)

| ID | Titel | Effort |
|----|-------|--------|
| **B11-003 / B3-030** | Bulk-Edit Page für Personen fehlt komplett | 6h+16h |

---

## 🟠 HOCH-Priorität Findings (101)

Zusammengefasst nach Bereichen:

### Repository-Bypass-Cluster (~20 Stellen, ~30h)

Direkter `supabase.from(...)` in UI/Provider statt Repository:
- B2-020 attendance_detail_page.dart (11 Calls)
- B3-019/020 person_detail_page.dart
- B3-028 members_providers.dart
- B4-011 copy_to_tenant_sheet.dart
- B5-013/014/033/034 self-service & parents Provider
- B6-006/007/020 planning, history
- B7-021 general_settings
- B8-018 copy_shift_to_tenant_sheet
- B10-008/009/013 handover_sheet, voice_leader

### Tracking-Service (`usage_events`) — 7 HOCH/MITTEL

Komplett fehlend, betrifft Login, Attendance, Parents, Songs, Export, Meetings, Handover, Player CRUD:
- B11-020 Tracking-Service fehlt komplett (3h)
- B11-001 / B11-002 Dashboard-Page + UsageEvents-Repository (8h+1h)
- B1-002 Tracking Login fehlt (6h)
- B2-033 TrackingService für Attendance (4h)
- B5-002 / B5-026 Tracking Sign-In/Out (8h+2h)
- B6-028 Tracking Export (3h)
- B10-001 Tracking MeetingCreated, B10-015 HandoverCreated (1h)

### Audio-Player-Service — 4 HOCH

- B11-022 Audio-Player-Service fehlt (4h)
- B4-006/020/021 AudioPlayerService + Component für Songs (8h+6h+4h)
- B5-006/022 Audio-Player für Self-Service (6h+8h)

### Role-Permissions (konfigurierbar) — 3 HOCH

- B11-009/010/011 Role-Permissions-Page + Tabelle + Enforcement (8h+4h+3h)
- B7-031/032 Role-Permissions im Settings (6h+3h)

### People (Cross-Instance + Workflows) — 8 HOCH

- B3-012/013/014/015 isLeader-Dialog, Email-Account, syncPlayerWithUpcoming, informUserAboutApproval
- B3-001/002 Filter "andere Instanz" + Bulk-Bearbeitung
- B3-025/026 getPossiblePersonsByName + Person-Matcher Utility (8h+4h)

### Settings-Hub — 8 HOCH

- B7-003 Role-Permissions
- B7-004 Dynamic Legal Page
- B7-005/006/033 Profile redesign + Passbild-Upload
- B7-007/008/009 Viewer-/Admin-Verwaltung + Multi-Tenant Wechsel-Modal
- B7-014/015 absence_reasons/late_reasons + shift_excused_as_present

### Songs — 4 HOCH

- B4-006 Audio-Player (siehe oben)
- B4-008 Liedtext-Format-Warnung
- B4-011 Auto-Save Text-Felder unsauber
- B4-015 Download iOS deaktiviert ohne Fallback

### Self-Service — 8 HOCH

- B5-003/028 absence_reasons/late_reasons (Tenant-Konfig)
- B5-004 printAllCurrentFiles (PDF-Merge)
- B5-005 Choir-Type 'Chor' Files Fallback
- B5-007/029 Beschreibung (Quill HTML) + Anhang-Modal
- B5-012 Custom-Reason-Dialog Bug
- B5-027 Aktuelle Werke (Songs Modal) im Parents Portal
- B5-042 ParentsRepository fehlt

### Attendance — 9 HOCH

- B2-011 Visibility-Resume-Refetch (App-Lifecycle)
- B2-012 Manuelles Hinzufügen von Personen
- B2-013 Ad-Hoc Erinnerung
- B2-014 iOS-only FAB für Ablaufplan (heute commited!)
- B2-015 Anhang (Datei) hinzufügen/entfernen
- B2-016 Status-Mapping je available_statuses (8 Varianten)
- B2-019 _loadSongEntries history-table
- B2-032 getAttendanceByIdRobust fehlt

### Planning/Stats/History/Export — 12 HOCH

- B6-001 Registerprobenplan-Feature
- B6-002 getMissingGroups
- B6-013 Diva-Index-Chart Data-Misuse
- B6-017/018 History count-Berechnung + Accordion
- B6-026/027 Export-Felder fehlend + keine Player/Attendance-Differenzierung
- B6-029 Excel-Export 100-Termine-Limit

### Tenant Create + Auth — 6 HOCH

- B1-001/005 Legal-Link + LegalService
- B1-002 Tracking Login
- B1-009 Telefonnummer-Validierung
- B1-010 Einverständnis-Toggle
- B1-016/017 Tenant-Defaults + isSection-Konflikt
- B1-022 App-Redirect-Page

### Sonstige — ~15

- B8-018/019 Cross-Tenant Shift-Insert + isUsed-Schutz
- B8-020 Auto-Re-Index Segmente
- B8-023 evaluate-critical-rules Edge-Function
- B9-001/002/003/004 Reorder Instrumente + sort_order Spalte (NEU SQL)
- B9-008/015 AI-Synonym + Teacher-Spielerliste
- B11-016 Deep-Linking
- B11-018 device_tokens-Tabelle

---

## 📊 Score pro Bereich (Sprint-Reihenfolge)

```
Batch 11 (Neue Pages):              1%  🔴🔴 — komplett fehlend
Batch 4 (Songs):                   38%  🔴 — Public-Viewer + Audio-Player fehlen
Batch 7 (Settings):                41%  🔴 — Hub-Lücken + 3 neue Pages
Batch 3 (People):                  50%  🔴 — Cross-Tenant + Bulk-Edit
Batch 1 (Auth):                    51%  🔴 — Legal + App-Redirect
Batch 2 (Attendance):              65%  🟠 — Push + Cold-Start + Conductor
Batch 5 (Self-Service):            66%  🟠 — Push + Audio + Reasons
Batch 6 (Planning):                73%  🟡
Batch 9 (Instruments):             74%  🟡
Batch 8 (Types/Shifts):            79%  🟢
Batch 10 (Meetings/Handover):      85%  🟢
```

---

## Empfohlene Sprint-Aufteilung

### Sprint 0: DSGVO-Compliance (3 Tage) ⚠️ Vor App-Store-Release
- B7-026/B11-005: Delete-Account-Page + Service (12h)
- B11-012/013: Legal-Page + LegalService (3h)
- B11-014: Legal-Modal beim Login (2h)
- B1-001: Legal-Link im Login-Footer (4h)

### Sprint 1: Cross-Cutting Services (5 Tage)
**Zuerst, weil viele andere Findings davon abhängen.**
- **TrackingService** + usage_events Repository (B11-020): 3h
- **AudioPlayerService** (B11-022): 4h
- **Push-Service** komplett (B11-017): 16h
- Deep-Linking Foundation (B11-016): 4h

### Sprint 2: Repository-Bypass-Refactoring (4 Tage)
~20 Stellen migrieren + Lint-Regel ergänzen (~30h):
- attendance_detail_page (11 Calls — größte Stelle)
- person_detail_page, members_providers
- copy_to_tenant_sheet, copy_shift_to_tenant_sheet
- planning_page, history_page, general_settings
- handover_sheet, parents_providers, self_service-Provider

### Sprint 3: Cold-Start + Realtime (2 Tage)
- B2-009 Tenant-Change Auto-Close (1.5h)
- B2-010 Cold-Start two-stage fetch (4h)
- B2-007 Notiz-ActionSheet mit Reasons (3h)
- B2-008 Conductor-Wechsel (4h)
- B2-011 Visibility-Resume (2h)

### Sprint 4: Cross-Tenant Person-Matching (3 Tage)
- B10-007 Email .ilike+.trim Fix (0.5h)
- B10-008 Empty-Email-Duplikat-Bug (0.5h)
- B10-009/010 Handover-Felder + Role.RESPONSIBLE (2.5h)
- B3-010/011 Person-Matcher Utility + Cross-Tenant Lookup (16h+6h)
- B3-025/026 getPossiblePersonsByName/Email Repository (12h)

### Sprint 5: Neue Pages (3 Tage)
- B11-003/B3-030: Bulk-Edit-Page (16h)
- B11-001/B11-002: Dashboard + UsageEventsRepository (9h)
- B11-009-011: Role-Permissions Page + Enforcement (15h)

### Sprint 6: Settings-Hub-Restructuring (3 Tage)
- B7-001/002/028: Delete-Account + Files-Page (kommt aus Sprint 0/5)
- B7-005/006/033: Profile-Redesign + Passbild-Upload (14h)
- B7-007/008/009: Viewer-/Admin-Verwaltung + Multi-Tenant Modal (10h)

### Sprint 7: People Workflows (3 Tage)
- B3-001/002: Filter "andere Instanz" + Custom-Felder (10h)
- B3-012/013: isLeader-Dialog + Email-Account-Frage (5h)
- B3-014/015: syncPlayerWithUpcoming + informUserAboutApproval (6h)

### Sprint 8: Songs Public-Sharing + Audio (2 Tage)
- B4-001/018/019: Song-Viewer Public-Page + Route (14h)
- B4-006/020/021: AudioPlayerService + Component für Songs (kommt aus Sprint 1)
- B4-008/011/015: Format-Warnung + Auto-Save + Download iOS (5h)

### Sprint 9: Statistics + Export Bug-Fixes (1 Tag)
- B6-011: include_in_average Filter (1h) — KRITISCH
- B6-025/026/027: Export ExtraFields + Felder + Diff (6.5h)
- B6-029: Excel-Export 100-Limit (1h)

### Sprint 10: Sign-Out-Pattern + Reasons (2 Tage)
- B5-003/028: tenant.absence_reasons/late_reasons (4h)
- B5-006/007/021/022 (alter Bug-Cluster) Custom-Reason-Helper (5h)
- B5-007/029: Beschreibung + Anhang-Modal (7h)
- B5-004: printAllCurrentFiles PDF-Merge (8h)

### Sprint 11: Attendance Workflows (2 Tage)
- B2-014: iOS-FAB Ablaufplan (1h)
- B2-012: Personen hinzufügen (6h)
- B2-013: Ad-Hoc Erinnerung (2h)
- B2-015: Anhang Datei (3h)
- B2-016: Status-Mapping 8 Varianten (3h)

### Sprint 12: Long Tail (laufend)
- 118 MITTEL + 66 NIEDRIG Findings als Tickets in Wochen-Sprints

---

## 🔄 Patterns / Trends

### 1. Drei dominante neue Querschnitts-Services fehlen
**Push, Tracking, AudioPlayer** tauchen in fast jedem Batch als HOCH-Finding auf. Diese drei Services zusammen sind ein eigener großer Sprint und Voraussetzung für viele andere Findings.

### 2. Repository-Bypass weiterhin größtes Architektur-Problem
**~20 Stellen** im Code umgehen das Repository-Pattern. Bestätigt aus dem ersten Re-Crawl. Weiterhin der dominanteste Anti-Pattern.

### 3. Cross-Tenant-Operationen ohne zentrale Validierung
Schreibvorgänge in fremde Tenants ohne explizite Membership-Validierung — Sicherheits-Risiko.

### 4. Custom-Reason-Dialog Pattern (4× gleicher Bug)
Sign-Out-mit-Sonstiger-Grund in 4 verschiedenen Pages gebrochen. Zentralen Helper bauen.

### 5. DSGVO-Compliance-Lücken sind App-Store-Risiko
Delete-Account, Legal-Page, Legal-Modal — alle drei fehlen. Vor App-Store-Submission **zwingend** zu beheben.

### 6. Public-Sharing-Features unvollständig
Song-Viewer, Calendar (Webhook-URL falsch im alten Crawl), Share-Links erzeugen tote URLs.

### 7. Cold-Start Push-Race nicht behandelt
RLS-Race nach Auth-Restore + visibility-change-listener fehlen → User sieht leere Detail-Pages bei Push.

### 8. Settings-Page als Hub fehlt fast alles
Statistiken, Export, Werkhistorie, Ablaufpläne, Admins, Handover, Files, Role-Permissions, Delete-Account — die Flutter-Settings ist eine deutliche UX-Regression.

### 9. Tenant-spezifische Konfiguration ignoriert
- `tenant.absence_reasons` / `late_reasons` → hartcodiert
- `tenant.shift_excused_as_present` → Feld fehlt komplett im Tenant-Model
- `tenant.additional_fields` → in Export, Filter, View-Optionen ignoriert
- `tenant_role_permissions` → komplett ignoriert (Sicherheit!)

### 10. Force-Unwrap auf `tenant.id!` Pattern wiederholt sich
Trotz früherer Fixes erneut in mehreren neuen Stellen aufgetaucht. Lint-Regel angeraten.

---

## Skills/Agents Update — Empfehlung

Basierend auf den Findings sollten folgende Updates an den Skills/Agents gemacht werden:

### 1. `migration-crawl/SKILL.md` — Page-Mappings aktualisieren
**Lohnt sich:** ✅ Ja (30 min)
- Batch 11 als Standard-Batch aufnehmen mit Mappings für Dashboard, Bulk-Edit, Delete-Account, Files, Role-Permissions, Legal, Login/Legal-Modal, App-Redirect
- Cross-Cutting Services-Check (Push, Tracking, AudioPlayer, Files, Legal, RolePermission) als eigenen Mini-Batch ergänzen

### 2. `flutter-reviewer.md` — Repository-Bypass-Detection
**Lohnt sich:** ✅ Ja (30 min)
- Explizit "supabaseClientProvider direkt in UI/Provider" als Anti-Pattern aufnehmen
- "Force-Unwrap auf tenant.id!" als Anti-Pattern aufnehmen
- "Cross-Tenant-Operation ohne Membership-Validierung" als Anti-Pattern

### 3. `page-crawler.md` — Vergleichs-Tabelle erweitern
**Lohnt sich:** ✅ Ja (30 min)
- Cross-Tenant-Operations als Check-Punkt
- Public-Sharing-Routes als Check-Punkt
- Tracking/Analytics als Check-Punkt
- DSGVO-Features als Check-Punkt

**Andere Skills (`bug-hunt`, `parity-audit`, `flutter-feature` etc.):** kein Update nötig.

---

## Scan-Details

- **Datum:** 2026-06-17
- **Ionic-HEAD:** b3ea25d (commit von 2026-06-17 13:35, "iOS-only FAB für Ablaufplan")
- **Batches gescannt:** 1-11
- **Agents verwendet:** 11× page-crawler (Opus, parallel)
- **Token-Budget:** ~1.5M Tokens

### Vergleich zu altem (stale) Report

| Metrik | Alter Crawl (v3.8.3) | Neuer Crawl (v4.0.5) | Δ |
|--------|---------------------|---------------------|------|
| Findings | 252 | 315 | +63 |
| KRITISCH | 4 | 30 | +26 ⚠️ |
| HOCH | 42 | 101 | +59 |
| Score | 78% | 57% | -21pp |

Der Score-Rückgang ist auf die Major-Version-Sprung des Ionic-Projekts zurückzuführen — viele neue Features wurden noch nicht migriert.

---

## Nächste Schritte

1. **Sprint 0 (DSGVO) sofort starten** — App-Store-Compliance ist nicht verhandelbar
2. **GitHub Issues #178-210 obsolet** — basierten auf altem Crawl, sollten geschlossen oder remapped werden
3. **Neue GitHub Issues anlegen** für KRITISCH + HOCH Findings (~131 Tickets)
4. **Memory aktualisieren:** Status auf "Re-Crawl 2026-06-17 v4.0.5"
5. **Skills-Updates** (3× ~30min) durchführen — verbessert künftige Crawls

**Tipp:** Nutze `/ionic-migrate [feature]` oder `/fix-bug [B*-XXX]` um Findings zu beheben.
