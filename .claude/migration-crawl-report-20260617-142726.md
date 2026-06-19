# Migration Crawl Report
Datum: 2026-03-04
Scope: full (alle 10 Batches)

## Zusammenfassung

| Metrik | Wert |
|--------|------|
| Gescannte Ionic Pages | 34 |
| Gescannte Flutter Pages | 34 |
| Durchschnittlicher Score | **76%** |
| Gesamt-Findings | **190** |
| Duplikate entfernt | 2 |
| False Positives (Flutter-Extras) | 8 |

| Kategorie | KRITISCH | HOCH | MITTEL | NIEDRIG | Gesamt |
|-----------|----------|------|--------|---------|--------|
| Missing Feature | 4 | 25 | 38 | 37 | 104 |
| Bug | 1 | 2 | 9 | 5 | 17 |
| UX Gap | 1 | 6 | 27 | 45 | 79 |
| Service Gap | 0 | 0 | 0 | 0 | 0 |
| **Gesamt** | **6** | **33** | **74** | **87** | **200** |

## Top-5 Action Items

1. **[B9-001]** Instruments Provider umgeht WithTenant Security Pattern — KRITISCH — 1h
2. **[B8-005]** Ablaufplan (Default Plan) fehlt im Attendance Type Editor — KRITISCH — 8h
3. **[B9-002]** Kategorien-Verwaltung für Instrumente fehlt komplett — KRITISCH — 6h
4. **[B4-001]** Realtime-Updates für Songs fehlen — KRITISCH — 3h
5. **[B7-001]** Realtime-Subscription für Pending Players fehlt — KRITISCH — 3h

---

## Priorisierter Task-Katalog

### KRITISCH

#### [B9-001] Instruments Provider umgeht WithTenant Security Pattern
- **Typ:** BUG
- **Ionic:** -
- **Flutter:** instruments_list_page.dart:14-29, :189, :212 — instrumentsListProvider nutzt direkt supabaseClientProvider statt groupRepositoryWithTenantProvider. Auch _showAddDialog und _showEditDialog nutzen groupRepositoryProvider statt groupRepositoryWithTenantProvider.
- **Effort:** 1h
- **Fix:** Lokalen Provider entfernen, stattdessen groupsProvider und groupNotifierProvider aus group_providers.dart nutzen.
- **Status:** [ ] Offen

#### [B9-002] Kategorien-Verwaltung für Instrumente fehlt komplett
- **Typ:** MISSING_FEATURE
- **Ionic:** instrument-list.page.ts:121-210 — Komplettes Kategorien-Management mit CRUD, Modal, Gruppierung nach Kategorie
- **Flutter:** instruments_list_page.dart — Keine Kategorien-UI. Backend-Methoden existieren bereits in GroupRepository und GroupNotifier.
- **Effort:** 6h
- **Fix:** Kategorien-Modal mit Liste, Add/Edit/Delete implementieren. Instrumentenliste nach Kategorie gruppieren.
- **Status:** [ ] Offen

#### [B8-005] Ablaufplan (Default Plan) fehlt im Attendance Type Editor
- **Typ:** MISSING_FEATURE
- **Ionic:** type.page.html:396-481, type.page.ts:267-383 — Felder hinzufügen (Freitext/Werk-Platzhalter), Drag-and-Drop, Dauer, Endzeit-Berechnung
- **Flutter:** attendance_type_edit_page.dart — Keine Ablaufplan-UI, obwohl Model defaultPlan und planningTitle enthält.
- **Effort:** 8h
- **Fix:** Ablaufplan-Section mit ReorderableListView, Add-Dialog für Felder, Zeitberechnung implementieren.
- **Status:** [ ] Offen

#### [B4-001] Realtime-Updates für Songs fehlen
- **Typ:** MISSING_FEATURE
- **Ionic:** songs.page.ts:91-103 — Supabase Realtime-Subscription auf songs-Tabelle
- **Flutter:** songs_list_page.dart — Keine Realtime-Subscription
- **Effort:** 3h
- **Fix:** Supabase Channel auf songs-Tabelle mit tenantId-Filter hinzufügen, bei Änderung songsProvider invalidieren.
- **Status:** [ ] Offen

#### [B7-001] Realtime-Subscription für Pending Players fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** settings.page.ts:149-162 — Realtime auf player-Tabelle, automatische Aktualisierung der Pending-Liste
- **Flutter:** pending_players_page.dart — Keine Realtime, Admin sieht neue Registrierungen erst nach Pull-to-Refresh
- **Effort:** 3h
- **Fix:** Supabase Channel auf player-Tabelle mit Filter status=pending hinzufügen.
- **Status:** [ ] Offen

#### [B7-021] Per-Instanz Notification Toggle fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** notifications.page.html:89-100 — Benachrichtigungen pro Instanz aktivieren/deaktivieren
- **Flutter:** notifications_page.dart — Kein enabled_tenants Feature
- **Effort:** 3h
- **Fix:** Sektion "Instanz-Einstellungen" mit Toggle pro Tenant hinzufügen, enabled_tenants Array verwalten.
- **Status:** [ ] Offen

---

### HOCH

#### [B9-003] Gruppierung nach Kategorie in Instrumentenliste fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** instrument-list.page.ts:38-84 — Sortierung nach Kategorie, sticky Divider mit Count
- **Flutter:** instruments_list_page.dart:83-123 — Keine Kategorie-Gruppierung
- **Effort:** 3h
- **Status:** [ ] Offen

#### [B9-004] Spieler-Anzahl pro Instrument fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** instrument-list.page.html:73 — Badge mit Spieleranzahl, rot wenn 0
- **Flutter:** instruments_list_page.dart:136-178 — Nur Name/Kurzname. getPlayerCountInGroup() existiert im Repository.
- **Effort:** 2h
- **Status:** [ ] Offen

#### [B9-005] Instrument Detail-Felder fehlen (Stimmung, Tonumfang, Notenschlüssel, Synonyme)
- **Typ:** MISSING_FEATURE
- **Ionic:** instrument.page.html:38-87 — Stimmung (C/Es/B/F), Tonumfang, Notenschlüssel (G/F/C), Synonyme mit KI
- **Flutter:** instruments_list_page.dart:247-353 — Edit-Dialog hat nur Name, Kurzname, Notizen. Model hat die Felder bereits.
- **Effort:** 4h
- **Status:** [ ] Offen

