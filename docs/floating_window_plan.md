# Food Locker — Floating Bite Button Plan

A phased plan to let you log bites **from a floating window on top of other
apps** — a small draggable puck that logs a bite on tap and shows the current
pacing zone as its colour, so you can keep counting while you use the phone for
something else.

> **Status: ready to build.** Nothing here is built yet, but the scope (§1) and
> design decisions (§6) are settled — implementation can start at Phase 1.
>
> **Android-only, device-verified.** This rides Android's "Display over other
> apps" overlay; iOS has no equivalent third-party API and is a non-goal (§1). The
> overlay and its permission cannot run under `flutter test`/CI — most of this is
> verified manually on a real device (§5).

---

## 0. Guiding principles

Carried over from the bite feature (`bite_pacing_plan.md` §0), and they still hold
inside the overlay:

- **Store facts, derive views.** The floating button logs the same raw `at_ms`
  bite the main screen does, into the same append-only `bites` store. It persists
  nothing new; the pacing zone it paints is a **read-time projection** of the last
  bite and the effective thresholds, exactly as `BiteManager` derives it.
- **Bite count is the headline metric, and logging never blocks.** A tap on the
  puck records a bite immediately, same contract as the main button.
- **Reuse the pacing model.** `PacingZone`, `PacingConfig` (`b1`/`b2`), and
  `PacingZoneStyle` already define the zones and their colours. The overlay reuses
  them rather than inventing a second pacing rule.
- **Minimal footprint.** The overlay is a puck, not the page. It owns no wake-lock,
  no countdown text, no count, no haptics — just the tap target and its colour.

---

## 1. What it is (v1 scope)

A **floating circular bite button**, drawn over whatever app is in front:

- **Tap = one bite**, written immediately to the shared bite store.
- **Fill colour = the current pacing zone** (`tooSoon` / `holdOn` / `inTheClear`),
  from `PacingZoneStyle`. Because the zone advances with time since the last bite,
  the overlay runs a small local ticker that recomputes the colour between taps —
  the same derivation `BiteManager` does, minus the wake-lock and countdown.
- **Draggable**, so it can be parked out of the way, with a **small ✕** to dismiss
  it.

Explicitly **out of scope for v1** (kept on the main page only): the running
count, the countdown seconds, the "in the clear" haptic, and the wake-lock — a
floating window means the phone is already in use, so the screen won't sleep.

**iOS: non-goal.** No system-wide floating overlay exists for third-party iOS
apps. The launch control (§4) is Android-only and hidden elsewhere.

---

## 2. Same app, second engine — what's reused vs re-created

**This is not a new app.** The overlay lives in the same APK and reuses the code
we already have — `PacingZone`, `PacingConfig`, `PacingZoneStyle`, the
`BiteDatabase`, `DriftBiteRepository`, and `logBite`. The *only* thing it can't
reuse is a **live in-memory object**: `flutter_overlay_window` renders the puck
from a second Flutter entrypoint running in its own isolate, and isolates don't
share memory, so the overlay can't grab the already-running `BiteManager` /
`Provider` instance the main screen uses.

The practical consequence is small — instead of reading a repository out of a
`Provider`, the overlay **re-creates the thin data layer** (a `DriftBiteRepository`
over the *same* on-disk database) and derives pacing with the same calls:

- A dedicated `@pragma('vm:entry-point')` `overlayMain()` boots a minimal
  `MaterialApp` whose only content is the puck — built from the existing widgets
  and models, not new ones.
- The puck reads/writes the **store directly** through its own repository, not
  through `BiteManager`.
- The main app and the overlay stay in sync through the **shared database on disk**
  (the same SQLite file), not through shared memory.

---

## 3. Data path — the overlay writes to the store directly

The overlay must work even when the main app is backgrounded or reclaimed by the
OS, so it **opens its own connection to the same `bites` database** and writes
there directly, rather than messaging a main isolate that may not be alive.

- **Reuse, don't fork, the data layer.** The overlay constructs its own
  `BiteDatabase` / `DriftBiteRepository` and calls the existing
  `logBite(now)` / `lastBite()` / `pacingConfigAt(now)`. Pacing colour comes from
  `PacingZone.forElapsed(sinceLastBite, b1, b2)` — the same call `BiteManager`
  makes. No new persistence, no schema change.
