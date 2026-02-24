---
name: parity-audit
description: Ionic-Flutter Parity Audit mit 4 parallelen Agents. Generiert interaktives HTML-Dashboard mit Feature-Gaps, Service-Parity, UX-Divergenzen und Code-Quality Findings.
argument-hint: [ionic-path] [flutter-path] - optional, defaults to /Users/I576226/repositories/attendance/src/app/ and lib/features/
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, TaskCreate, TaskUpdate, TaskList, AskUserQuestion
---

# Parity Audit - Ionic→Flutter Migration Audit

Systematischer Vergleich zwischen Ionic und Flutter Codebase mit 4 spezialisierten Agents.

**Argumente:** $ARGUMENTS

---

## PHASE 0: SETUP

### 0.1 Pfade bestimmen

**Standard-Pfade:**
- Ionic: `/Users/I576226/repositories/attendance/src/app/`
- Flutter: `/Users/I576226/repositories/attendix/lib/features/`

Falls `$ARGUMENTS` angegeben:
- Erstes Argument: Ionic-Pfad
- Zweites Argument: Flutter-Pfad

### 0.2 Report-Verzeichnis erstellen

```bash
REPORT_DATE=$(date +%Y-%m-%d)
REPORT_DIR="docs/reports/ionic-flutter-parity-$REPORT_DATE"
mkdir -p "$REPORT_DIR"
```

### 0.3 Tasks erstellen

```
TaskCreate(subject: "Feature-Gap Scan", description: "feature-gap-scanner Agent - vergleicht Ionic Pages mit Flutter Pages", activeForm: "Scanne Feature-Gaps")
TaskCreate(subject: "Service-Parity Scan", description: "service-parity-checker Agent - vergleicht Ionic Services mit Flutter Repositories", activeForm: "Scanne Service-Parity")
TaskCreate(subject: "UX-Detail Scan", description: "ux-detail-analyzer Agent - vergleicht UX-Patterns (Dialoge, Toasts, Loading, etc.)", activeForm: "Scanne UX-Details")
TaskCreate(subject: "Code-Quality Scan", description: "code-quality-auditor Agent - prüft Multi-Tenant, Riverpod, Error-Handling", activeForm: "Scanne Code-Quality")
TaskCreate(subject: "Dashboard generieren", description: "Aggregation und HTML-Dashboard erstellen", activeForm: "Generiere Dashboard")
```

---

## PHASE 1: PARALLEL SCANS

**WICHTIG: Alle 4 Scanner PARALLEL starten mit `run_in_background: true`!**

### Agent-Prompts

```
Task(
  subagent_type: "feature-gap-scanner",
  description: "Scan Feature Gaps",
  prompt: "Führe einen Feature-Gap Scan durch. Ionic-Pfad: [IONIC_PATH]. Flutter-Pfad: [FLUTTER_PATH]. Vergleiche alle Ionic Pages mit Flutter Pages. Output: JSON mit pageComparisons, missingFeatures, extraFeatures, criticalGaps, scores.",
  run_in_background: true
)

Task(
  subagent_type: "service-parity-checker",
  description: "Scan Service Parity",
  prompt: "Führe einen Service-Parity Scan durch. Ionic-Pfad: [IONIC_PATH]/services/. Flutter-Pfad: [FLUTTER_PATH]/../data/repositories/. Vergleiche alle Ionic Services mit Flutter Repositories. Output: JSON mit services, methods, mappings, scores.",
  run_in_background: true
)

Task(
  subagent_type: "ux-detail-analyzer",
  description: "Scan UX Details",
  prompt: "Führe einen UX-Detail Scan durch. Ionic-Pfad: [IONIC_PATH]. Flutter-Pfad: [FLUTTER_PATH]/../. Vergleiche UX-Patterns: Dialoge, Toasts, Loading, Pull-to-Refresh, Forms, Navigation. Output: JSON mit categories, divergences, scores.",
  run_in_background: true
)

Task(
  subagent_type: "code-quality-auditor",
  description: "Scan Code Quality",
  prompt: "Führe einen Code-Quality Audit durch. Flutter-Pfad: [FLUTTER_PATH]/../. Prüfe: Multi-Tenant Security (KRITISCH!), Riverpod Patterns, Error Handling, Freezed Models, Import Structure. Output: JSON mit categories, findings, scores.",
  run_in_background: true
)
```