#### [B9-012] Kategorie-Zuordnung im Instrument Edit-Dialog fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** instrument.page.html:28-37 — Dropdown zur Kategorie-Zuweisung
- **Flutter:** instruments_list_page.dart:272-350 — Kein Kategorie-Feld
- **Effort:** 2h
- **Status:** [ ] Offen

#### [B9-013] Stimmung-Dropdown fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** instrument.page.html:39-51 — Dropdown C/Es/B/F
- **Flutter:** instruments_list_page.dart:272-350 — Kein Stimmungs-Feld
- **Effort:** 1.5h
- **Status:** [ ] Offen

#### [B9-014] Tonumfang-Feld fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** instrument.page.html:53-61 — Freitext
- **Flutter:** instruments_list_page.dart:272-350 — Fehlt
- **Effort:** 0.5h
- **Status:** [ ] Offen

#### [B9-015] Notenschlüssel-Mehrfachauswahl fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** instrument.page.html:62-74 — G/F/C Mehrfachauswahl
- **Flutter:** instruments_list_page.dart:272-350 — Fehlt
- **Effort:** 1.5h
- **Status:** [ ] Offen

#### [B9-018] Instrumente-Zuordnung im Lehrer-Create/Edit fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** teachers.page.html:41-46 — ion-select multiple für Instrumente
- **Flutter:** teachers_list_page.dart:250-306 — Kein UI-Element für Instrumente-Auswahl
- **Effort:** 3h
- **Status:** [ ] Offen

#### [B9-024] Instrumente-Mehrfachauswahl im Teacher Edit fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** teacher.page.html:18-23 — ion-select multiple
- **Flutter:** teachers_list_page.dart:242-306 — Fehlt
- **Effort:** 3h
- **Status:** [ ] Offen

#### [B8-006] Terminerinnerungen-Konfiguration fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** type.page.html:151-314, type.page.ts:410-482 — Reminder-System mit vordefinierten/benutzerdefinierten Zeiten
- **Flutter:** attendance_type_edit_page.dart — Model hat notification/reminders, aber keine UI
- **Effort:** 6h
- **Status:** [ ] Offen

#### [B8-007] Checkliste (To-Dos) fehlt im Attendance Type Editor
- **Typ:** MISSING_FEATURE
- **Ionic:** type.page.html:483-586, type.page.ts:484-589 — CRUD mit Deadlines und Reorder
- **Flutter:** attendance_type_edit_page.dart — ChecklistItem Model existiert, keine UI
- **Effort:** 6h
- **Status:** [ ] Offen

#### [B8-008] Ganztägig-Option fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** type.page.html:77-88 — allDay Toggle mit durationDays
- **Flutter:** attendance_type_edit_page.dart — Model hat allDay/durationDays, keine UI
- **Effort:** 2h
- **Status:** [ ] Offen

#### [B7-002] Fehlende Accounts anlegen (Batch-Account-Erstellung) fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** settings.page.html:248-253 — Für alle Spieler ohne Account automatisch erstellen
- **Flutter:** settings_page.dart — Kein Menüpunkt. createAccountForPerson() existiert in auth_service.dart.
- **Effort:** 4h
- **Status:** [ ] Offen

#### [B7-003] Instanz löschen fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** settings.page.ts:439-477 — Mit Sicherheitsabfrage (Name muss exakt eingegeben werden)
- **Flutter:** settings_page.dart — Fehlt
- **Effort:** 4h
- **Status:** [ ] Offen

#### [B7-004] Instanz als Favorit setzen fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** settings.page.ts:479-492 — Swipe-Aktion im Instanz-Wechsel
- **Flutter:** settings_page.dart — Fehlt
- **Effort:** 2h
- **Status:** [ ] Offen

#### [B7-013] Registrierungsfelder-Konfiguration fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** general.page.html:110-121 — Multi-Select welche Felder bei Selbst-Registrierung
- **Flutter:** general_settings_page.dart:482-504 — Nur Auto-Genehmigung Toggle, keine Feldauswahl
- **Effort:** 3h
- **Status:** [ ] Offen

#### [B7-014] Feiertage anzeigen Toggle fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** general.page.html:157-172 — showHolidays Toggle
- **Flutter:** general_settings_page.dart:368-383 — Bundesland immer sichtbar, kein Toggle
- **Effort:** 2h
- **Status:** [ ] Offen

#### [B7-022] Realtime für Notification-Config fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** notifications.page.ts:28-37 — Realtime auf notifications-Tabelle
- **Flutter:** notifications_page.dart:30-53 — Config nur einmal geladen, kein Auto-Update nach Telegram-Bot-Verbindung
- **Effort:** 2h
- **Status:** [ ] Offen

#### [B7-023] Duplicate Notifications Pages
- **Typ:** BUG
- **Ionic:** -
- **Flutter:** notifications_page.dart + notification_settings_page.dart — Zwei Pages mit ähnlicher Funktionalität, unterschiedliche Implementierungen
- **Effort:** 2h
- **Fix:** Eine der Pages entfernen, Funktionalität konsolidieren.
- **Status:** [ ] Offen

#### [B6-009] Organisations-Statistiken komplett fehlen
- **Typ:** MISSING_FEATURE
- **Ionic:** stats.page.html:233-290, stats.page.ts:508-563 — Instanzübergreifende Personen-Analysen
- **Flutter:** statistics_page.dart — Fehlt komplett
- **Effort:** 8h
- **Status:** [ ] Offen

#### [B6-014] Provider und Model in History Page-Datei statt separaten Files
- **Typ:** BUG
- **Ionic:** -
- **Flutter:** history_page.dart:13-106 — songHistoryProvider, conductorsProvider, HistoryEntry Model direkt in Page definiert
- **Effort:** 3h
- **Fix:** Provider nach lib/core/providers/, Models nach lib/data/models/ extrahieren.
- **Status:** [ ] Offen

#### [B4-003] FAB ohne Rollen-Check auf Songs-Seite
- **Typ:** BUG
- **Ionic:** songs.page.html:319 — @if (isAdmin)
- **Flutter:** songs_list_page.dart:443 — FAB für alle Rollen sichtbar
- **Effort:** 0.5h
- **Fix:** `floatingActionButton: role.isConductor ? FloatingActionButton(...) : null`
- **Status:** [ ] Offen

