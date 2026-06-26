# Polish Backlog

Laufende Liste von Code-Review-Findings, die bewusst auf "defer-able" markiert wurden. Pro Sprint eine Sektion. Wird abgearbeitet entweder im **Sprint 13 (Long Tail)** oder opportunistisch wenn man den Code ohnehin anfasst.

> **Konvention:**
> - Findings werden bei der Erstellung als 🟡 Minor klassifiziert. Wenn ein Finding später kritischer wird (z.B. nach Bug-Report), in einen normalen Sprint hochziehen.
> - Pro Sprint ein Tracking-Issue auf GitHub das auf den entsprechenden Abschnitt hier zeigt — so bleibt das Issue-Board übersichtlich.
> - Findings ohne ID sind frei nummerbar — wir verwenden `P-<sprint>-<nr>` (z.B. `P-1a-3`).

---

## Sprint 1a — Tracking + Audio Foundation (2026-06-19)

Bezug: `docs/superpowers/plans/2026-06-19-sprint-1a-tracking-audio.md`, finaler Code-Review.

### P-1a-1 — `_FakeRef`-Pattern koppelt Tests an `CurrentTenantNotifier` Internals
- **Datei:** `test/core/services/tracking/tracking_service_test.dart`
- **Problem:** Wenn `CurrentTenantNotifier._initializeTenant` jemals neue `ref.read`s hinzubekommt, brechen alle Tests die `_FakeCurrentTenantNotifier` nutzen mit `UnimplementedError`.
- **Fix-Vorschlag:** Kleinen `currentTenantValueProvider` (`Provider<Tenant?>`) anlegen der den State des `currentTenantProvider` wraps. Tests overriden den dann statt den Notifier.
- **Effort:** 30 min

### P-1a-2 — `Future.delayed(Duration.zero)` stylistisch unklar
- **Datei:** `test/core/services/tracking/tracking_service_test.dart` (mehrere Stellen)
- **Problem:** Ausdruck "warte einen Tick" ist als `Future.delayed(Duration.zero)` weniger expressiv als `Future.microtask(() {})`.
- **Fix-Vorschlag:** Pattern-Replace.
- **Effort:** 5 min

### P-1a-3 — `usage_events.sql` SQL-Datei nicht im Repo committed
- **Problem:** `supabase/sql/usage_events.sql` wird in Doc-Comments referenziert (siehe `lib/data/repositories/usage_events_repository.dart`, `lib/data/models/usage_event.dart`), existiert aber nur als untracked file im master. RLS-Aussagen sind aus dem Branch nicht verifizierbar.
- **Fix-Vorschlag:** Eigener Commit auf master, der die SQL-Migration committed (separat von Sprint-1a-Code).
- **Effort:** 15 min
- **Anmerkung:** Production-Tabelle existiert bereits (sonst hätten die heutigen Crawls anders ausgesehen) — nur das File ist im Repo nicht versioniert.

### P-1a-4 — `trackingDeviceTypeProvider` Desktop-Fallback ist `'web'`
- **Datei:** `lib/core/services/tracking/tracking_service.dart:16-26`
- **Problem:** Auf macOS-Desktop (Attendix wird laut CLAUDE.md auch dort deployed) wird der Device-Type als `'web'` geloggt. Im Dashboard nicht von echten Web-Usern unterscheidbar.
- **Fix-Vorschlag:** Fallback auf `'desktop'` ändern oder explizite Cases für `macOS`/`linux`/`windows`. Ionic-Equivalent verifizieren ob es das auch hat.
- **Effort:** 15 min

### P-1a-5 — `AudioPlayerState.currentSongName` `''` statt `String?`
- **Datei:** `lib/core/services/audio_player/audio_player_state.dart`
- **Problem:** Inkonsistenz: `currentUrl` und `currentFileName` sind `String?`, aber `currentSongName` defaultet auf `''`. Widget muss extra `state.currentSongName.isNotEmpty ? ... : ...` machen.
- **Fix-Vorschlag:** Auf `String?` umstellen, Widget mit `??` vereinfachen. Freezed-Migration.
- **Effort:** 20 min

### P-1a-6 — `_FakeRef.invalidate` swallowt Calls statt zu werfen
- **Datei:** `test/core/services/tracking/tracking_service_test.dart`
- **Problem:** Wenn die geteste Code-Pfad eines Tages `ref.invalidate(...)` aufruft, merkt der Test es nicht (Fake macht `{}`).
- **Fix-Vorschlag:** `throw UnimplementedError('invalidate not expected')` analog zur `noSuchMethod`-Strategie im Audio-Fake.
- **Effort:** 5 min

### P-1a-7 — Widget-Test-Lücke: kein `onTap`-Test für close/play-Button
- **Datei:** `test/shared/widgets/audio_player/audio_player_widget_test.dart`
- **Problem:** Tests prüfen Rendering aber nicht ob die Buttons die Service-Methoden aufrufen.
- **Fix-Vorschlag:** Drei kurze Tests mit `tester.tap(find.byIcon(...))` + `verify(svc.method).called(1)`.
- **Effort:** 30 min

### P-1a-8 — Mid-Playback-Fehler in `AudioPlayerService` nicht behandelt
- **Datei:** `lib/core/services/audio_player/audio_player_service.dart`
- **Problem:** Nur `ProcessingState.completed` wird beobachtet. Network-Drop mid-playback würde UI in "isPlaying=true" einfrieren.
- **Fix-Vorschlag:** `playbackEventStream` listenen, bei Errors auf `_stopInternal()` fallen.
- **Effort:** 1h