### Auf Ergebnisse warten

Sammle alle 4 Agent-Outputs mit `TaskOutput`.

---

## PHASE 2: AGGREGATION

### 2.1 JSON-Dateien sammeln

Aus den Agent-Outputs extrahieren und speichern:

```bash
# Speichere Agent-Outputs als JSON
Write(file_path: "$REPORT_DIR/feature_gaps.json", content: [FEATURE_GAPS_OUTPUT])
Write(file_path: "$REPORT_DIR/service_parity.json", content: [SERVICE_PARITY_OUTPUT])
Write(file_path: "$REPORT_DIR/ux_divergences.json", content: [UX_DIVERGENCES_OUTPUT])
Write(file_path: "$REPORT_DIR/code_quality.json", content: [CODE_QUALITY_OUTPUT])
```

### 2.2 Scores berechnen

**Score-Formel (gewichtet):**

```
overallScore = (featureScore × 1.5 + serviceScore × 1.0 + uxScore × 0.8 + codeQualityScore × 1.0) / 4.3
```

Gewichtung:
- Features: 1.5 (höchste Priorität - funktionale Parität)
- Services: 1.0 (wichtig für Datenintegrität)
- UX: 0.8 (wichtig aber subjektiver)
- Code Quality: 1.0 (wichtig für Wartbarkeit)

### 2.3 Aggregierte Daten erstellen

```json
{
  "generatedAt": "[ISO_TIMESTAMP]",
  "summary": {
    "featureScore": [FEATURE_SCORE],
    "serviceScore": [SERVICE_SCORE],
    "uxScore": [UX_SCORE],
    "codeQualityScore": [CODE_QUALITY_SCORE],
    "overallScore": [OVERALL_SCORE]
  },
  "featureGaps": [FEATURE_GAPS_DATA],
  "serviceParity": [SERVICE_PARITY_DATA],
  "uxDivergences": [UX_DIVERGENCES_DATA],
  "codeQuality": [CODE_QUALITY_DATA]
}
```

---

## PHASE 3: HTML DASHBOARD

### 3.1 Dashboard generieren

Erstelle `$REPORT_DIR/index.html` mit:

1. **Eingebetteten Daten** (keine externen JSON-Fetches wegen CORS):
   ```javascript
   const AUDIT_DATA = { ... aggregierte Daten ... };
   ```

2. **Interaktive Sections:**
   - Overall Score Hero
   - 4 Score Cards (Features, Services, UX, Code Quality)
   - Expandierbare Detail-Sections für jede Kategorie

3. **Styling:**
   - Tailwind CSS via CDN
   - Score-basierte Farbcodierung (grün ≥90, gelb ≥70, rot <70)
   - Severity Badges (critical=rot, warning=gelb, info=grün)

### 3.2 HTML-Template

Nutze das Template aus `docs/reports/ionic-flutter-parity-2026-02-24/index.html` als Basis.

Die `AUDIT_DATA` Variable wird mit den aktuellen Scan-Ergebnissen befüllt.

---

## PHASE 4: GITHUB ISSUES (Optional)

### 4.1 Kritische Findings

Falls kritische Findings vorhanden:

```bash
# Nur für KRITISCHE Findings (Security, Multi-Tenant)
gh issue create --title "[Parity] KRITISCH: [Finding Title]" \
  --body "## Problem\n[Description]\n\n## Location\n[File:Line]\n\n## Impact\n[Impact Description]\n\n## Fix\n[Suggested Fix]" \
  --label "priority:critical,type:security"
```