#### [B5-006] Aktuelle Werke/Songs-Modal weniger prominent (Single-Tenant)
- **Typ:** MISSING_FEATURE
- **Ionic:** signout.page.html:92-94 — Button in Welcome-Card
- **Flutter:** self_service_overview_page.dart:71-74 — Nur AppBar-Icon, weniger discoverable
- **Effort:** 1h
- **Status:** [ ] Offen

#### [B5-011] Alle Kinder gleichzeitig An-/Abmelden fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** parents.page.html:192-198 — Bulk-Aktion für alle Kinder
- **Flutter:** parents_portal_page.dart:230-309 — Nur individuelle Kind-Aktionen
- **Effort:** 3h
- **Status:** [ ] Offen

#### [B3-011] Account-Erstellung aus Person-Detail fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** person.page.ts:701-714 — Account direkt erstellen
- **Flutter:** account_accordion.dart:112-132 — Nur Info-Hinweis
- **Effort:** 4h
- **Status:** [ ] Offen

#### [B3-012] Passbild-Upload und -Verwaltung fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** person.page.ts:716-779 — Upload, Ersetzen, Entfernen, Fullscreen
- **Flutter:** person_header.dart:38-55 — Nur Anzeige, kein Upload
- **Effort:** 6h
- **Status:** [ ] Offen

#### [B3-013] Person-Transfer/Kopieren aus Detail-Seite fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** person.page.ts:866-964 — In andere Instanz übertragen/kopieren
- **Flutter:** person_detail_page.dart:935-969 — Nur Massen-Handover über Liste
- **Effort:** 3h
- **Status:** [ ] Offen

#### [B3-014] Person entfernen (permanentes Löschen) fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** person.page.ts:892-921 — Entfernen mit Bestätigungsdialog
- **Flutter:** person_detail_page.dart:935-969 — Nur Pausieren/Archivieren
- **Effort:** 2h
- **Status:** [ ] Offen

#### [B2-006] Keine Realtime-Subscription für attendance-Tabelle auf Detail-Page
- **Typ:** MISSING_FEATURE
- **Ionic:** attendance.page.ts:104-108, 153-165 — Bei Löschung User benachrichtigen und Modal schließen
- **Flutter:** attendance_detail_page.dart:210-227 — Nur person_attendances, nicht attendance selbst
- **Effort:** 3h
- **Status:** [ ] Offen

#### [B1-003] Auth-Error-Codes nicht differenziert behandelt
- **Typ:** UX_GAP
- **Ionic:** db.service.ts:872-896 — 8 spezifische Fehlermeldungen
- **Flutter:** login_page.dart:74-78 — Nur generische Exception
- **Effort:** 2h
- **Status:** [ ] Offen

#### [B1-008] Profilbild-Upload fehlt in Tenant-Registrierung
- **Typ:** MISSING_FEATURE
- **Ionic:** tenant-register.page.ts:286-332 — Upload mit Dateigrößen-Check, Vorschau
- **Flutter:** tenant_registration_page.dart — Fehlt
- **Effort:** 4h
- **Status:** [ ] Offen

#### [B1-009] bfecg_church Feld-Typ fehlt
- **Typ:** MISSING_FEATURE
- **Ionic:** tenant-register.page.ts:58-59, 271-280 — Kirchengemeinde-Auswahl mit Custom-Eingabe
- **Flutter:** tenant_registration_page.dart:399-541 — Wird übersprungen
- **Effort:** 3h
- **Status:** [ ] Offen

#### [B1-015] Hauptgruppen-Name Eingabe fehlt bei Tenant-Erstellung
- **Typ:** MISSING_FEATURE
- **Ionic:** register.page.html:101-133 — Dediziertes Feld mit Erklärung
- **Flutter:** tenant_create_page.dart:261-265 — Hartcodierte Standard-Gruppe
- **Effort:** 1.5h
- **Status:** [ ] Offen

---

### MITTEL

#### [B1-001] Demo-Login fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 1h | **Status:** [ ] Offen

#### [B1-007] mounted-Check fehlt in Register-Page
- **Typ:** BUG | **Effort:** 0.5h | **Status:** [ ] Offen

#### [B1-010] Login für existierende User auf Registrierungsseite fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 2h | **Status:** [ ] Offen

#### [B1-011] Keine Prüfung ob User bereits in Tenant registriert
- **Typ:** UX_GAP | **Effort:** 1.5h | **Status:** [ ] Offen

#### [B1-012] Dynamisches Gruppen-Label fehlt (Stimme/Instrument/Gruppe)
- **Typ:** UX_GAP | **Effort:** 0.5h | **Status:** [ ] Offen

#### [B1-013] Memory Leak: TextEditingController in date-Feld
- **Typ:** BUG | **Effort:** 1h | **Status:** [ ] Offen

#### [B1-016] Zusammenfassungs-Ansicht vor Tenant-Erstellung fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 1.5h | **Status:** [ ] Offen

#### [B1-017] Willkommens-Card und Hint-Card fehlen
- **Typ:** MISSING_FEATURE | **Effort:** 1h | **Status:** [ ] Offen

#### [B2-001] Fehlende Realtime für person_attendances auf Listenseite
- **Typ:** MISSING_FEATURE | **Effort:** 2h | **Status:** [ ] Offen

#### [B2-007] Netzwerk-Status-Überwachung fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 3h | **Status:** [ ] Offen

#### [B2-008] Kein automatisches Speichern bei Status-Klick (Click-Modus)
- **Typ:** UX_GAP | **Effort:** 4h | **Status:** [ ] Offen

#### [B3-001] View-Optionen (Spalten-Sichtbarkeit) fehlen
- **Typ:** MISSING_FEATURE | **Effort:** 6h | **Status:** [ ] Offen

#### [B3-002] Anwesenheits-Prozent-Badge fehlt in People-Liste
- **Typ:** MISSING_FEATURE | **Effort:** 3h | **Status:** [ ] Offen

#### [B3-007] Entfernen-Aktion (permanentes Löschen) fehlt in People-Liste
- **Typ:** MISSING_FEATURE | **Effort:** 2h | **Status:** [ ] Offen

#### [B3-015] Personen-Suche bei Namensübereinstimmung fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 4h | **Status:** [ ] Offen

#### [B3-016] E-Mail-Suche in anderen Instanzen fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 3h | **Status:** [ ] Offen

#### [B3-017] Andere-Instanzen-Accordion fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 4h | **Status:** [ ] Offen

#### [B3-018] Anstehende Termine fehlen in Person-Detail
- **Typ:** MISSING_FEATURE | **Effort:** 3h | **Status:** [ ] Offen

