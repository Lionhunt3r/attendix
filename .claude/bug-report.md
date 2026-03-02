# Bug Report - Attendix People Detail Page
Generiert: 2026-03-02
Scope: People Detail Page (`lib/features/people/`)

## Zusammenfassung

| Kategorie | KRITISCH | HOCH | MITTEL | NIEDRIG | Gesamt |
|-----------|----------|------|--------|---------|--------|
| Security | 0 | 0 | ~~2~~ 0 | ~~2~~ 0 | ~~4~~ 0 |
| Business-Logik | 0 | ~~2~~ 0 | ~~2~~ 1 | 0 | ~~4~~ 1 |
| Funktional | 0 | 0 | ~~4~~ 2 | ~~2~~ 2 | ~~6~~ 4 |
| Runtime | 0 | ~~2~~ 0 | ~~1~~ 0 | 0 | ~~3~~ 0 |
| **Gesamt** | **0** | **0** | **3** | **2** | **5** |

## Status: 12 von 17 Bugs gefixt!

**Gefixte Bugs (2026-03-02):**
- [x] SEC-001: Rollen-Prüfungen hinzugefügt
- [x] RT-001: Force Unwraps abgesichert
- [x] RT-002: imageUrl null-safe gemacht
- [x] RT-003: availableTenants.firstOrNull verwendet
- [x] RT-004: cardShape Cast abgesichert
- [x] BL-001: attended-Berechnung korrigiert
- [x] FN-001: TextEditingController Memory Leak behoben
- [x] FN-002: RefreshIndicator Provider korrigiert
- [x] SEC-002: Debug-Logs in kDebugMode gewrappt
- [x] SEC-003: Debug-Log in Handover Sheet in kDebugMode gewrappt

**Verbleibende Bugs:**
- [ ] BL-002: Handover ohne Rollen-Prüfung für Target-Tenant (MITTEL)
- [ ] FN-004: setState in Build-Methode via addPostFrameCallback (MITTEL)
- [ ] FN-005: FutureBuilder ohne Refresh-Mechanismus für Rolle (MITTEL)
- [ ] BL-003: Account-Erstellung nicht implementiert (NIEDRIG)
- [ ] FN-006: Keine Form-Validierung im Edit-Modus (NIEDRIG)

---

## HOCH

### SEC-001: Fehlende Rollen-Prüfung bei Person bearbeiten/speichern/pausieren/archivieren
- **Kategorie:** Security / Business-Logik
- **Dateien:**
  - `lib/features/people/presentation/pages/person_detail_page.dart:407` (_saveChanges)
  - `lib/features/people/presentation/pages/person_detail_page.dart:576-723` (_pausePerson, _archivePerson)
  - `lib/features/people/presentation/pages/person_create_page.dart:366` (_save)
- **Problem:** Die Methoden `_saveChanges()`, `_pausePerson()`, `_unpausePerson()`, `_archivePerson()` und `_save()` haben keine Rollen-Prüfung (isConductor/canEdit). Jeder authentifizierte Benutzer mit Zugriff auf die Detail-Seite kann Personendaten ändern.
- **Auswirkung:** Unautorisierte Datenmanipulation innerhalb eines Tenants. Obwohl RLS serverseitig schützt, bietet die UI nicht autorisierte Aktionen an.
- **Fix:**
```dart
final currentUserRole = ref.read(currentRoleProvider);
if (!currentUserRole.isConductor && !currentUserRole.isHelper) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Keine Berechtigung')),
  );
  return;
}
```
- **Status:** [ ] Offen

### RT-001: Force Unwrap auf tenant!.id! und person.id! ohne Null-Check
- **Kategorie:** Runtime
- **Dateien:**
  - `lib/features/people/presentation/pages/person_detail_page.dart:70` (personAttendanceStatsProvider)
  - `lib/features/people/presentation/pages/person_detail_page.dart:427` (_saveChanges)
  - `lib/features/people/presentation/pages/person_detail_page.dart:1796` (_buildRoleSelector)
- **Problem:** `tenant!.id!` und `person.id!` werden verwendet ohne vorherigen Null-Check. Bei fehlenden IDs crasht die App.
- **Auswirkung:** Garantierte App-Crashes bei neuen Personen oder fehlenden Tenant-Daten.
- **Fix:**
```dart
final tenantId = tenant?.id;
if (person.id == null || tenantId == null) {
  // Handle error gracefully
  return;
}
```
- **Status:** [ ] Offen

