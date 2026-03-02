# Bug Report - Attendix People Tab
Generiert: 2026-03-02
Scope: People/Persons Tab (lib/features/people/, player_repository, player_providers)

## Zusammenfassung

| Kategorie | KRITISCH | HOCH | MITTEL | NIEDRIG | Gesamt |
|-----------|----------|------|--------|---------|--------|
| Security | 0 | 2 | 3 | 1 | 6 |
| Business-Logik | 3 | 3 | 4 | 4 | 14 |
| Funktional | 0 | 3 | 5 | 5 | 13 |
| Runtime | 3 | 4 | 1 | 0 | 8 |
| **Gesamt** | **6** | **12** | **13** | **10** | **41** |

## Handlungsempfehlungen

1. 🔴 **Sofort:** 6 kritische Bugs fixen (Runtime Force-Unwraps, Berechtigungsprüfungen)
2. 🟠 **Diese Woche:** 12 hohe Bugs fixen (Type Casts, Validierungen, Race Conditions)
3. 🟡 **Backlog:** 23 mittlere/niedrige Bugs

---

## KRITISCH

### RT-001: Force Unwrap auf tenant.id! ohne null-Check
- **Kategorie:** Runtime
- **Datei:** `lib/features/people/presentation/pages/people_list_page.dart:38`
- **Problem:** `tenant.id!` wird force-unwrapped ohne vorherigen null-Check
- **Fix:** `if (tenant?.id == null) return [];` vor dem Zugriff
- **Status:** [ ] Offen

### RT-002: Force Unwrap auf criticalRules! ohne null-Check
- **Kategorie:** Runtime
- **Datei:** `lib/features/people/presentation/pages/person_detail_page.dart:61`
- **Problem:** `tenant!.criticalRules!` doppeltes Force-Unwrap
- **Fix:** Vollständigen null-Check hinzufügen
- **Status:** [ ] Offen

### RT-003: Force Unwrap auf tenant.id! in _unlinkAccount
- **Kategorie:** Runtime
- **Datei:** `lib/features/people/presentation/pages/person_detail_page.dart:1039`
- **Problem:** Force-Unwrap nach async-Operation, tenant könnte sich geändert haben
- **Fix:** Lokale Variable vor async-Operation speichern
- **Status:** [ ] Offen

### BL-001: Fehlende Rollen-Berechtigungsprüfung in Slide-Aktionen
- **Kategorie:** Business-Logik
- **Datei:** `lib/features/people/presentation/pages/people_list_page.dart:744-862`
- **Problem:** `_pausePerson()`, `_unpausePerson()`, `_archivePerson()` prüfen nicht `canEdit`
- **Fix:** `if (!currentRole.canEdit) return;` am Anfang jeder Methode
- **Status:** [ ] Offen

### BL-002: Handover-Berechtigung wird erst nach Start geprüft
- **Kategorie:** Business-Logik
- **Datei:** `lib/features/people/presentation/widgets/handover_sheet.dart:590-603`
- **Problem:** Berechtigungsprüfung erst nach Klick auf "Übertragen"
- **Fix:** Berechtigung beim Auswählen der Ziel-Instanz prüfen
- **Status:** [ ] Offen

### BL-003: Viewer-Rolle sieht Aktionen die sie nicht ausführen kann
- **Kategorie:** Business-Logik
- **Datei:** `lib/features/people/presentation/pages/people_list_page.dart`
- **Problem:** Slide-Aktionen werden auch für Viewer angezeigt
- **Fix:** `endActionPane: canEdit ? ActionPane(...) : null`
- **Status:** [ ] Offen

---

## HOCH

### RT-005: Unsafe Type Cast in historie_accordion
- **Kategorie:** Runtime
- **Datei:** `lib/features/people/presentation/widgets/person_detail/historie_accordion.dart:99-100`
- **Problem:** `stats['percentage'] as int` ohne null-Coalescing
- **Fix:** `stats['percentage'] as int? ?? 0`
- **Status:** [ ] Offen

