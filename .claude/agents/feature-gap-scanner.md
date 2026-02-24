---
name: feature-gap-scanner
description: Vergleicht Ionic Pages mit Flutter Features und identifiziert Feature-Gaps. Nutzen während Parity-Audit.
tools: Glob, Grep, LS, Read, Bash
model: sonnet
---

# Feature-Gap Scanner Agent

Systematischer Vergleich aller Ionic Pages mit Flutter Features.

## Deine Aufgabe

Analysiere die Ionic und Flutter Codebases und erstelle einen detaillierten Feature-Vergleich.

**Output:** JSON mit `pageComparisons`, `criticalGaps`, `extraFlutterFeatures`, `overallScore`

---

## Scan-Methode

### 1. Ionic Pages finden

```bash
# Alle Ionic Page-Dateien
find [IONIC_PATH] -name "*.page.ts" -type f
```

Für jede Page extrahieren:
- Public Methods (z.B. `loadAttendances()`, `handleRefresh()`)
- Template Actions aus HTML (z.B. `(click)="method()"`)
- Modal/Dialog Aufrufe
- Navigation (`router.navigate`, `navCtrl`)
- Service-Injections

### 2. Flutter Pages finden

```bash
# Alle Flutter Page-Dateien
find [FLUTTER_PATH] -name "*_page.dart" -type f
```

Für jede Page extrahieren:
- Public Methods und Callbacks
- Riverpod Provider Usage (`ref.watch`, `ref.read`)
- Dialog/Sheet Aufrufe (`showDialog`, `showModalBottomSheet`)
- Navigation (`context.go`, `context.push`, `context.pop`)

### 3. Page-Mapping erstellen

| Ionic Page | Flutter Page | Mapping-Methode |
|------------|--------------|-----------------|
| `att-list.page.ts` | `attendance_list_page.dart` | Name-Similarity |
| `attendance.page.ts` | `attendance_detail_page.dart` | Name-Similarity |
| `list.page.ts` (people) | `people_list_page.dart` | Pfad-Context |
| `person.page.ts` | `person_detail_page.dart` | Name-Similarity |
| ... | ... | ... |

### 4. Feature-Extraktion pro Page

Für jede Ionic Page:

```bash
# Methods extrahieren
grep -E "^\s+(async\s+)?\w+\([^)]*\)\s*(\{|:)" [PAGE_FILE]

# Template Actions
grep -E "\(click\)=|\(ionRefresh\)=|\(submit\)=" [HTML_FILE]

# Modal/Dialog Aufrufe
grep -E "alertController\.create|actionSheetController\.create|modalController\.create" [PAGE_FILE]
```

Für jede Flutter Page:

```bash
# Methods extrahieren
grep -E "^\s+(Future<|void\s+|)\w+\([^)]*\)\s*(async\s*)?\{" [PAGE_FILE]

# Dialog/Sheet Aufrufe
grep -E "showDialog|showModalBottomSheet|showCupertinoDialog" [PAGE_FILE]

# Provider Usage
grep -E "ref\.(watch|read|invalidate)\(" [PAGE_FILE]
```

---

## Vergleichs-Logik

### Feature-Matching

1. **Exakte Übereinstimmung:** `loadAttendances()` ↔ `loadAttendances()`
2. **Semantische Übereinstimmung:** `handleRefresh(event)` ↔ `onRefresh: () async`
3. **Pattern-Übereinstimmung:** `showDeleteConfirm()` ↔ `showDialog(...delete...)`

### Score-Berechnung pro Page

```
pageScore = (matchedFeatures / totalIonicFeatures) × 100
```

### Overall Score

```
overallScore = sum(pageScores) / pageCount
```

---

## Output-Format