- **Sync back on resume.** Bites logged while floating land in the same file, so
  the main `BiteManager` must **re-read on `AppLifecycleState.resumed`** to pick up
  what the puck logged (today's count, the seeded last-bite reference). Optionally
  the overlay also posts a lightweight "bite logged" message
  (`FlutterOverlayWindow.shareData`) so a foreground main page updates live.
- **De-risk first (spike, Phase 1).** Two Drift connections on one SQLite file is
  the one genuinely uncertain piece: the second engine re-runs `beforeOpen`
  seeding (idempotent — a no-op once a config row exists) and needs WAL journal
  mode for safe concurrent access, and `drift`/`sqlite3` native access must work
  inside the overlay isolate's plugin registrant. A small spike validates this
  before any UI is built on top of it.

---

## 4. Permission, launch, and lifecycle

Standard "draw over other apps" plumbing, plus a launch control on the Bite tab:

- **Permission.** Add `SYSTEM_ALERT_WINDOW` (and the foreground-service entries the
  plugin requires) to `AndroidManifest.xml`. At launch time, check
  `FlutterOverlayWindow.isPermissionGranted()` and, if not, send the user to the
  system grant screen via `requestPermission()`.
- **Launch control.** A "Float" / pop-out action on the Bite tab (an app-bar
  `IconButton`, gated to `Platform.isAndroid`) checks the permission, then
  `showOverlay(...)` with `enableDrag: true`. Closing is `closeOverlay()`, driven
  by the puck's close gesture.
- **Foreground service & SDK.** The plugin backs the overlay with a foreground
  service (its own notification). Confirm the app's `minSdk` meets the plugin's
  floor and bump it in `android/app/build.gradle.kts` if needed; add any
  `FOREGROUND_SERVICE` / service-type entries the plugin's setup calls for.

---

## 5. Testing reality

Be honest about verification, because this repo leans on CI:

- **CI can build and `flutter analyze`** the new code, and **`flutter test`** the
  parts that don't need the overlay.
- **The overlay itself is device-only.** The floating window, the permission
  grant, and the cross-isolate store access can't be exercised in `flutter test` —
  they're verified **manually on a real Android device**.
- **Keep the testable core pure.** The pacing-zone-from-last-bite derivation and
  the bite-logging path are plain Dart over the repository, unit-testable without
  the overlay; lean on that so the untestable surface is just the thin overlay UI
  and the platform plumbing.

---

## 6. Settled decisions

1. **v1 is a bare button that changes colour** — tap to log, fill = pacing zone.
   No count, no countdown, no haptic, **no wake-lock** (a floating window means the
   phone is already awake and in use).
2. **Built with `flutter_overlay_window`** (a second Flutter entrypoint), not a
   hand-written native overlay service.
3. **The overlay writes to the store directly** through its own `BiteDatabase`
   connection, so it works with the main app backgrounded; the main page re-reads
   on resume (§3).
4. **Reuse the existing pacing model** (`PacingZone`, `PacingConfig`,
   `PacingZoneStyle`) — one pacing rule across the main button and the puck.
5. **Android-only.** The launch control is hidden on non-Android; iOS is a non-goal.

---

## 7. Phases

Each phase is one sitting on a single subject and is independently committable.
Where a phase has testable logic it ends **green** (`flutter analyze` +
`flutter test`); the overlay-dependent bullets are verified manually on a device
(§5). The uncertain cross-isolate store access is spiked in Phase 1 before any UI
is built on it.

**Phase 1 — Isolate-safe bite core + cross-connection spike**

De-risk the one uncertain piece and pin down the shared logging/pacing path.
- [ ] Spike: open a second `BiteDatabase` connection to the same `bites` file from
      a separate isolate/engine, confirm a direct `logBite` write is visible to the
      main connection, and confirm `drift`/`sqlite3` works in that engine; enable
      WAL journal mode if not already on
- [ ] Confirm the shared path — construct `DriftBiteRepository` standalone (no
      `Provider`) and derive the pacing zone via
      `PacingZone.forElapsed(sinceLastBite, b1, b2)` off `lastBite()` +
      `pacingConfigAt(now)`
- [ ] **Verify:** unit-test the pacing-zone-from-last-bite derivation (too-soon /
      hold-on / clear boundaries) as pure logic; the spike's two-connection write
      is confirmed on a device

**Phase 2 — Overlay entrypoint + the floating pacing button**

The puck itself, in its own engine.
- [ ] Add `flutter_overlay_window`; add the `SYSTEM_ALERT_WINDOW` /
      foreground-service entries to `AndroidManifest.xml`; bump `minSdk` if the
      plugin needs it
- [ ] Add the `@pragma('vm:entry-point')` `overlayMain()` booting a minimal
      `MaterialApp` with a circular bite button: fill from `PacingZoneStyle`, a
      local ticker recomputing the zone between taps, tap → `logBite(now)` through
      the overlay's own repository
- [ ] Draggable puck with a small ✕ to dismiss (→ `closeOverlay()`)
- [ ] **Verify (device):** the puck floats over other apps, taps log bites, and
      the colour advances through the zones over time; `flutter analyze` /
      `flutter test` pass

**Phase 3 — Launch/permission flow + resume sync**

Wire it to the app.
- [ ] A `Platform.isAndroid`-gated "Float" action on the Bite tab that checks
      `isPermissionGranted()` / `requestPermission()` then `showOverlay(...)`
- [ ] Refresh `BiteManager` on `AppLifecycleState.resumed` so bites logged while
      floating show up on return (optionally an overlay→app `shareData` message for
      a live foreground update)
- [ ] **Verify (device):** grant flow works; start/stop from the Bite tab; a bite
      tapped on the puck is reflected in the main count after returning;
      `flutter analyze` / `flutter test` pass

**Phase 4 — Polish**
- [ ] Edge cases (permission denied, overlay already showing, rapid taps); puck
      theming/size and an accessibility label; a short note in `CLAUDE.md`/README on
      the overlay permission; final `flutter analyze` / `flutter test` pass before
      pushing