#### [B3-019] Historie-Einträge löschen fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 2h | **Status:** [ ] Offen

#### [B3-024] E-Mail-Feld nur read-only in Person-Detail
- **Typ:** BUG | **Effort:** 1.5h | **Status:** [ ] Offen

#### [B3-026] Einteilungs-Filter auf Members-Seite fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 2h | **Status:** [ ] Offen

#### [B4-002] Share-Link auf Songs-Listenseite fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 1h | **Status:** [ ] Offen

#### [B4-007] Smart Print druckt nur erste PDF statt alle Gruppen-PDFs
- **Typ:** UX_GAP | **Effort:** 4h | **Status:** [ ] Offen

#### [B4-008] Druckverhältnis-Presets fehlen bei Smart Print
- **Typ:** UX_GAP | **Effort:** 2h | **Status:** [ ] Offen

#### [B5-001] Statistik-Berechnung ignoriert include_in_average
- **Typ:** BUG | **Effort:** 2h | **Status:** [ ] Offen
- Betrifft auch B5-010 und B5-015 (gleiche Root Cause in self_service_providers.dart + parents_providers.dart)

#### [B5-005] Segment-Control durch PopupMenu ersetzt
- **Typ:** UX_GAP | **Effort:** 1h | **Status:** [ ] Offen

#### [B5-007] PDF-Zusammenführung (printAllCurrentFiles) fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 8h | **Status:** [ ] Offen

#### [B5-008] Noten-Download fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 4h | **Status:** [ ] Offen

#### [B5-012] Aktuelle Werke für Eltern fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 3h | **Status:** [ ] Offen

#### [B6-001] Share-Plan Toggle fehlt auf Planning Page
- **Typ:** MISSING_FEATURE | **Effort:** 1.5h | **Status:** [ ] Offen

#### [B6-006] Beste/Schlechteste Anwesenheit nicht in Statistics UI
- **Typ:** MISSING_FEATURE | **Effort:** 1h | **Status:** [ ] Offen

#### [B6-007] Mitglieder-Übersicht in Statistics fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 1.5h | **Status:** [ ] Offen

#### [B6-008] Termine pro Veranstaltungstyp fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 1h | **Status:** [ ] Offen

#### [B6-012] Multi-Song-Auswahl beim History-Hinzufügen fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 2h | **Status:** [ ] Offen

#### [B7-005] Instanz erstellen im Wechsel-Modal fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 4h | **Status:** [ ] Offen

#### [B7-006] Telegram-Support-Kontakt fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 0.5h | **Status:** [ ] Offen

#### [B7-007] Passbild Upload im Profil fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 4h | **Status:** [ ] Offen

#### [B7-008] Geburtsdatum im Profil fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 2h | **Status:** [ ] Offen

#### [B7-009] Pending-Persons-Badge auf Settings-Seite fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 2h | **Status:** [ ] Offen

#### [B7-010] Pull-to-Refresh auf Settings-Hauptseite fehlt
- **Typ:** UX_GAP | **Effort:** 1h | **Status:** [ ] Offen

#### [B7-016] Evaluate Critical Rules nach Speichern fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 1h | **Status:** [ ] Offen

#### [B7-017] Sanitize Player Additional Fields nach Speichern fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 4h | **Status:** [ ] Offen

#### [B7-018] Extra Field Werte zurücksetzen fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 2h | **Status:** [ ] Offen

#### [B7-019] Browser-Warnung bei Ungespeicherten Änderungen fehlt (PWA)
- **Typ:** UX_GAP | **Effort:** 1h | **Status:** [ ] Offen

#### [B7-024] Benutzer-ID Anzeige für Telegram fehlt
- **Typ:** UX_GAP | **Effort:** 0.5h | **Status:** [ ] Offen

#### [B7-025] Inkonsistentes Sofortiges vs. manuelles Speichern bei Notifications
- **Typ:** UX_GAP | **Effort:** 1h | **Status:** [ ] Offen

#### [B8-003] Reorder umgeht Repository (Attendance Types)
- **Typ:** BUG | **Effort:** 1h | **Status:** [ ] Offen

#### [B8-004] Erstellen umgeht Repository (Attendance Types)
- **Typ:** BUG | **Effort:** 1h | **Status:** [ ] Offen

#### [B8-009] Relevante Gruppen Filter fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 3h | **Status:** [ ] Offen

#### [B8-010] Zusatzfeld-Filter fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 3h | **Status:** [ ] Offen

#### [B8-011] Edit-Page umgeht Repository (Attendance Type Edit)
- **Typ:** BUG | **Effort:** 1h | **Status:** [ ] Offen

#### [B8-012] Lokaler _attendanceTypeByIdProvider statt globaler
- **Typ:** BUG | **Effort:** 0.5h | **Status:** [ ] Offen

#### [B8-013] Unsaved Changes Dialog hat nur 2 statt 3 Optionen
- **Typ:** UX_GAP | **Effort:** 1h | **Status:** [ ] Offen

#### [B8-018] updateShiftAttendancesInTenant fehlt beim Copy
- **Typ:** MISSING_FEATURE | **Effort:** 4h | **Status:** [ ] Offen

#### [B9-006] KI-Synonym-Generierung fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 4h | **Status:** [ ] Offen

#### [B9-007] Stimmung/Notenschlüssel in Listendarstellung fehlen
- **Typ:** MISSING_FEATURE | **Effort:** 1h | **Status:** [ ] Offen

#### [B9-008] Instrument-Anzahl im Titel fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 0.5h | **Status:** [ ] Offen

#### [B9-009] Admin-Rollencheck für FAB und Edit fehlt (Instruments)
- **Typ:** UX_GAP | **Effort:** 1.5h | **Status:** [ ] Offen

#### [B9-010] Kontextabhängige Anzeige basierend auf Tenant-Typ fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 1h | **Status:** [ ] Offen

#### [B9-011] Löschen prüft nicht ob Spieler zugewiesen sind
- **Typ:** BUG | **Effort:** 1h | **Status:** [ ] Offen

#### [B9-016] Synonyme-Feld mit KI-Button fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 3h | **Status:** [ ] Offen

#### [B9-019] Instrumentenamen in Teachers-Listenansicht fehlen
- **Typ:** MISSING_FEATURE | **Effort:** 2h | **Status:** [ ] Offen