### RT-002: Force Unwrap bei imageUrl ohne konsistenten Check
- **Kategorie:** Runtime
- **Datei:** `lib/features/people/presentation/pages/people_list_page.dart:913,917`
- **Problem:** `person.imageUrl!.contains('.svg')` wird verwendet. Bei paralleler Ausführung oder State-Änderung könnte imageUrl zwischenzeitlich null werden.
- **Fix:**
```dart
backgroundImage: (person.imageUrl?.contains('.svg') == false)
    ? NetworkImage(person.imageUrl!)
    : null,
```
- **Status:** [ ] Offen

### RT-003: availableTenants.first ohne isNotEmpty Check
- **Kategorie:** Runtime
- **Datei:** `lib/features/people/presentation/widgets/handover_sheet.dart:82`
- **Problem:** `availableTenants.first.id` wird verwendet. Zwischen Check und Zugriff könnte sich State ändern.
- **Fix:**
```dart
_targetTenantId = availableTenants.firstOrNull?.id;
if (_targetTenantId == null) return;
```
- **Status:** [ ] Offen

---

## MITTEL

### BL-001: Statistik-Berechnung mit falscher Logik für 'attended'
- **Kategorie:** Business-Logik
- **Datei:** `lib/features/people/presentation/pages/person_detail_page.dart:83-84`
- **Problem:** `a['attended'] == true` sucht nach Feld das nicht existiert. Die Datenstruktur verwendet `status` als Integer (1=present).
- **Auswirkung:** `attended` ist immer 0, Anwesenheitsrate wird falsch berechnet (immer 0%).
- **Fix:**
```dart
final attended = pastAttendances.where((a) {
  final status = a['status'] as int?;
  return status == 1 || status == 3 || status == 5; // present, late, lateExcused
}).length;
```
- **Status:** [ ] Offen

### BL-002: Handover ohne Rollen-Prüfung für Target-Tenant
- **Kategorie:** Business-Logik
- **Datei:** `lib/features/people/presentation/widgets/handover_sheet.dart:543-604`
- **Problem:** Die Handover-Logik prüft nicht, ob der Benutzer im Ziel-Tenant Admin-Rechte hat.
- **Auswirkung:** Benutzer könnte Spieler in Tenants übertragen ohne dortige Berechtigung.
- **Fix:** Rollenpruefung für Target-Tenant hinzufügen.
- **Status:** [ ] Offen

### FN-001: TextEditingController Memory Leak in _buildExtraFieldInput
- **Kategorie:** Funktional
- **Datei:** `lib/features/people/presentation/pages/person_detail_page.dart:1295-1323`
- **Problem:** Neue TextEditingController werden im Widget-Baum erstellt ohne dispose. Bei jedem Rebuild neue Controller.
- **Auswirkung:** Memory Leak bei häufigen Rebuilds.
- **Fix:**
```dart
TextFormField(
  initialValue: currentValue?.toString() ?? '',
  onChanged: (value) {
    _additionalFieldValues[field.id] = value;
    _markChanged();
  },
)
```
- **Status:** [ ] Offen

### FN-002: Inkonsistente RefreshIndicator Provider-Verwendung
- **Kategorie:** Funktional
- **Datei:** `lib/features/people/presentation/pages/people_list_page.dart:412-416 vs 494-498`
- **Problem:** Liste zeigt `realtimePlayersProvider`, aber RefreshIndicator invalidiert `peopleListProvider`.
- **Auswirkung:** Pull-to-Refresh aktualisiert falschen Provider.
- **Fix:** Konsistent `realtimePlayersProvider` verwenden.
- **Status:** [ ] Offen

### FN-003: Missing Email Validation in Edit Form
- **Kategorie:** Funktional
- **Datei:** `lib/features/people/presentation/pages/person_detail_page.dart:973-1284`
- **Problem:** Edit-Formular hat keine E-Mail-Validierung (Create-Page hat sie).
- **Auswirkung:** User kann ungültige E-Mail-Adressen beim Bearbeiten eingeben.
- **Fix:** E-Mail-Validierung hinzufügen.
- **Status:** [ ] Offen

### FN-004: setState in Build-Methode via addPostFrameCallback
- **Kategorie:** Funktional
- **Datei:** `lib/features/people/presentation/widgets/handover_sheet.dart:78-87`
- **Problem:** Pattern mit addPostFrameCallback + setState in `.when(data:)` verursacht unnötige Rebuilds.
- **Fix:** Initialisierung in initState oder didChangeDependencies.
- **Status:** [ ] Offen