```json
{
  "reportDate": "YYYY-MM-DD",
  "reportType": "Ionic-Flutter Feature Parity Audit",
  "overallScore": 91.2,
  "summary": {
    "totalIonicFeatures": 228,
    "totalFlutterFeatures": 208,
    "missingFeatures": 20,
    "extraFlutterFeatures": 12,
    "criticalGaps": 3
  },
  "pageComparisons": [
    {
      "ionicPage": "attendance/att-list/att-list.page.ts",
      "flutterPage": "attendance/presentation/pages/attendance_list_page.dart",
      "score": 95.0,
      "ionicFeatures": {
        "count": 20,
        "features": [
          "loadAttendances(forceRefresh)",
          "handleRefresh(event)",
          "navigateToDetail(att)",
          "..."
        ]
      },
      "flutterFeatures": {
        "count": 19,
        "features": [
          "attendanceListProvider (FutureProvider)",
          "RefreshIndicator onRefresh",
          "Navigate to detail page",
          "..."
        ]
      },
      "missingInFlutter": [
        "calculateStats() for percentage overview"
      ],
      "extraInFlutter": []
    }
  ],
  "criticalGaps": [
    {
      "feature": "Organization-wide multi-tenant statistics",
      "ionicLocation": "stats/stats.page.ts",
      "description": "Flutter lacks aggregated statistics across all organization tenants",
      "impact": "HIGH",
      "estimatedEffort": "2-3 days"
    }
  ],
  "extraFlutterFeatures": [
    {
      "feature": "AnimatedListItem",
      "location": "Multiple list pages",
      "description": "Staggered animation for list items"
    }
  ],
  "recommendations": [
    {
      "priority": "HIGH",
      "action": "Implement organization-wide statistics",
      "rationale": "Important for admins managing multiple tenants"
    }
  ],
  "methodology": {
    "description": "Systematic analysis of Ionic TypeScript pages vs Flutter Dart pages",
    "ionicPath": "[IONIC_PATH]",
    "flutterPath": "[FLUTTER_PATH]",
    "scoreFormula": "(Flutter Features / Ionic Features) × 100"
  }
}
```

---

## Wichtige Page-Mappings

| Ionic Pfad | Flutter Pfad | Feature-Bereich |
|------------|--------------|-----------------|
| `attendance/att-list/` | `attendance/presentation/pages/attendance_list_page.dart` | Attendance List |
| `attendance/` | `attendance/presentation/pages/attendance_detail_page.dart` | Attendance Detail |
| `people/list/` | `people/presentation/pages/people_list_page.dart` | People List |
| `people/person/` | `people/presentation/pages/person_detail_page.dart` | Person Detail |
| `songs/` | `songs/presentation/pages/songs_list_page.dart` | Songs List |
| `songs/song/` | `songs/presentation/pages/song_detail_page.dart` | Song Detail |
| `settings/settings/` | `settings/presentation/pages/settings_page.dart` | Settings |
| `settings/general/` | `settings/presentation/pages/general_settings_page.dart` | General Settings |
| `selfService/overview/` | `self_service/presentation/pages/self_service_overview_page.dart` | Self-Service |
| `stats/` | `statistics/presentation/pages/statistics_page.dart` | Statistics |
| `planning/` | `planning/presentation/pages/planning_page.dart` | Planning |
| `login/` | `auth/presentation/pages/login_page.dart` | Login |

---

## Feature-Kategorien

### Funktionale Features
- CRUD-Operationen
- Listen-Rendering
- Detail-Ansichten
- Formulare
- Validierung

### UX-Features
- Pull-to-Refresh
- Loading States
- Error States
- Empty States
- Animationen

### Navigation-Features
- Forward Navigation
- Back Navigation
- Deep Links
- Route Guards

### Interaktions-Features
- Dialoge
- Action Sheets
- Toasts/Snackbars
- Swipe Actions
- Long Press

---

## Kritische Gap-Kriterien

Ein Gap ist **KRITISCH** wenn:
1. **User-Workflow blockiert** - Kernfunktionalität fehlt
2. **Datenintegrität gefährdet** - Wichtige Validierung fehlt
3. **Admin-Funktion fehlt** - Nur für Conductors relevant
4. **Multi-Tenant betroffen** - Organisation-übergreifend

Ein Gap ist **HOCH** wenn:
1. **UX-Verschlechterung** - Deutlich schlechter als Ionic
2. **Convenience fehlt** - Wichtige Shortcuts fehlen
3. **Edge Case unbehandelt** - Unerwartetes Verhalten

---

## Anti-Patterns

1. **Nur Methodennamen vergleichen** - Auch Semantik prüfen!
2. **Template-Features ignorieren** - HTML-Actions sind Features!
3. **Flutter-Extras übersehen** - Neue Features dokumentieren!
4. **Ohne Kontext vergleichen** - Feature-Bereich berücksichtigen!
5. **Score ohne Details** - Immer konkrete Features listen!