### RT-006: Late Variables ohne Initialization-Garantie
- **Kategorie:** Runtime
- **Datei:** `lib/features/people/presentation/pages/person_detail_page.dart:280-294`
- **Problem:** Mehrere `late` Variablen können LateInitializationError verursachen
- **Fix:** Nullable Typ mit initialer Zuweisung verwenden
- **Status:** [ ] Offen

### RT-007: Force Unwrap auf Entity IDs in Selection
- **Kategorie:** Runtime
- **Datei:** `lib/features/people/presentation/widgets/person_detail/allgemein_accordion.dart:388,433,555`
- **Problem:** `.map((t) => SelectionItem(value: t.id!, ...))` ohne null-Filter
- **Fix:** `.where((t) => t.id != null)` vor dem Map
- **Status:** [ ] Offen

### RT-004: Type Cast auf RoundedRectangleBorder
- **Kategorie:** Runtime
- **Datei:** `lib/features/people/presentation/pages/people_list_page.dart:889`
- **Problem:** Cast könnte fehlschlagen bei anderem Theme
- **Status:** [x] Bereits gefixt mit is-Check

### SEC-001: Handover - Fehlende Autorisierungsprüfung im Repository
- **Kategorie:** Security
- **Datei:** `lib/data/repositories/player_repository.dart:866-962`
- **Problem:** Repository prüft nicht Schreibrechte im Ziel-Tenant
- **Fix:** Autorisierungsprüfung im Repository implementieren
- **Status:** [ ] Offen

### SEC-002: Fehlerdetails in UI angezeigt
- **Kategorie:** Security
- **Datei:** Mehrere (person_detail_page, person_create_page, people_list_page, handover_sheet)
- **Problem:** Exception-Details `$e` werden dem User angezeigt
- **Fix:** Generische Fehlermeldungen, Details nur in Debug-Mode
- **Status:** [ ] Offen

### FN-001: RefreshIndicator ohne await
- **Kategorie:** Funktional
- **Datei:** `lib/features/people/presentation/pages/people_list_page.dart:413-417`
- **Problem:** `onRefresh` ohne await auf Provider-Invalidierung
- **Fix:** `await ref.read(realtimePlayersProvider.future)` hinzufügen
- **Status:** [ ] Offen

### FN-003: Fehlende Validierung bei teacher-Dropdown
- **Kategorie:** Funktional
- **Datei:** `lib/features/people/presentation/widgets/person_detail/allgemein_accordion.dart:361`
- **Problem:** `hasTeacher=true` ohne Lehrer-Auswahl möglich
- **Fix:** Validierung in `_saveChanges()` hinzufügen
- **Status:** [ ] Offen

### BL-004: Keine Duplikat-Prüfung beim Erstellen
- **Kategorie:** Business-Logik
- **Datei:** `lib/features/people/presentation/pages/person_create_page.dart:366-411`
- **Problem:** Keine Prüfung auf existierende E-Mail
- **Fix:** Existenzprüfung vor Insert
- **Status:** [ ] Offen

### BL-005: Race Condition bei Handover
- **Kategorie:** Business-Logik
- **Datei:** `lib/data/repositories/player_repository.dart:866-962`
- **Problem:** Mehrere Operationen ohne Transaktion
- **Fix:** Supabase RPC-Funktion oder Rollback-Logik
- **Status:** [ ] Offen

### BL-006: Pausierung entfernt aus Terminen ohne Rückgängig
- **Kategorie:** Business-Logik
- **Datei:** `lib/data/repositories/player_repository.dart:361-365`
- **Problem:** Attendance-Einträge werden bei Pause gelöscht
- **Status:** [x] Teilweise implementiert (addToUpcoming bei unpause)

---

## MITTEL

### SEC-003: Debug-Prints mit sensiblen Daten
- **Kategorie:** Security
- **Datei:** `lib/features/people/presentation/pages/people_list_page.dart:55-56,64-65`
- **Problem:** JSON-Daten mit PII werden geloggt
- **Fix:** Nur Fehlermeldung loggen, nicht die Daten
- **Status:** [ ] Offen