### FN-005: FutureBuilder ohne Refresh-Mechanismus für Rolle
- **Kategorie:** Funktional
- **Datei:** `lib/features/people/presentation/pages/person_detail_page.dart:1795-1843`
- **Problem:** Nach Rollenänderung via `_updateUserRole` wird FutureBuilder nicht aktualisiert.
- **Auswirkung:** UI zeigt alte Rolle bis Page neu geladen wird.
- **Fix:** Rolle als State verwalten oder Provider invalidieren.
- **Status:** [ ] Offen

### RT-004: Unsafe Cast auf cardShape
- **Kategorie:** Runtime
- **Datei:** `lib/features/people/presentation/pages/people_list_page.dart:881`
- **Problem:** `theme.cardTheme.shape as RoundedRectangleBorder?` kann bei anderem ShapeBorder-Typ fehlschlagen.
- **Fix:**
```dart
final cardShape = theme.cardTheme.shape is RoundedRectangleBorder
    ? theme.cardTheme.shape as RoundedRectangleBorder
    : const RoundedRectangleBorder();
```
- **Status:** [ ] Offen

### SEC-002: Debug-Logs könnten sensitive Daten enthalten
- **Kategorie:** Security
- **Dateien:**
  - `lib/features/people/presentation/pages/people_list_page.dart:52-59`
  - `lib/features/people/presentation/widgets/handover_sheet.dart:510`
- **Problem:** Bei Fehlern werden JSON-Daten (potentiell PII) in Logs ausgegeben.
- **Fix:**
```dart
if (kDebugMode) {
  debugPrint('Error parsing person: $parseError');
}
```
- **Status:** [ ] Offen

---

## NIEDRIG

### BL-003: Account-Erstellung nicht implementiert
- **Kategorie:** Business-Logik
- **Datei:** `lib/features/people/presentation/pages/person_detail_page.dart:2021-2052`
- **Problem:** `_createAccount()` zeigt nur Hinweis, Funktion fehlt.
- **Auswirkung:** UI bietet nicht funktionierende Funktion an.
- **Fix:** Funktion implementieren oder Button ausblenden.
- **Status:** [ ] Offen

### FN-006: Keine Form-Validierung im Edit-Modus
- **Kategorie:** Funktional
- **Datei:** `lib/features/people/presentation/pages/person_detail_page.dart:961`
- **Problem:** Kein Form mit GlobalKey und keine Pflichtfeld-Validierung.
- **Auswirkung:** User kann leere Namen speichern.
- **Fix:** Form mit Validierung hinzufügen.
- **Status:** [ ] Offen

### FN-007: Doppelte _loadTargetGroups Aufrufe
- **Kategorie:** Funktional
- **Datei:** `lib/features/people/presentation/widgets/handover_sheet.dart:343-346`
- **Problem:** Methode wird redundant aufgerufen.
- **Auswirkung:** Potentielle mehrfache API-Aufrufe.
- **Fix:** Redundanten Aufruf entfernen.
- **Status:** [ ] Offen

### SEC-003: Debug-Log in Handover Sheet
- **Kategorie:** Security (NIEDRIG)
- **Datei:** `lib/features/people/presentation/widgets/handover_sheet.dart:510`
- **Problem:** Wie SEC-002.
- **Status:** [ ] Offen

---

## Scan-Details

- **Gescannte Dateien:** 4 Feature-Dateien + zugehörige Repositories/Providers
- **Scanner verwendet:** business-logic, functional, runtime, security
- **Dauer:** ~2 Minuten
- **Duplikate entfernt:** 6 (zusammengefasste Issues)

## Positive Sicherheitsaspekte

1. **Korrekte Multi-Tenant-Isolation:** Alle Supabase-Queries filtern nach `tenantId`
2. **Rollen-Check bei Account-Operationen:** `_updateUserRole()` und `_unlinkAccount()` prüfen `isConductor`
3. **Tenant-Guard in Providers:** Alle `*WithTenantProvider` verwenden `hasTenantId` Check
4. **Inner-Joins für Cross-Table Security:** `person_attendances` wird korrekt via `!inner` Join gefiltert

## Nächste Schritte

1. **HOCH-Bugs zuerst:** Rollen-Prüfungen und Force-Unwraps fixen
2. **attended-Berechnung:** BL-001 korrigiert die Statistik-Anzeige
3. **Memory Leaks:** TextEditingController Pattern verbessern
4. **Code Review:** Nach Fixes mit `/simplify` optimieren