#### [B9-020] Spieler-Anzahl pro Lehrer fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 1.5h | **Status:** [ ] Offen

#### [B9-021] Admin-Rollencheck für Teachers FAB fehlt
- **Typ:** UX_GAP | **Effort:** 1h | **Status:** [ ] Offen

#### [B9-022] Error State nicht benutzerfreundlich (Teachers)
- **Typ:** UX_GAP | **Effort:** 0.5h | **Status:** [ ] Offen

#### [B9-025] Zugewiesene Spieler-Liste im Teacher-Detail fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 3h | **Status:** [ ] Offen

#### [B10-003] Rich-Text-Editor (Quill) fehlt für Meeting-Notizen
- **Typ:** MISSING_FEATURE | **Effort:** 8h | **Status:** [ ] Offen

#### [B10-006] Altersfilter für Handover fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 4h | **Status:** [ ] Offen

#### [B10-007] Gruppenfilter für Handover fehlt
- **Typ:** MISSING_FEATURE | **Effort:** 2h | **Status:** [ ] Offen

#### [B10-010] Kein Bestätigungsdialog vor Transfer
- **Typ:** UX_GAP | **Effort:** 1h | **Status:** [ ] Offen

#### [B10-016] N+1 Query-Problem bei Voice-Leader Abwesenheiten
- **Typ:** BUG | **Effort:** 2h | **Status:** [ ] Offen

---

### NIEDRIG

(87 Findings — hier nur die wichtigsten, vollständige Details in den Batch-Outputs)

#### Quick Wins (< 1h)
- [B1-002] Versions-Anzeige auf Login-Seite — 0.5h
- [B1-012] Dynamisches Gruppen-Label — 0.5h
- [B4-006] Link-Validierung beim Song-Erstellen — 0.5h
- [B5-003] Min-5-Zeichen Validierung für Sonstiger Grund — 0.5h
- [B6-010] Farbcodierte Durchschnitts-Anwesenheit — 0.5h
- [B7-020] Neuladen-Aufforderung nach General Settings Speichern — 0.5h
- [B8-001] Info-Card auf Types-Seite — 0.5h
- [B9-008] Instrument-Anzahl im Titel — 0.5h
- [B9-023] Strengere Validierung bei Lehrer-Erstellung — 0.5h
- [B10-014] "Keine Kontaktdaten" Anzeige — 0.5h
- [B10-017] Absences limitiert ohne "+X weitere" Hinweis — 0.5h

#### Weitere NIEDRIG-Findings
- [B1-006] Pre-fill E-Mail bei Register — 0.5h
- [B1-014] Success-Dialog statt Toast nach Registrierung — 1h
- [B1-018] Dynamische Platzhalter bei Tenant-Erstellung — 0.5h
- [B1-019] Max-Length/Counter für Namensfelder — 0.5h
- [B1-020] maingroup statt reguläre Gruppe erstellen — 1h
- [B2-002] Kalender ohne AttendanceType-Farben — 2h
- [B2-003] Feiertage/Ferien im Kalender fehlen — 3h
- [B2-004] Viewer-Rolle kein "X von Y anwesend" Text — 1h
- [B2-009] Visibility-Change-Handler fehlt — 2h
- [B2-010] Missing-Groups bei Werken fehlt — 3h
- [B3-003] Filter nach Zusatzfeldern — 4h
- [B3-004] Filter nach verknüpften Instanzen — 4h
- [B3-005] Sortierung nach Anwesenheit — 2h
- [B3-006] Filter Ohne Account/Lehrer — 1h
- [B3-008] Filter-Persistierung — 2h
- [B3-009] Notizen-Badge in Liste — 0.5h
- [B3-010] Archivieren mit Datum/Notiz-Dialog — 1.5h
- [B3-020] Stimmführer-Rolle-Zuweisung — 2h
- [B3-021] Account-Erstellung bei E-Mail-Änderung — 2h
- [B3-022] Approve/Decline Mode — 4h
- [B3-023] Notiz-Änderungshistorie — 1h
- [B3-025] Stimmumfang/Instrumente-Felder (Chor) — 1h
- [B3-027] Skeleton Loading statt Spinner (Members) — 0.5h
- [B3-028] Tenant-Wechsel Einteilungs-Filter — 0.5h
- [B4-004] Song-Viewer für externe Besucher — 8h
- [B4-005] Duplicate-Number Validierung — 1h
- [B4-009] Datei-Größenvalidierung beim Upload — 0.5h
- [B4-010] Warnung für Nicht-PDF Liedtext — 1h
- [B4-011] Upload-Info Details — 0.5h
- [B4-012] Freitext-Note für Sonstige Kategorie — 1h
- [B4-013] Datei-Drucken (Browser-API) — 1h
- [B5-002] Abmeldegründe-Benennung angleichen — 0.5h
- [B5-004] Toast-Nachrichten persönlicher — 0.5h
- [B5-009] Noten-Drucken fehlt — 2h
- [B5-013] Legende weniger Status-Varianten — 0.5h
- [B5-014] Anmelden mit Notiz für Eltern — 1h
- [B6-002] Anwesenheitsnotizen in Planning — 0.5h
- [B6-003] Missing Groups in Planning — 2h
- [B6-004] Registerprobenplan Telegram-Versand — 2h
- [B6-005] Proben-Count pro Werk in Planning — 2h
- [B6-011] Datumsbereich-Default (Saisonstart vs. 180 Tage) — 1h
- [B6-013] Proben-Count pro Werk in History — 2h
- [B6-015] Accordion-Gruppierung in History — 1h
- [B6-016] Haptics-Feedback bei Löschung — 0.5h
- [B6-017] Custom-Freitext-Feld im Export — 1h
- [B6-018] Testergebnis-Feld im Export — 0.5h
- [B6-019] PDF-Export 8 Termine limitiert ohne Hinweis — 0.5h
- [B6-020] Additional_fields des Tenants im Export — 2h
- [B7-011] Personenübergabe in Settings — 8h
- [B7-012] Gemeinden-Verwaltung (Beta) — 4h
- [B8-002] Erstellen öffnet nur Dialog statt Modal — 2h
- [B8-014] beforeunload Warnung (PWA) — 1h
- [B8-015] Speichern-Button Position — 0.5h
- [B8-016] Modal vs Dialog (Shifts) — 0.5h
- [B8-019] Segmente inline vs Dialog — 0h
- [B8-020] Warning-Card bei Usage fehlt — 0.5h
- [B8-021] isUsed-Check für ShiftInstance-Bearbeitung — 1h
- [B8-022] Copy Sheet umgeht Repository — 2h
- [B9-017] Dialog statt Sheet/Modal (Instruments) — 2h
- [B9-026] Dialog statt Modal (Teachers) — 2h
- [B10-001] Swipe-to-Delete bei Meetings — 1h
- [B10-002] Dialog statt Sheet (Meeting erstellen) — 1h
- [B10-004] Chips statt Dropdown (Meeting Attendees) — 2h
- [B10-005] Skeleton passt nicht zum Content — 0.5h
- [B10-008] "Alle auswählen" Button — 1h
- [B10-009] Hauptgruppe ein-/ausblenden Toggle — 2h
- [B10-011] 2 Pages vs 1 Sheet (Design-Entscheid) — 0h
- [B10-012] Kein Handover-Zugang über Settings — 0h
- [B10-013] Einteilungs-Badge (Voice Leader) — 2h
- [B10-015] Loading Skeleton statt Spinner — 0.5h