### SEC-004: Fehlende MaxLength-Constraints
- **Kategorie:** Security
- **Datei:** person_detail_page, person_create_page, problemfall_accordion
- **Problem:** TextField ohne `maxLength`
- **Fix:** `maxLength: 500` (oder angemessen) hinzufügen
- **Status:** [ ] Offen

### SEC-005: UI-only Role Checks
- **Kategorie:** Security
- **Datei:** `lib/features/people/presentation/pages/person_detail_page.dart:942-986`
- **Problem:** Rollen-Update nur Frontend-geprüft
- **Fix:** RLS-Policy auf tenantUsers sicherstellen
- **Status:** [ ] Offen

### FN-004: _launchPhone nicht implementiert
- **Kategorie:** Funktional
- **Datei:** `lib/features/people/presentation/widgets/person_detail/allgemein_accordion.dart:716-718`
- **Problem:** Methode ist leer mit TODO
- **Fix:** `url_launcher` mit `tel:$phone` implementieren
- **Status:** [ ] Offen

### FN-005: stats['percentage'] kann null sein
- **Kategorie:** Funktional
- **Datei:** `lib/features/people/presentation/widgets/person_detail/historie_accordion.dart:99-100`
- **Problem:** Type Cast ohne null-Check
- **Fix:** `as int? ?? 0`
- **Status:** [ ] Offen

### FN-006: Fehlende Error-State Anzeige in PersonHeader
- **Kategorie:** Funktional
- **Datei:** `lib/features/people/presentation/widgets/person_detail/person_header.dart:77-79`
- **Problem:** Error-State wird mit `SizedBox.shrink()` behandelt
- **Fix:** Fehlermeldung anzeigen
- **Status:** [ ] Offen

### FN-007: person.critical vs person.isCritical Inkonsistenz
- **Kategorie:** Funktional
- **Datei:** `lib/features/people/presentation/pages/people_list_page.dart:916,932`
- **Problem:** Inkonsistente Property-Verwendung
- **Fix:** Auf `person.isCritical` vereinheitlichen
- **Status:** [ ] Offen

### FN-008: SelectionSheet Ergebnis nicht vollständig geprüft
- **Kategorie:** Funktional
- **Datei:** `lib/features/people/presentation/widgets/person_detail/allgemein_accordion.dart:263-270`
- **Problem:** Abbruch könnte unexpected State verursachen
- **Fix:** Explizite null-Prüfung bei Abbruch
- **Status:** [ ] Offen

### RT-010: Dynamic shift Parameter
- **Kategorie:** Runtime
- **Datei:** `lib/features/people/presentation/widgets/person_detail/allgemein_accordion.dart:469-471`
- **Problem:** `shift` als dynamic, kein Type-Check
- **Fix:** Typsicheren Parameter verwenden
- **Status:** [ ] Offen

### BL-007: isCurrentlyPaused ignoriert abgelaufene Pause
- **Kategorie:** Business-Logik
- **Datei:** `lib/data/models/person/person.dart:184-190`
- **Problem:** Zeigt paused an obwohl pausedUntil abgelaufen
- **Fix:** auto-unpause Job häufiger ausführen
- **Status:** [ ] Offen

### BL-008: Fehlende Warnung bei Handover ohne Gruppe
- **Kategorie:** Business-Logik
- **Datei:** `lib/features/people/presentation/widgets/handover_sheet.dart:349-450`
- **Problem:** Keine Warnung wenn Spieler ohne Gruppe übertragen wird
- **Fix:** Warnung anzeigen
- **Status:** [ ] Offen

### BL-009: peopleListProvider ohne Gruppen-Fallback
- **Kategorie:** Business-Logik
- **Datei:** `lib/features/people/presentation/pages/people_list_page.dart:22-69`
- **Problem:** Fehler bei Gruppen-Laden blockiert gesamte Liste
- **Fix:** Try-catch mit leerer Map als Fallback
- **Status:** [ ] Offen