### 4.2 Feature-Gaps als Issues

Für wichtige Feature-Gaps (Impact: HIGH):

```bash
gh issue create --title "[Parity] Missing Feature: [Feature Name]" \
  --body "## Missing in Flutter\n[Feature Description]\n\n## Ionic Location\n[File]\n\n## Estimated Effort\n[Effort]" \
  --label "type:enhancement,source:parity-audit"
```

---

## PHASE 5: ABSCHLUSS

### 5.1 Report committen

```bash
git add "$REPORT_DIR/"
git commit -m "docs: Add Ionic-Flutter parity audit report $REPORT_DATE

- Feature parity: [FEATURE_SCORE]%
- Service parity: [SERVICE_SCORE]%
- UX parity: [UX_SCORE]%
- Code quality: [CODE_QUALITY_SCORE]%
- Overall: [OVERALL_SCORE]%

Generated by /parity-audit skill"
```

### 5.2 Zusammenfassung anzeigen

```
## Parity Audit Complete

📊 **Overall Score: [OVERALL_SCORE]%**

| Category | Score |
|----------|-------|
| Features | [FEATURE_SCORE]% |
| Services | [SERVICE_SCORE]% |
| UX | [UX_SCORE]% |
| Code Quality | [CODE_QUALITY_SCORE]% |

📁 **Report:** $REPORT_DIR/index.html

🔴 **Critical Findings:** [COUNT]
🟡 **Warnings:** [COUNT]
🟢 **Info:** [COUNT]

**Top 3 Action Items:**
1. [ACTION_1]
2. [ACTION_2]
3. [ACTION_3]
```

### 5.3 Tasks abschließen

Alle Tasks als completed markieren.

---

## Checkliste

- [ ] Pfade bestimmt (default oder custom)
- [ ] Report-Verzeichnis erstellt
- [ ] Tasks erstellt
- [ ] 4 Scanner parallel gestartet
- [ ] Auf alle Scanner-Ergebnisse gewartet
- [ ] JSON-Dateien gespeichert
- [ ] Scores berechnet
- [ ] HTML-Dashboard generiert
- [ ] GitHub Issues erstellt (falls kritisch)
- [ ] Report committed
- [ ] Zusammenfassung angezeigt
- [ ] Tasks abgeschlossen

---

## Agent-Referenz

| Agent | Fokus | Output |
|-------|-------|--------|
| `feature-gap-scanner` | Ionic Pages vs Flutter Pages | `feature_gaps.json` |
| `service-parity-checker` | Ionic Services vs Flutter Repos | `service_parity.json` |
| `ux-detail-analyzer` | UX-Patterns (Dialoge, Toasts, etc.) | `ux_divergences.json` |
| `code-quality-auditor` | Multi-Tenant, Riverpod, Error Handling | `code_quality.json` |

---

## Score-Interpretation

| Score | Status | Bedeutung |
|-------|--------|-----------|
| ≥90% | ✨ Excellent | Parität erreicht, nur kleinere Verbesserungen |
| 70-89% | ⚡ Good | Guter Fortschritt, einige Lücken zu schließen |
| 50-69% | ⚠️ Needs Work | Signifikante Arbeit nötig |
| <50% | 🔴 Critical | Migration weit von Parität entfernt |

---

## Anti-Patterns (VERBOTEN!)

1. **Scanner sequentiell starten** - IMMER parallel mit `run_in_background: true`!
2. **Ohne Dashboard abschließen** - HTML-Dashboard ist Pflicht!
3. **JSON extern laden** - Daten IMMER einbetten wegen CORS!
4. **Multi-Tenant Findings ignorieren** - IMMER kritisch behandeln!
5. **Ohne Scores abschließen** - Alle 4 Scores + Overall berechnen!

---

## Beispiel-Aufruf

```bash
# Standard-Pfade
/parity-audit

# Custom-Pfade
/parity-audit /path/to/ionic /path/to/flutter
```
