# Ionic → Flutter Parity Gap Report

**Erstellt:** 2026-02-25
**Analysiert von:** 4 parallele Agents (Service-Parity, Feature-Gap, UX-Detail, Code-Quality)

---

## Executive Summary

| Kategorie | Score | Status |
|-----------|-------|--------|
| **Service Parity** | 62% | ⚠️ Gaps vorhanden |
| **Feature/UI Parity** | 87% | ⚠️ Gaps vorhanden |
| **UX Patterns** | 74% | ⚠️ Gaps vorhanden |
| **Code Quality** | 94% | ✅ Gut |
| **Gesamt** | ~79% | ⚠️ |

---

## 1. Kritische Gaps (Prio 1) 🔴

Diese Features sind essentiell für die Funktionalität und sollten vor dem Release implementiert werden.

### 1.1 Realtime-Updates in Attendance Detail

**Status:** NICHT IMPLEMENTIERT
**Impact:** HOCH - Mehrere Nutzer sehen keine Live-Updates

**Ionic Implementation:**
```typescript
// attendance.page.ts:101-116
subsribeOnChannels() {
  this.sub = this.db.getSupabase()
    .channel('att-changes').on(
      'postgres_changes',
      { event: '*', schema: 'public', table: 'attendance' },
      (payload) => this.onAttRealtimeChanges(payload))
    .subscribe();
}
```

**Flutter TODO:**
- [ ] Supabase Realtime Channel in `attendance_detail_page.dart`
- [ ] `ref.invalidate()` bei Änderungen
- [ ] Unsubscribe bei dispose

---

### 1.2 Checklisten-Feature

**Status:** NICHT IMPLEMENTIERT
**Impact:** HOCH - Feature wird aktiv genutzt

**Ionic Location:** `attendance.page.ts:570-786`

**Fehlende Funktionen:**
- [ ] `toggleChecklistItem()` - Item abhaken
- [ ] `addChecklistItem()` - Neues Item
- [ ] `removeChecklistItem()` - Item löschen
- [ ] `restoreChecklist()` - Von Vorlage wiederherstellen
- [ ] Deadline-Anzeige (overdue/warning)
- [ ] Progress-Anzeige

**Geschätzter Aufwand:** 4-6 Stunden

---

### 1.3 Werke-History zu Anwesenheit

**Status:** NICHT IMPLEMENTIERT
**Impact:** MITTEL-HOCH

**Ionic Location:** `attendance.page.ts:370-456`

**Fehlende Funktionen:**
- [ ] `addSongsToHistory()` - Werke zuordnen
- [ ] `removeHistoryEntry()` - Eintrag entfernen
- [ ] Dirigent-Auswahl
- [ ] Accordion-UI in Attendance Detail

**Geschätzter Aufwand:** 3-4 Stunden

---

### 1.4 "Meine Stammdaten" Card

**Status:** NICHT IMPLEMENTIERT
**Impact:** HOCH - Benutzer können Profil nicht ändern

**Ionic Location:** `settings.page.html:86-161`

**Fehlende Funktionen:**
- [ ] Avatar-Anzeige
- [ ] Passbild ändern (Kamera/Galerie)
- [ ] Vorname/Nachname bearbeiten
- [ ] Geburtstag bearbeiten
- [ ] Telefon bearbeiten

**Geschätzter Aufwand:** 3-4 Stunden

---

### 1.5 Song File-Operationen

**Status:** TEILWEISE IMPLEMENTIERT
**Impact:** HOCH - Noten-Management eingeschränkt

**Ionic Service:** `song.service.ts`

**Fehlende Methoden:**
| Methode | Beschreibung | Status |
|---------|--------------|--------|
| `uploadSongFile()` | Noten hochladen | ❌ |
| `downloadSongFile()` | Noten herunterladen | ❌ |
| `downloadSongFileFromPath()` | Download von Pfad | ❌ |
| `deleteSongFile()` | Datei löschen | ❌ |
| `copySongToTenant()` | Werk kopieren | ❌ |

**Geschätzter Aufwand:** 4-6 Stunden

---

### 1.6 Gruppen-PDFs drucken (Smart Print)

**Status:** NICHT IMPLEMENTIERT
**Impact:** MITTEL-HOCH

**Ionic Location:** `song.page.ts:607-776`

**Fehlende Funktionen:**
- [ ] Kopienanzahl pro Gruppe (basierend auf Spielerzahl)
- [ ] PDF mergen
- [ ] Druckvorschau

**Geschätzter Aufwand:** 4-5 Stunden

---

### 1.7 Registerprobenplan

**Status:** NICHT IMPLEMENTIERT
**Impact:** MITTEL

**Ionic Location:** `planning.page.ts:444-492`

