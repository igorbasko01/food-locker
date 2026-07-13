# Food Locker — Bite Counting & Pacing Plan

A phased plan to add bite counting and timer-based pacing to Food Locker.

---

## 0. Guiding principles

Keep these in view — they are the reasons behind every decision below.

- **Adherence beats accuracy.** Every tool in this space dies from people quitting, not from
  a missed tap here and there. Optimize for something you'll actually use every meal.
- **Store facts, derive views.** Persist raw bite timestamps only. Delta, zone, and pacing score
  are all read-time projections of the timestamps — never stored.
- **Feedback, not lockout.** Logging a bite is never blocked. Pacing pressure is communicated,
  not enforced, so the timestamp data stays honest.
- **Bite count is the headline metric.** Total bite count per day is the number to surface and
  track. Count it accurately and make it visible.
- **Pacing is the other half.** Slowing the *rate* of bites — the zones and timer — lets satiety
  catch up so you feel as full sooner. Counting and pacing are the two things the app does.

---

## 1. Storage architecture

Leave the existing weight/food data exactly where it is on the current Hive store — untouched —
and introduce Drift for the new bite data only.

### 1a. Drift for the bite log

New data only — greenfield, no legacy. Its query shape — time-window ranges and weekly pacing
aggregates — is a SQL sweet spot: ranges and aggregates are a
`WHERE`/`GROUP BY` instead of loading a box and scanning in Dart. That query shape is the reason
to give the bite data its own SQL-backed store rather than another Hive box.

The bite log is isolated enough that if Drift doesn't pan out, the blast radius is one small
subsystem.

`build_runner` is already in your pipeline, so Drift's codegen adds a builder, not a new tooling
paradigm.

### 1b. Repository seam (the guardrail that makes two stores safe)

Put an interface in front of each dataset so the rest of the app never knows which engine backs
which:

```dart
abstract interface class BiteRepository {
  Future<void> logBite(DateTime at);
  Future<Bite?> lastBite();                          // reference point for the pacing ticker
  Future<List<Bite>> bitesInRange(DateTime from, DateTime to);
  Future<int> biteCount(DateTime from, DateTime to); // the headline metric
  Future<void> setPacingConfig(PacingConfig cfg);    // appends a config-change marker
}

abstract interface class WeightRepository { /* backed by Hive */ }
```

Benefits: engine choice stays an implementation detail the rest of the app is insulated from;
the two stores are independently testable; and it gives you one place to coordinate the
two-store tax below.

### 1c. The two-store tax — budget for it

Two persistence stacks mean two init paths, two test setups, and — the real one — two code paths
anywhere you touch "all the data." Your existing export/backup/import flows (`csv`, `archive`,
`share_plus`, `file_picker`) now span both stores. **Export everything**, **restore from backup**,
and **wipe my data** all become two-store operations. Route them through the repositories so
there's a single coordination point. This is manageable but underestimated.

For backup specifically: extend the existing **CSV export** to include the bite data, and support
**importing that CSV back into the SQLite (Drift) store** — both routed through the repository seam.

Cross-store analytics (e.g. pacing vs. weight trend) become a Dart-side join across engines —
fine, because it's an occasional tiny analytical read.

---

## 2. Data model (Drift)

### 2a. Bite log — append-only timestamp stream

The atomic fact is a millisecond timestamp. Store the raw log only; every view — counts, deltas,
pacing — is derived at read time, so storing raw keeps future options open with zero data loss.

```
bites
  id            INTEGER PK AUTOINCREMENT   -- insertion order == chronological (append-only)
  at_ms         INTEGER  NOT NULL  INDEXED -- epoch millis, ms precision
  -- nothing else stored; delta and zone are derived
```

Millisecond precision is cheap and keeps the inter-bite deltas exact.

Store `at_ms` as a plain `integer()` (epoch millis) — **not** Drift's `dateTime()` type, whose
default mode stores unix *seconds* and would silently truncate the millisecond precision. Epoch
integers keep deltas a trivial subtraction and stay DST-safe (a UTC instant, monotonic across
midnight and clock changes). Storing integer costs nothing for date-by-day queries — SQLite's date
functions work on epoch values via the `unixepoch` modifier:

```sql
-- bites per calendar day (local)
SELECT date(at_ms / 1000, 'unixepoch', 'localtime') AS day, COUNT(*) AS bites
FROM bites
GROUP BY day;
```

### 2b. Pacing config — versioned thresholds

A bite's pacing score depends on the thresholds in effect *when it happened*, so those thresholds
are versioned (a slowly-changing dimension): retuning them later must not silently re-grade past
bites and contaminate longitudinal comparisons.

Three fixed zones means exactly two boundaries — so two columns, no separate boundaries table:

```
-- one row per config version (SCD)
pacing_config
  id            INTEGER PK AUTOINCREMENT
  effective_ms  INTEGER NOT NULL   -- epoch millis: instant this version took effect
  b1_s          INTEGER NOT NULL   -- end of "too soon"          (seconds)
  b2_s          INTEGER NOT NULL   -- start of "in the clear" — ok to bite (seconds)
```

The three zones are the ranges the two boundaries cut: `[0, b1)` too soon, `[b1, b2)` ok — hold on,
`[b2, ∞)` in the clear. `b2` — where "in the clear" begins and the haptic fires — is the point at
which the app recommends it's ok to take the next bite; it's derived, not stored.

Units follow the bite-log rule: `effective_ms` is an *instant* (epoch millis); `b1_s` and `b2_s`
are *durations* (seconds). Compare a delta in ms against `b_s * 1000`.

If thresholds never change, `pacing_config` holds one row. If they do, any historical bite's zone is
still reconstructable from the version effective at its timestamp, and you know which date ranges
are validly comparable.

---

## 3. Pacing feature — behaviour

### 3a. Bite logging

- One tap = one bite. The tap **records `at_ms` immediately**, always. Never blocked.

### 3b. Pacing visualization (derived, never stored)

The timer is a **feedback metronome**, not a gate and not a measurement. Zones express *how costly
it is to bite right now*, decreasing to zero once you're in the clear — so the colour never falsely
green-lights an early bite:

| Time since last bite | Zone | Colour | Message |
|---|---|---|---|
| 0 – 15 s | too soon | red | "Too soon — keep chewing" |
| 15 – 30 s | ok — hold on | amber | "Almost — hold on a moment" |
| 30 s+ | in the clear | green | "You're in the clear" |

- **The live view is clock-driven, not data-driven.** The zone is a function of
  `now − lastBiteTimestamp`, which changes with wall-clock time, so a local ticker
  (`Timer.periodic`, ~200–500 ms) rebuilds it from the last-bite time held in memory. The database
  is touched only to seed that reference on the first bite of a session (`lastBite()`).
- **The ticker runs only while the countdown matters.** It's born on a tap and counts up through
  the zones; when the gap reaches `b2` it fires the haptic, freezes the view on a static "in the
  clear" state, and cancels itself — no periodic work runs between reaching clear and the next
  bite. The next tap resets the reference and restarts it. On screen open with no recent bite (last
  bite already past `b2`, or none), it shows the static clear state with no ticker running.
- **Haptic tick when you reach `b2`** so you can watch your plate / your kids, feel the buzz,
  and know you're clear — not stare at the phone between bites.
- In-zone encouragement is about *chewing* ("keep chewing, pacing well"), never a readiness cue.
  Reaching `b2` is the only readiness signal.
- The boundaries, colours, and messages above are v1 starting values (`b1 = 15 s`, `b2 = 30 s`,
  where `b2` is the point at which biting is recommended). Both boundaries are **configurable** per
  `pacing_config` version; consider a lower `b2` to start and ramp up to protect adherence.
- Freezing the view and stopping the ticker at `b2` is **display/compute only** — timestamp logging
  never stops. A bite 90 s after the previous one is logged like any other; the 90 s isn't stored,
  it's just the gap derived between the two timestamps (a well-paced bite, or a long pause before
  the next).

### 3c. Read-time query

The only value derived from the stored log is the count:

- `biteCount(window)` — total bites for a local day; the headline count shown on the main screen.

---

## 4. Tasks

Each phase is one sitting on a single subject. Phases are ordered so each assumes the earlier
ones; beyond that they're independent.

**Phase 0 — Hive → Hive CE migration (unblocks latest Drift)**

The existing store is generated by `hive_generator`, which caps `analyzer` at `<7.0.0`. On the
current Dart SDK, the analyzer versions Drift's codegen (`drift_dev`) needs sit *above* that cap —
so adding Drift alongside the legacy generator forces either an old, pinned Drift with a
hand-written database connection, or a resolver dead-end. Migrating the existing Hive layer to the
maintained community fork **Hive CE** (`hive_ce`) frees the `analyzer` constraint so Drift can be
added later at its latest version with no pinning and no custom connection code. Hive CE is
binary-compatible and keeps the same `typeId`s, so existing user boxes stay readable — this is a
tooling swap, not a data migration.
- [x] Swap `hive`/`hive_flutter`/`hive_generator` for `hive_ce`/`hive_ce_flutter`/`hive_ce_generator`
- [x] Repoint imports; keep the classic `@HiveType`/`@HiveField` annotations and `typeId`s untouched
- [x] Regenerate adapters; register via the generated `hive_registrar.g.dart` (`Hive.registerAdapters()`)
- [x] Verify a `Weight` round-trips through a real on-disk box (adapters + binary format intact)