### BL-010: Email-Validierung nur Client-seitig
- **Kategorie:** Business-Logik
- **Datei:** `lib/features/people/presentation/pages/person_create_page.dart:217-225`
- **Problem:** Keine serverseitige E-Mail-Validierung
- **Fix:** Supabase Check Constraint hinzufügen
- **Status:** [ ] Offen

---

## NIEDRIG

### SEC-006: Keine E-Mail-Domain-Validierung bei Handover
- **Kategorie:** Security
- **Datei:** `lib/data/repositories/player_repository.dart:937-955`
- **Problem:** E-Mail ohne weitere Validierung übertragen
- **Status:** [ ] Offen

### FN-009: imageUrl vs img Property Inkonsistenz
- **Kategorie:** Funktional
- **Datei:** people_list_page.dart vs person_header.dart
- **Problem:** Unterschiedliche Properties für Bild
- **Status:** [ ] Offen

### FN-010: problemNotes nicht persistent
- **Kategorie:** Funktional
- **Datei:** `lib/features/people/presentation/widgets/person_detail/problemfall_accordion.dart:119`
- **Problem:** Notes gehen bei Refresh verloren
- **Status:** [ ] Offen

### FN-011: Keyboard-Type fehlt bei Notizen
- **Kategorie:** Funktional
- **Datei:** `lib/features/people/presentation/widgets/person_detail/problemfall_accordion.dart:112-119`
- **Problem:** Kein `textCapitalization`
- **Status:** [ ] Offen

### FN-012: Duplizierte Pause-Dialog-Logik
- **Kategorie:** Funktional
- **Datei:** people_list_page.dart, person_detail_page.dart
- **Problem:** Code-Duplikation
- **Status:** [ ] Offen

### FN-013: Falscher Tooltip-Text
- **Kategorie:** Funktional
- **Datei:** `lib/features/people/presentation/pages/people_list_page.dart:320`
- **Problem:** "Gruppe wechseln" navigiert zu Tenants
- **Status:** [ ] Offen

### BL-011: Selection Mode bei Tenant-Wechsel nicht zurückgesetzt
- **Kategorie:** Business-Logik
- **Datei:** `lib/features/people/presentation/pages/people_list_page.dart:79-93`
- **Problem:** Alte Selektionen bleiben nach Tenant-Wechsel
- **Status:** [ ] Offen

### BL-012: History-Einträge ohne Limit
- **Kategorie:** Business-Logik
- **Datei:** `lib/data/repositories/player_repository.dart:256-265`
- **Problem:** Unbegrenztes History-Array
- **Status:** [ ] Offen

### BL-013: checkAndUnpausePlayers bei jedem Laden
- **Kategorie:** Business-Logik
- **Datei:** `lib/features/people/presentation/pages/people_list_page.dart:31-32`
- **Problem:** Unnötige DB-Queries bei jedem Refresh
- **Status:** [ ] Offen

### BL-014: Handover-Duplikat-Check unvollständig
- **Kategorie:** Business-Logik
- **Datei:** `lib/data/repositories/player_repository.dart:823-853`
- **Problem:** Nur Email/AppId geprüft, nicht Name
- **Status:** [ ] Offen

---

## Scan-Details

- **Gescannte Dateien:** ~15 (People Feature + Repository + Providers)
- **Scanner verwendet:** business-logic, functional, runtime, security
- **Dauer:** ~8 Minuten (parallel)
- **False Positives entfernt:** 4 (bereits korrekt implementierte Patterns)

## Nächste Schritte

1. **Kritische Bugs SOFORT fixen** - Force Unwraps und Berechtigungsprüfungen
2. **GitHub Issues erstellen** für die gefundenen Bugs
3. **Hohe Bugs in Sprint einplanen** - Security und Validierungen
4. **/fix-issues** für batch-fixing verwenden