**Fehlende Funktionen:**
- [ ] Dirigenten shufflen
- [ ] Zeitslots berechnen
- [ ] PDF generieren

**Geschätzter Aufwand:** 3-4 Stunden

---

## 2. Hohe Gaps (Prio 2) 🟡

### 2.1 UI/Feature Gaps

| Feature | Seite | Beschreibung | Aufwand |
|---------|-------|--------------|---------|
| Aktuelle Werke Modal | Songs | Aktuelle Stücke anzeigen | 2h |
| Gruppenverzeichnis Modal | Songs | Alle Gruppen übersichtlich | 2h |
| Werkhistorie Modal | Settings | Song-History verwalten | 2-3h |
| Passwort ändern | Settings | Passwort-Änderung | 1-2h |
| Admins verwalten | Settings | Admin-User CRUD | 3h |
| Fehlende Accounts | Settings | Bulk Account Creation | 2h |
| Klick/Auswahl-Modus | Attendance | Status-Änderungsmodus | 2h |
| Status-Übersicht Modal | Attendance | Status-Zusammenfassung | 1-2h |
| Ablaufplan anzeigen | Attendance | Plan-Accordion | 2h |
| Ablaufplan-Export | Attendance | PDF-Export | 2h |
| Share Plan Toggle | Planning | Plan teilen | 1h |
| Notizfeld hinzufügen | Planning | Notizen im Plan | 1h |
| Fehlende Instrumente | Planning | Anzeige | 1h |

### 2.2 Service/Repository Gaps

| Service | Fehlende Methoden | Beschreibung |
|---------|-------------------|--------------|
| `shift.service.ts` | `getPlayersWithShift()`, `assignShiftToPlayersInTenant()` | Cross-Tenant Shift-Handover |
| `attendance.service.ts` | `getParentAttendances()` | Parent-Portal Feature |
| `attendance-type.service.ts` | `addDefaultAttendanceTypes()` | Onboarding |
| `player.service.ts` | `resetExtraFieldValues()`, `updateExtraFieldValue()` | Extra Fields Admin |
| `history.service.ts` | 6 Methoden | Song-History CRUD |
| `cross-tenant.service.ts` | 7 Methoden | Cross-Tenant Features |

---

## 3. UX-Divergenzen 🟠

### 3.1 Toast-Meldungen

**Ionic:** 362 Toast-Aufrufe
**Flutter:** 190 Toast-Aufrufe
**Differenz:** -172 (47% fehlen!)

**Hauptprobleme:**
- Repository-Fehler werden nicht an User kommuniziert
- Viele Erfolgsmeldungen fehlen
- Service-Layer Fehlermeldungen nicht angezeigt

**Empfehlung:** ToastHelper.showError/showSuccess in allen Repository-Operationen ergänzen

---

### 3.2 Dialoge

**Ionic:** 126 Dialoge
**Flutter:** 82 Dialoge
**Differenz:** -44

**Fehlende Dialog-Typen:**
- Text-Input-Dialoge (z.B. "Beobachter hinzufügen")
- Confirmation-Dialoge für einige Operationen

---

### 3.3 Loading States

**Ionic:** Modal Overlay mit Text ("Speichern...", "Laden...")
**Flutter:** Inline CircularProgressIndicator

**Problem:** Flutter blockiert UI nicht bei langen Operationen

**Empfehlung:** Modal Loading Overlay für kritische Operationen implementieren

---

### 3.4 Positive Divergenzen (Flutter besser)

| Bereich | Ionic | Flutter | Verbesserung |
|---------|-------|---------|--------------|
| Pull-to-Refresh | 11 Listen | 17 Listen | +55% |
| Form Validation | 9 | 28 | +211% |
| DialogHelper | - | ✅ | Zentralisiert |
| ToastHelper | - | ✅ | Strukturiert |
| AnimatedListItem | - | ✅ | Animations |
| Dark Mode | Basic | ✅ | Besser |

---

## 4. Security Findings

### 4.1 Multi-Tenant Warnings

**Severity:** MEDIUM
**Betroffene Dateien:**

| Datei | Methode | Problem |
|-------|---------|---------|
| `sign_in_out_repository.dart:64` | `signIn()` | Update ohne tenantId |
| `sign_in_out_repository.dart:86` | `signOut()` | Update ohne tenantId |
| `sign_in_out_repository.dart:104` | `updateAttendanceNote()` | Update ohne tenantId |
| `attendance_repository.dart:221` | `updatePersonAttendance()` | Update ohne tenantId |
| `attendance_repository.dart:257` | `batchUpdatePersonAttendances()` | Update ohne tenantId |
| `attendance_repository.dart:297` | `recalculatePercentage()` | Select ohne tenantId |