**Phase 1 — Drift setup + `bites` table**
- [x] Add Drift deps (`drift`, `drift_flutter` or `sqlite3_flutter_libs`, dev `drift_dev` + `build_runner`)
- [x] Define the database class and connection
- [x] Define `bites`: `id` autoincrement, `at_ms` plain `integer()` (epoch millis), indexed
- [x] Run codegen; confirm the DB opens and a row round-trips

**Phase 2 — `pacing_config` table + default**
- [x] Define `pacing_config`: `effective_ms`, `b1_s`, `b2_s`
- [x] Seed a default row on first run (`b1 = 15`, `b2 = 30`)
- [x] Add a helper to read the config effective at a given instant

**Phase 3 — `BiteRepository`**
- [x] Define the interface: `logBite`, `lastBite`, `bitesInRange`, `biteCount`, `setPacingConfig`
- [x] Implement it against Drift
- [x] Expose it through `provider`

**Phase 4 — Bite logging screen (the main screen)**
- [x] Tap button → `logBite(DateTime.now())`, recorded immediately, never blocked
- [x] Today's count (`biteCount` for the current local day), re-queried after each tap

**Phase 5 — Pacing visualization (on the same screen as the tap button)**
- [x] Local ticker (`Timer.periodic`, ~200–500 ms), started on tap, reading last-bite time from memory
- [x] Current zone from `now − lastBite` against `b1`/`b2`; colours + messages as app constants (too soon/red, hold on/amber, clear/green)
- [x] On reaching `b2`: haptic, freeze on the static "in the clear" state, cancel the ticker
- [x] Next tap resets the reference and restarts the ticker; on open with no recent bite, show the static clear state (no ticker)

**Phase 6 — CSV export**
- [x] Extend the existing CSV export to include the bite data
- [x] Route it through the repository seam so one call spans both stores

**Phase 7 — CSV import**
- [x] Parse the bite CSV back into the SQLite (Drift) store
- [x] Route through the repository seam; validate / dedupe on import

---

## 5. Follow-up tasks

Refinements to the shipped feature, ordered independently — each is a small, self-contained
change to the existing Bite screen and app shell.

**Phase 8 — Reorder the Bite tab**

The Bite tab currently sits first in the bottom navigation. Move it so the tab order reads
**Home, Weight, Bite, Settings** — Bite becomes the third tab.
- [x] Reorder the tabs in `AppShell` so Bite is third (Home, Weight, Bite, Settings)
- [x] Update the matching `IndexedStack` children and any tab-index constants/defaults so the
      selected index still maps to the right page
- [x] Confirm the default landing tab is still the intended one after the reorder (now Home —
      index 0 — matching the pre-bite landing tab)

**Phase 9 — Center the Bite screen content**

The Bite screen content is currently left-justified; it should be horizontally centered.
- [x] Center the Bite screen's content horizontally (explicit `CrossAxisAlignment.center` on the
      column plus `TextAlign.center` on the loose labels), matching the layout intent of the
      other tabs
- [x] Verify the tap button, count, and pacing message all read as centered

**Phase 10 — Elapsed-time timer up to the clear threshold**

Alongside the pacing zone message, show a live timer counting the time elapsed since the current
bite started, running up until the "in the clear" (`b2`) threshold is reached — at which point the
timer disappears.
- [ ] Render an elapsed-time readout next to the pacing message, driven by the same clock ticker
      (`now − lastBite`) already rebuilding the zone
- [ ] Count up from the bite instant; hide the timer once the gap reaches `b2` (the "all good"
      threshold), consistent with the ticker freezing/cancelling at `b2`
- [ ] On screen open with no recent bite (already past `b2`, or none), show no timer

**Phase 11 — Export/import the `pacing_config` table**

Backup currently exports only `bites.csv` (raw `at_ms` timestamps); the `pacing_config`
table — the versioned thresholds — is left out, so a restore loses the config history and any
historical bite's zone can no longer be reconstructed (§2b). Extend the backup to carry it too.
- [ ] Add a per-store CSV entry for the pacing config (e.g. `pacing_config.csv` with
      `effective_ms`, `b1_s`, `b2_s`, one row per version), following the `BiteBackupCodec` /
      `bites.csv` pattern
- [ ] Have `SerializationService` pack it into the same archive and route it through the
      repository seam on both export and import
- [ ] On import, replace/merge the config versions consistently with how bites are restored;
      preserve the null-vs-empty semantics for older archives that lack the entry (leave existing
      config untouched when absent)
- [ ] Ensure a default config still seeds correctly when restoring a pre-config backup