---

## Page-für-Page Analyse

### Login Page (Score: 78%)
**Ionic:** login.page.ts | **Flutter:** login_page.dart

Implementiert:
- [x] E-Mail/Passwort Login
- [x] Show/Hide Passwort Toggle
- [x] Error-Anzeige
- [x] Navigation zu Register/Forgot Password
- [x] Auto-Navigation zu gespeichertem Tenant (Extra)

Findings:
- [ ] [B1-001] Demo-Login fehlt (MITTEL)
- [ ] [B1-002] Versions-Anzeige fehlt (NIEDRIG)
- [ ] [B1-003] Auth-Error-Codes nicht differenziert (HOCH)

---

### Register Page (Score: 90%)
**Ionic:** login.page.ts (Alert) | **Flutter:** register_page.dart (eigene Seite)

Implementiert:
- [x] E-Mail/Passwort/Bestätigung
- [x] Passwort-Mindestlänge (8 Zeichen, besser als Ionic)
- [x] Success-Screen mit E-Mail-Bestätigung
- [x] Dedizierte Seite statt Alert (Flutter-Extra)

Findings:
- [ ] [B1-006] Pre-fill E-Mail fehlt (NIEDRIG)
- [ ] [B1-007] mounted-Check fehlt (MITTEL)

---

### Tenant Registration Page (Score: 72%)
**Ionic:** tenant-register.page.ts | **Flutter:** tenant_registration_page.dart

Implementiert:
- [x] Account-Erstellung + Persönliche Daten
- [x] Gruppen-Auswahl + Dynamische Additional Fields
- [x] Auto-Approve vs. Pending Handling
- [x] Provider-basiertes Laden

Findings:
- [ ] [B1-008] Profilbild-Upload fehlt (HOCH)
- [ ] [B1-009] bfecg_church Feld fehlt (HOCH)
- [ ] [B1-010] Login für existierende User fehlt (MITTEL)
- [ ] [B1-011] Keine vorab-Prüfung auf bestehende Registrierung (MITTEL)
- [ ] [B1-013] Memory Leak TextEditingController (MITTEL)
- [ ] [B1-014] Nur Toast statt Dialog nach Erfolg (NIEDRIG)

---

### Tenant Create Page (Score: 75%)
**Ionic:** register.page.ts | **Flutter:** tenant_create_page.dart

Implementiert:
- [x] Gruppentyp-Auswahl (Orchestra/Choir/General)
- [x] Kurzname/Vollname
- [x] Auto-Admin-Rolle

Findings:
- [ ] [B1-015] Hauptgruppen-Name Eingabe fehlt (HOCH)
- [ ] [B1-016] Zusammenfassungs-Ansicht fehlt (MITTEL)
- [ ] [B1-017] Willkommens-Card fehlt (MITTEL)
- [ ] [B1-020] maingroup nicht korrekt erstellt (NIEDRIG)

---

### Attendance List (Score: 85%)
**Ionic:** att-list.page.ts | **Flutter:** attendance_list_page.dart

Implementiert:
- [x] Kategorisierte Liste (Aktuell/Anstehend/Vergangen)
- [x] Realtime für attendance-Tabelle
- [x] Kalender-Ansicht (Flutter-Extra)
- [x] Pull-to-Refresh, Swipe-to-Delete
- [x] Prozent-Badge mit Farbkodierung

Findings:
- [ ] [B2-001] Realtime für person_attendances fehlt (MITTEL)
- [ ] [B2-002] Kalender ohne Type-Farben (NIEDRIG)
- [ ] [B2-003] Feiertage im Kalender fehlen (NIEDRIG)

---

### Attendance Detail (Score: 90%)
**Ionic:** attendance.page.ts | **Flutter:** attendance_detail_page.dart

Implementiert:
- [x] Status ändern (Click/Select-Modus)
- [x] Realtime für person_attendances
- [x] Alle Accordions (Info, Checklist, Songs, Plan)
- [x] Foto-Upload, Excel-Export, Telegram
- [x] Bottom-StatusBar (Flutter-Extra)

Findings:
- [ ] [B2-006] Keine Realtime für attendance-Löschung (HOCH)
- [ ] [B2-007] Netzwerk-Überwachung fehlt (MITTEL)
- [ ] [B2-008] Batch-Save statt Sofort-Save (MITTEL)

---

### People List (Score: 72%)
**Ionic:** list.page.ts | **Flutter:** people_list_page.dart

Implementiert:
- [x] Gruppierung, Suche, Filter, Sortierung
- [x] Swipe-Actions (Pausieren/Archivieren)
- [x] Realtime-Updates
- [x] Selection-Mode + Handover (Flutter-Extra)

Findings:
- [ ] [B3-001] View-Optionen fehlen (MITTEL)
- [ ] [B3-002] Anwesenheits-Badge fehlt (MITTEL)
- [ ] [B3-007] Permanentes Löschen fehlt (MITTEL)
- [ ] 11 weitere NIEDRIG-Findings

---

### Person Detail (Score: 75%)
**Ionic:** person.page.ts | **Flutter:** person_detail_page.dart

Implementiert:
- [x] Inline-Editing mit Draft-State
- [x] Alle Accordions (Allgemein, Problemfall, Account, Historie)
- [x] Schichtplan, Eltern, Lehrer, Zusatzfelder
- [x] Hero-Animation Avatar (Flutter-Extra)