**Risikobewertung:**
- Operationen nutzen UUIDs die global einzigartig sind
- Vermutlich durch Supabase RLS geschützt
- Empfehlung: RLS-Policies verifizieren oder Tenant-Validierung via JOIN hinzufügen

### 4.2 Positive Findings

- ✅ Alle anderen Repositories korrekt mit tenantId-Filter
- ✅ Riverpod Patterns korrekt (100%)
- ✅ Error Handling konsistent (100%)
- ✅ Freezed Models vollständig (100%)
- ✅ Deutsche Labels korrekt (100%)

---

## 5. Service Method Mapping

### 5.1 Vollständig migrierte Services (Score 90-100%)

| Ionic Service | Flutter Repository | Score |
|---------------|-------------------|-------|
| `meeting.service.ts` | `meeting_repository.dart` | 100% |
| `teacher.service.ts` | `teacher_repository.dart` | 100% |
| `feedback.service.ts` | `feedback_repository.dart` | 100% |
| `church.service.ts` | `church_repository.dart` | 100% |
| `organisation.service.ts` | `organisation_repository.dart` | 100% |
| `viewer-parent.service.ts` | `viewer_repository.dart` + `parent_repository.dart` | 100% |
| `handover.service.ts` | `player_repository.dart` | 100% |
| `group.service.ts` | `group_repository.dart` | 92% |

### 5.2 Gut migrierte Services (Score 70-89%)

| Ionic Service | Flutter Repository | Score | Fehlend |
|---------------|-------------------|-------|---------|
| `sign-in-out.service.ts` | `sign_in_out_repository.dart` | 88% | Telegram |
| `attendance-type.service.ts` | `attendance_type_repository.dart` | 83% | Default Types |
| `attendance.service.ts` | `attendance_repository.dart` | 76% | Parent Att. |
| `player.service.ts` | `player_repository.dart` | 75% | Extra Fields |

### 5.3 Teilweise migrierte Services (Score 20-69%)

| Ionic Service | Flutter Repository | Score | Fehlend |
|---------------|-------------------|-------|---------|
| `shift.service.ts` | `shift_repository.dart` | 63% | Cross-Tenant |
| `song.service.ts` | `song_repository.dart` | 47% | File Ops |
| `history.service.ts` | - | 25% | CRUD |
| `cross-tenant.service.ts` | - | 20% | Handover |

### 5.4 Nicht migrierte Services (Score 0%)

| Service | Grund | Priorität |
|---------|-------|-----------|
| `ai.service.ts` | GPT-Features | Niedrig |
| `notification.service.ts` | Telegram/Push | Mittel |
| `telegram.service.ts` | Bot-Integration | Mittel |
| `image.service.ts` | Inline in Pages | Niedrig |

---

## 6. Empfohlene Reihenfolge

### Phase 1: Vor Release (8-12h)
1. Realtime-Updates in Attendance Detail
2. "Meine Stammdaten" Card
3. Checklisten-Feature
4. Toast-Meldungen ergänzen (kritische Pfade)

### Phase 2: Nächste Version (10-15h)
5. Song File-Operationen
6. Werke-History zu Anwesenheit
7. Aktuelle Werke Modal
8. Passwort ändern
9. Security Warnings fixen

### Phase 3: Später (15-20h)
10. Registerprobenplan
11. Gruppen-PDFs drucken
12. Cross-Tenant Features
13. Telegram-Integration
14. Alle fehlenden Dialoge

---

## 7. Flutter-exklusive Features

Diese Features gibt es NUR in Flutter (nicht in Ionic):

| Feature | Beschreibung |
|---------|--------------|
| `forgot_password_page.dart` | Passwort-Zurücksetzen Flow |
| `viewers_page.dart` | Separate Betrachter-Verwaltung |
| `parents_page.dart` | Separate Eltern-Verwaltung |
| `calendar_subscription_page.dart` | iCal-Abo Setup |
| `smart_print_service.dart` | Intelligentes Drucken |
| `zip_service.dart` | ZIP-Download |
| `app_update_service.dart` | App-Update Handling |
| AnimatedListItem | Staggered List Animations |
| Inline PDF-Viewer | PDF direkt in App anzeigen |

---

## Anhang: Agent-Ergebnisse

- **Service-Parity-Checker:** 32 Ionic Services analysiert, 115 von 186 Methoden gemappt
- **Feature-Gap-Scanner:** 35 Ionic Pages vs 43 Flutter Pages verglichen
- **UX-Detail-Analyzer:** 944 Ionic UX-Patterns vs 515 Flutter Patterns
- **Code-Quality-Auditor:** 13 Repositories, 11 Providers, 15 Models geprüft

---

*Dieser Report wurde automatisch generiert und sollte regelmäßig aktualisiert werden.*