### P-1a-9 — `_disposePlayer` swallowt Errors stumm in Production
- **Datei:** `lib/core/services/audio_player/audio_player_service.dart` (`_disposePlayer`)
- **Problem:** `unawaited(_stopInternal())` in `onDispose` — wenn stop/dispose throwed, sieht's niemand.
- **Fix-Vorschlag:** `unawaited(_stopInternal().catchError((e, st) { debugPrint('AudioPlayer dispose error: $e'); }))`.
- **Effort:** 5 min

### P-1a-10 — `AudioPlayerService.isAudioFile` und `formatTime` als statics auf Notifier
- **Datei:** `lib/core/services/audio_player/audio_player_service.dart`
- **Problem:** Pure Helpers leben auf einer Notifier-Klasse, was unübersichtlich ist.
- **Fix-Vorschlag:** In eigene `lib/core/services/audio_player/audio_player_utils.dart` extrahieren.
- **Effort:** 15 min — Style-only.

### P-1a-11 — TrackingObserver: `null` Route-Names werden stumm verworfen
- **Datei:** `lib/core/router/tracking_observer.dart`
- **Problem:** Imperatively gepushte Routes (Dialoge, Bottom-Sheets) haben `RouteSettings.name == null` und feuern kein page_view. Funktional gewünscht, aber ohne Kommentar wirkt es wie ein Bug.
- **Fix-Vorschlag:** One-liner Kommentar im Code dass das Absicht ist.
- **Effort:** 2 min

---

## Sprint 1b — Push Foundation (TBD)

(noch leer — wird beim Sprint-Start gefüllt)

---

## Sprint 2a — Repository-Bypass-Refactor (Existing Repos) (2026-06-26)

Bezug: `docs/superpowers/plans/2026-06-22-sprint-2a-repo-migration.md`, finaler Code-Review.

### P-2a-1 — `getChildrenForParent` doc-comment kann das `isFilter('pending', null)` Pattern klarer dokumentieren
- **Datei:** `lib/data/repositories/player_repository.dart` (~Zeile 172)
- **Problem:** Doc-Comment sagt "Filters out pending and left players", was Leser zu `pending = false` führt — tatsächlich nutzt der Code `isFilter('pending', null)` (matched `pending IS NULL`).
- **Fix-Vorschlag:** Doc-Comment präzisieren um Verwechslung zu vermeiden. Z.B. einen Satz wie "(NB: matches Ionic db.service.ts which uses `pending IS NULL`; do NOT change to `pending = false` without checking parents-portal expectations)".
- **Effort:** 5 min

### P-2a-2 — Inkonsistenz `getChildrenForParent` vs. `getPlayersByParentId`
- **Datei:** `lib/data/repositories/player_repository.dart`
- **Problem:** Beide Methoden filtern `pending` unterschiedlich: `getChildrenForParent` nutzt `isFilter('pending', null)` (matched NULL), `getPlayersByParentId` nutzt `pending = false`. Beide existierten vor Sprint 2a und wurden nur portiert.
- **Fix-Vorschlag:** Klären welche Semantik korrekt ist (vermutlich `pending = false`), beide angleichen. Dabei prüfen welche Pages welche Methode aufrufen und ob das Verhalten ändern darf.
- **Effort:** 1h (Untersuchung + Migration + Tests)

### P-2a-3 — `recalculatePercentage` fire-and-forget
- **Datei:** `lib/features/attendance/presentation/pages/attendance_detail_page.dart` (in `_savePersonStatus`)
- **Problem:** `ref.read(attendanceNotifierProvider.notifier).recalculatePercentage(...)` wird ohne `await` aufgerufen — pre-existing, nicht durch Sprint 2a verursacht.
- **Fix-Vorschlag:** Entweder awaiten und Loading-State zeigen, oder explizit dokumentieren dass es fire-and-forget ist.
- **Effort:** 15 min

### P-2a-4 — `attendance_detail_page` Realtime-Channel-Cleanup in `dispose()`
- **Datei:** `lib/features/attendance/presentation/pages/attendance_detail_page.dart` (`_unsubscribeFromRealtimeChanges`)
- **Problem:** `ref.read(supabaseClientProvider)` in `dispose()` ist riskant wenn der ProviderContainer schon abgebaut ist. Pre-existing.
- **Fix-Vorschlag:** Wird automatisch durch Sprint 2c gelöst (Realtime kommt in Repository), kein separater Fix nötig.
- **Effort:** 0h (passiert in Sprint 2c)

### P-2a-5 — Test-Comment-Mismatch in `player_repository_test.dart:188`
- **Datei:** `test/data/repositories/player_repository_test.dart` (~Zeile 188)
- **Problem:** Comment sagt "must exclude pending players", asserted aber `isFilter('pending', null)`. Code ist korrekt (matches `pending IS NULL`), aber Comment ist missverständlich.
- **Fix-Vorschlag:** Comment präziser machen: `"must keep historic isFilter('pending', null) semantics — i.e. only non-pending rows where pending column is null"`.
- **Effort:** 2 min

---

## Konvention für die Abarbeitung

1. **Sprint 13 (Long Tail)** zieht alle hier gelisteten Findings ein und bündelt sie zu PRs nach Datei/Bereich.
2. **Opportunistisch:** Wenn ein laufender Sprint sowieso eine der genannten Dateien anfasst, polish-Items aus diesem Backlog mitnehmen und hier durchstreichen.
3. **Eskalation:** Wenn ein Finding sich als kritischer herausstellt (Production-Bug-Report etc.), in den nächsten regulären Sprint hochziehen statt hier zu warten.