Findings:
- [ ] [B3-011] Account-Erstellung fehlt (HOCH)
- [ ] [B3-012] Passbild-Upload fehlt (HOCH)
- [ ] [B3-013] Transfer/Kopieren fehlt (HOCH)
- [ ] [B3-014] Permanentes Löschen fehlt (HOCH)
- [ ] 11 weitere MITTEL/NIEDRIG-Findings

---

### Members Page (Score: 88%)
**Ionic:** members.page.ts | **Flutter:** members_page.dart

Implementiert:
- [x] Gruppierte Liste mit Stimmführer-Badge
- [x] Suche, Pull-to-Refresh

Findings:
- [ ] [B3-026] Einteilungs-Filter fehlt (MITTEL)

---

### Songs List (Score: 87%)
**Ionic:** songs.page.ts | **Flutter:** songs_list_page.dart

Implementiert:
- [x] Umfangreiche Filter (Kategorie, Instrument, Solo, Schwierigkeit)
- [x] Suche, Sortierung, View-Options
- [x] Gruppenverzeichnis, Aktuelle Werke
- [x] Active Filter Chips (Flutter-Extra)

Findings:
- [ ] [B4-001] Realtime fehlt (KRITISCH)
- [ ] [B4-003] FAB ohne Rollen-Check (HOCH)

---

### Song Detail (Score: 92%)
**Ionic:** song.page.ts | **Flutter:** song_detail_page.dart

Implementiert:
- [x] Inline-Editing, Datei-Management
- [x] PDF-Viewer, Image-Viewer (Flutter-Extra)
- [x] Smart Print, Telegram, ZIP, Copy-to-Tenant
- [x] Share-Link, Kategorie-Management

Findings:
- [ ] [B4-007] Smart Print nur erste PDF (MITTEL)
- [ ] [B4-008] Druckverhältnis-Presets fehlen (MITTEL)

---

### Self-Service Overview (Score: 88%)
**Ionic:** overview.page.ts + signout.page.ts | **Flutter:** self_service_overview_page.dart

Implementiert:
- [x] Cross-Tenant Termine, Statistik
- [x] Anmelden/Abmelden/Verspätung
- [x] Legende, Ablaufplan, Deadline
- [x] Applicant-View

Findings:
- [ ] [B5-001] include_in_average ignoriert (MITTEL/BUG)
- [ ] [B5-006] Songs weniger prominent (HOCH)
- [ ] [B5-007] PDF-Zusammenführung fehlt (MITTEL)

---

### Parents Portal (Score: 82%)
**Ionic:** parents.page.ts | **Flutter:** parents_portal_page.dart

Implementiert:
- [x] Kinder laden, Statistiken pro Kind
- [x] An-/Abmelden pro Kind
- [x] Ablaufplan, Deadline, Legende

Findings:
- [ ] [B5-011] Alle Kinder gleichzeitig An-/Abmelden fehlt (HOCH)
- [ ] [B5-012] Aktuelle Werke für Eltern fehlt (MITTEL)

---

### Planning Page (Score: 85%)
**Ionic:** planning.page.ts | **Flutter:** planning_page.dart

Implementiert:
- [x] Ablaufplan erstellen/bearbeiten
- [x] Drag-and-Drop, Auto-Save
- [x] PDF Export, Telegram, Registerprobenplan

Findings:
- [ ] [B6-001] Share-Plan Toggle fehlt (MITTEL)
- [ ] [B6-003] Missing Groups fehlt (NIEDRIG)

---

### Statistics Page (Score: 78%)
**Ionic:** stats.page.ts | **Flutter:** statistics_page.dart

Implementiert:
- [x] Alle 7 Charts (fl_chart)
- [x] Zeitraum-Filter, Pull-to-Refresh

Findings:
- [ ] [B6-009] Organisations-Statistiken fehlen (HOCH)
- [ ] [B6-006] Best/Worst nicht in UI (MITTEL)
- [ ] [B6-007] Mitglieder-Übersicht fehlt (MITTEL)

---

### History Page (Score: 75%)
**Ionic:** history.page.ts | **Flutter:** history_page.dart

Implementiert:
- [x] Werke-Liste gruppiert nach Datum
- [x] Suche, Hinzufügen, Löschen

Findings:
- [ ] [B6-014] Provider/Model in Page-Datei (HOCH/BUG)
- [ ] [B6-012] Multi-Song-Auswahl fehlt (MITTEL)

---

### Export Page (Score: 87%)
**Ionic:** export.page.ts | **Flutter:** export_page.dart

Implementiert:
- [x] PDF/Excel, Spieler/Anwesenheit
- [x] Felder-Auswahl mit Reorder
- [x] ExportService als separate Klasse

Findings:
- [ ] [B6-017] Custom-Freitext-Feld fehlt (NIEDRIG)
- [ ] [B6-020] Tenant additional_fields fehlen (NIEDRIG)

---

### Settings Page (Score: 72%)
**Ionic:** settings.page.ts | **Flutter:** settings_page.dart

Implementiert:
- [x] Rollenbasiertes Menü
- [x] Profil, Feedback, Version, Logout
- [x] Ausgelagerte Sub-Pages

Findings:
- [ ] [B7-001] Realtime für Pending Players fehlt (KRITISCH)
- [ ] [B7-002] Batch-Account-Erstellung fehlt (HOCH)
- [ ] [B7-003] Instanz löschen fehlt (HOCH)
- [ ] [B7-004] Instanz-Favoriten fehlt (HOCH)

---

### General Settings (Score: 82%)
**Ionic:** general.page.ts | **Flutter:** general_settings_page.dart

Implementiert:
- [x] Grunddaten, Saison, Probenzeiten, Feiertage
- [x] Feature-Toggles, Registrierung, Zusatzfelder
- [x] Problemfall-Regeln, Organisation

Findings:
- [ ] [B7-013] Registrierungsfelder-Konfiguration fehlt (HOCH)
- [ ] [B7-014] Feiertage-Toggle fehlt (HOCH)
- [ ] [B7-017] Sanitize Additional Fields fehlt (MITTEL)

---

### Notifications (Score: 75%)
**Ionic:** notifications.page.ts | **Flutter:** notifications_page.dart + notification_settings_page.dart

Implementiert:
- [x] Telegram-Verbindung, Kategorie-Toggles

Findings:
- [ ] [B7-021] Per-Instanz Toggle fehlt (KRITISCH)
- [ ] [B7-022] Realtime fehlt (HOCH)
- [ ] [B7-023] Duplicate Pages (HOCH/BUG)

---

### Attendance Types List (Score: 88%)
**Ionic:** types.page.ts | **Flutter:** attendance_types_page.dart

Implementiert:
- [x] Liste, Reorder, Erstellen

Findings:
- [ ] [B8-003] Reorder umgeht Repository (MITTEL/BUG)
- [ ] [B8-004] Erstellen umgeht Repository (MITTEL/BUG)

---

### Attendance Type Edit (Score: 55%)
**Ionic:** type.page.ts | **Flutter:** attendance_type_edit_page.dart

Implementiert:
- [x] Name, Farbe, Zeiten, Status, Toggles
- [x] Unsaved Changes Detection

Findings:
- [ ] [B8-005] Ablaufplan fehlt (KRITISCH)
- [ ] [B8-006] Terminerinnerungen fehlt (HOCH)
- [ ] [B8-007] Checkliste fehlt (HOCH)
- [ ] [B8-008] Ganztägig fehlt (HOCH)
- [ ] [B8-011] Edit umgeht Repository (MITTEL/BUG)

---

### Shifts List (Score: 92%)
**Ionic:** shifts.page.ts | **Flutter:** shifts_list_page.dart

Implementiert:
- [x] Alle Features + bessere List-Tiles (Flutter-Extra)

Findings: Nur NIEDRIG (UX-Kosmetik)

---

### Shift Detail (Score: 85%)
**Ionic:** shift.page.ts | **Flutter:** shift_detail_page.dart

Implementiert:
- [x] CRUD, Segmente, ShiftInstances
- [x] Copy-to-Tenant, Vorschau

Findings:
- [ ] [B8-018] updateShiftAttendances fehlt (MITTEL)

---

### Instruments List (Score: 52%)
**Ionic:** instrument-list.page.ts | **Flutter:** instruments_list_page.dart

Implementiert:
- [x] CRUD, Loading/Error/Empty States

Findings:
- [ ] [B9-001] Provider umgeht WithTenant (KRITISCH)
- [ ] [B9-002] Kategorien fehlen (KRITISCH)
- [ ] [B9-003] Gruppierung fehlt (HOCH)
- [ ] [B9-004] Spieler-Anzahl fehlt (HOCH)
- [ ] [B9-009] Rollencheck fehlt (MITTEL)

---

### Instrument Detail (Score: 35%)
**Ionic:** instrument.page.ts | **Flutter:** _InstrumentEditDialog in instruments_list_page.dart

Implementiert:
- [x] Name, Löschen

Findings:
- [ ] [B9-005] Stimmung/Tonumfang/Notenschlüssel/Synonyme fehlen (HOCH)
- [ ] [B9-012] Kategorie-Zuordnung fehlt (HOCH)
- [ ] [B9-013-015] Alle Detail-Felder fehlen (HOCH)

---

### Teachers List (Score: 72%)
**Ionic:** teachers.page.ts | **Flutter:** teachers_list_page.dart

Implementiert:
- [x] CRUD, Privatlehrer-Toggle
- [x] Swipe-to-Delete (Flutter-Extra)

Findings:
- [ ] [B9-018] Instrumente-Zuordnung fehlt (HOCH)
- [ ] [B9-019] Instrumentenamen in Liste fehlen (MITTEL)
- [ ] [B9-020] Spieler-Anzahl fehlt (MITTEL)

---

### Teacher Detail (Score: 55%)
**Ionic:** teacher.page.ts | **Flutter:** _TeacherEditDialog in teachers_list_page.dart

Implementiert:
- [x] Name, Kontakt, Notizen, Privatlehrer

Findings:
- [ ] [B9-024] Instrumente-Mehrfachauswahl fehlt (HOCH)
- [ ] [B9-025] Spieler-Liste fehlt (MITTEL)

---

### Meetings List (Score: 90%)
**Ionic:** meeting-list.page.ts | **Flutter:** meetings_list_page.dart

Implementiert:
- [x] Alle Features + Rollen-Check (Flutter-Extra)

Findings: Nur NIEDRIG

---

### Meeting Detail (Score: 82%)
**Ionic:** meeting.page.ts | **Flutter:** meeting_detail_page.dart

Implementiert:
- [x] Attendees, Notizen, View/Edit Mode

Findings:
- [ ] [B10-003] Rich-Text-Editor fehlt (MITTEL)

---

### Handover (Score: 78%)
**Ionic:** handover.page.ts + handover-detail.page.ts | **Flutter:** handover_sheet.dart

Implementiert:
- [x] Transfer/Kopieren, Gruppen-Mapping
- [x] Duplikat-Erkennung, Progress
- [x] Berechtigungsprüfung (Flutter-Extra)

Findings:
- [ ] [B10-006] Altersfilter fehlt (MITTEL)
- [ ] [B10-007] Gruppenfilter fehlt (MITTEL)
- [ ] [B10-010] Bestätigungsdialog fehlt (MITTEL)

---

### Voice Leader (Score: 85%)
**Ionic:** voice-leader.page.ts | **Flutter:** voice_leader_page.dart

Implementiert:
- [x] Gruppenmitglieder, Kontakt, Abwesenheiten

Findings:
- [ ] [B10-016] N+1 Query-Problem (MITTEL/BUG)
- [ ] [B10-013] Einteilungs-Badge fehlt (NIEDRIG)

---

## Scan-Details

- **Datum:** 2026-03-04
- **Batches gescannt:** 1-10 (vollständig)
- **Agents verwendet:** 10x page-crawler (parallel)
- **Duplikate entfernt:** 2 (B5-010, B5-015 → merged in B5-001)
- **False Positives entfernt:** 8 (Flutter-Extras: B1-004, B1-005, B2-005, B2-011, B2-012, B2-013, B7-015, B8-017)

## Nächste Schritte

1. Kritische Security-Findings sofort fixen: B9-001 (1h) — Provider umgeht WithTenant
2. Kritische Feature-Gaps mit `/ionic-migrate` beheben: B8-005, B9-002, B7-021
3. Realtime-Gaps schließen: B4-001, B7-001, B7-022, B2-001, B2-006
4. Instruments & Teachers Page komplett überarbeiten (niedrigster Score: 54%)
5. Attendance Type Edit vervollständigen (Score: 55%)
6. Nach Fixes erneut `/migration-crawl` laufen lassen für Progress-Tracking
