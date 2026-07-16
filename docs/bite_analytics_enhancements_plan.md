# Food Locker — Bite Analytics Enhancements Plan

A follow-up to `bite_analytics_plan.md` (now shipped) adding three refinements
across the Bite tab and its analytics screen:

1. **Average meal size** over the last 30 days, as a new stat tile.
2. **A pickable breakdown day** — tapping a bar in the daily-bites chart switches
   the meal-breakdown card below it to that day.
3. **Current-meal bites on the main Bite page** — the in-progress meal's running
   count, alongside the day's headline total.

> **Status: ready to build.** Nothing here is built yet, but every design
> decision (§6) is settled — implementation can start at Phase 1.

---

## 0. Guiding principles

Unchanged from `bite_analytics_plan.md` §0 and `bite_pacing_plan.md` §0, and they
still constrain every decision here:

- **Store facts, derive views.** The `bites` table stays an append-only log of
  raw `at_ms` timestamps. Average meal size, the current-meal count, and every
  breakdown are **read-time projections** of that log. No schema change, no
  migration, nothing new persisted.
- **Bite count is the headline metric.** The new numbers elaborate on the count;
  they never compete with it.
- **Reuse the settled meal model.** "Meal", "snack", `mealGapThreshold` (5 min),
  and `minMealBites` (10) already live on `BiteAnalytics` (§2 of the analytics
  plan). Both feature 1 and feature 3 build on those exact definitions rather
  than introducing a second clustering rule.
- **Local-day granularity, DST-safe.** Days are calendar days in the device's
  local zone, bounded by `[startOfDay, startOfNextDay)` and built with the
  `DateTime(y, m, d ± 1)` idiom — never fixed 24-hour arithmetic.

---

## 1. Average meal size (last 30 days)

### 1a. What it is

The mean number of bites in a **meal** — a qualifying cluster of `≥ minMealBites`
bites — across the last 30 days. Snacks (sub-`minMealBites` clusters) are excluded
by definition, so this measures the size of actual meals, not of all eating.

`averageMealSize = Σ(bites in meals over the window) / (number of meals)`

Returns `0` when the window holds no meal, mirroring how `averagePerDay` and
`averageMealsPerDay` treat an empty window (rendered as `—`).

### 1b. Where it lives

A new method on `BiteAnalytics` (`lib/features/bite/data/bite_analytics.dart`),
built from the same per-day clustering the class already does for
`averageMealsPerDay`:

```dart
/// Mean bites per meal over `[from, to)` — total bites in qualifying meal
/// clusters divided by the number of those clusters. Snacks are excluded.
/// Returns 0 when the window holds no meal.
Future<double> averageMealSize(DateTime from, DateTime to);
```

`averageMealsPerDay` already clusters each day and counts the meals; this reuses
that traversal, summing meal *bites* as well as counting meals. Factor the shared
"meal clusters across a window" walk into one private helper so the two methods
can't drift apart.

### 1c. UI

The meals summary row (`_MealsSummaryRow` in `bite_analytics_page.dart`) grows
from two tiles to three — **Meals today**, **30-day avg meals**, **30-day avg
meal size** — matching the three-across `_StatTilesRow` above it. The controller
gains `averageMealSizeLast30`, loaded over the same `from30 … to` window the other
30-day metrics already use.

---

## 2. Pickable breakdown day

### 2a. What changes

Today the breakdown card is pinned to today (`breakdownToday`). This makes the
day **selectable**: tapping a bar in the daily-bites chart selects that calendar
day, and the breakdown card re-queries and re-renders for it. Today stays the
default selection on open, and a control returns to today after browsing.

No new analytics: `BiteAnalytics.breakdownForDay(day)` already takes any day.
This is a controller + chart-wiring change.

### 2b. Controller

`BiteAnalyticsController` replaces the fixed `breakdownToday` with a selected-day
model:

```dart
DateTime get selectedDay;             // defaults to today
bool get isSelectedDayToday;          // drives the "back to today" affordance
DayMealBreakdown get selectedBreakdown;
Future<void> selectDay(DateTime day); // re-queries breakdownForDay, notifies
```

`selectDay` normalises to local midnight, sets a per-card loading flag, awaits
`breakdownForDay`, and notifies — so re-selection never blocks the rest of the
screen. The initial `load()` seeds `selectedDay = today`. `mealsToday` and the
30-day tiles are unaffected — they stay today/window metrics.

### 2c. Chart

`DailyBitesChart` gains two optional parameters, staying a stateless widget:

```dart
final DateTime? selectedDay;              // highlighted bar
final ValueChanged<DateTime>? onDaySelected;
```

- **Selection** rides `BarTouchData.touchCallback`: on a tap-up event, map
  `group.x` back to its calendar day (the same `firstDay + index` arithmetic the
  tooltip and axis labels already use) and call `onDaySelected`.
- **Highlight** the selected bar so the link to the card below is visible — e.g. a
  border or a full-opacity rod even when it's below the 40 line — without losing
  the existing muted/threshold treatment.
- The existing tooltip stays; tapping both shows the tooltip and selects the day.

### 2d. Card

`_MealBreakdownCard`'s title becomes the selected date (through the shared
locale-aware date helper from §4 — `14/7` or `7/14` per the phone; "Today's meals"
when it's today), with a small "Back to today" action shown only when
`!isSelectedDayToday`. The card keeps its own empty state for a selected day with
no bites.

---

## 3. Current-meal bites on the main Bite page

### 3a. What it is

Under "Today's Bites", show the number of bites in the **current meal** — the
trailing cluster of today's bites whose consecutive gaps are `≤ mealGapThreshold`
(5 min), using the same rule as the analytics meal model. It answers "how much
have I eaten *this* sitting?" next to the all-day total.

Shown only while a meal is **actually in progress**: if the most recent bite is
more than `mealGapThreshold` ago, the sitting has ended and the line is hidden —
so opening the app hours after a meal shows nothing rather than a stale count.

No `minMealBites` gate applies to the live count — it counts from the first bite
of the sitting, before the cluster is big enough to have "qualified" as a meal in
the analytics sense.

### 3b. Where it lives — derived, not counted

`BiteManager` already re-reads today's bites and refreshes `_todayCount` after
every mutation. The current-meal size follows the exact same pattern: it's
**recomputed from today's stored bites**, not tracked with a running counter.

```dart
/// Bites in the current meal, or 0 when no meal is in progress. Recomputed from
/// the store alongside [todayCount]: the size of the trailing run of today's
/// bites no more than [BiteAnalytics.mealGapThreshold] apart — but only when the
/// most recent bite is within that threshold of now. A last bite older than the
/// threshold means the sitting has ended, so this reads 0.
int get currentMealBites;
```

- **On `logBite` and `initialize`** (every refresh that recomputes the day
  count): first gate on recency — if the most recent bite is more than
  `mealGapThreshold` ago, `currentMealBites` is 0. Otherwise cluster today's bites
  by the `mealGapThreshold` rule and take the trailing cluster's size. It's folded
  into the same refresh, off one read of today's bites — there is no increment/
  reset arithmetic and no `_currentMealCount` state to keep in sync; the number is
  always a projection of the log.
- Reuse the meal-clustering already in `BiteAnalytics` (extract its private
  `_clusterBites` / `mealGapThreshold` into a shared spot) so the live count and
  the analytics screen apply one identical rule.

Because it's recomputed from the log, resetting is automatic: a just-logged bite
(`lastBite == now`) always shows and starts a fresh trailing cluster of size 1
after a `> mealGapThreshold` gap, while opening the app long after the last bite
shows nothing.

### 3c. UI

`bite_page.dart` shows the count as a quiet secondary line under the big day total
(e.g. "This meal: N"), rendered only when `currentMealBites > 0` so an empty day
stays clean. It reads `biteManager.currentMealBites`; no new provider.

**Bite-driven caveat (settled, §6.4):** the recency gate is evaluated when the
manager recomputes — on a bite or on open — not on a timer. So opening the app
after a meal ended correctly shows nothing, but if you sit on the Bite page and
the 5-min mark passes with no new bite, the line only clears on the next refresh
(a bite, a tab switch, or reopening the tab), since no ticker runs past `b2`
(~30 s). A timer to blank it at the exact 5-min boundary is out of scope for v1.

---

## 4. Locale-aware dates in charts and stats

### 4a. What changes

Every date drawn on a chart or a stat is currently hardcoded to US month/day
order — `'${day.month}/${day.day}'` on the axes and the max-day tile, ISO
`year-month-day` in the tooltips. This makes the numeric dates follow the
**device locale's** ordering instead (`14/7` vs `7/14`) — still numbers, no month
names, just the order the phone uses.

Sites in scope (charts + stats only):

- `daily_bites_chart.dart` — the x-axis day labels and the touch tooltip.
- `weight_chart.dart` — the x-axis day labels and the touch tooltip.
- `bite_analytics_page.dart` — `_formatDay` (the 30-day-max stat tile's date).
- The pickable-day card title from §2d.

**Out of scope, left as-is:** the full ISO dates in the weight history list, the
add-weight dialog, and the home-tab day header (ISO `yyyy-mm-dd` is
order-unambiguous), and the backup filename timestamp in `serialization_service.dart`
(it must stay a stable, sortable format — never localised).

### 4b. How

The app wires no `Localizations` delegates, so `Localizations.localeOf(context)`
would always resolve to the fallback locale. Read the real device locale directly
instead, and format through `intl`:

- Add `intl` to `pubspec.yaml` (not currently even a transitive dependency) and
  call `initializeDateFormatting()` once at startup in `main.dart`.
- One shared helper in `lib/core/` (beside `csv_serializer.dart`): `shortDate`
  (`DateFormat.Md` — numeric month/day in locale order) for axis labels and tiles,
  and `fullDate` (`DateFormat.yMd`) for tooltips, both formatting against
  `PlatformDispatcher.instance.locale`. Every in-scope site calls this one place,
  so ordering can never drift between the two charts and the tile again.

---

## 5. Body weight on the bite chart

### 5a. Shape — grouped bars

`fl_chart` renders side-by-side bars out of the box: a `BarChartGroupData` holds a
*list* of `BarChartRodData` in `barRods`, drawn grouped per x. The daily-bites
chart uses one rod today; a second rod per day is the weight bar, in a distinct
colour with a two-entry legend.

### 5b. The scale still needs a second axis

Two bars don't close the unit gap: bites are a count (0–~150) and weight is kg in
a narrow band far from zero (e.g. 72–96). Drawn from zero on the shared bite axis,
every weight bar is a near-identical tall block and the day-to-day change — the
whole point of overlaying it — is invisible. So the weight rod is mapped onto a
**secondary right-hand axis** fitted to the weight's own min/max (±~1 kg padding,
as `weight_chart.dart` does): its `toY` is normalised into the bar chart's Y
range, and the right axis (`rightTitles`, hidden today) is labelled in kg by
inverting that mapping. Left axis = bites, right axis = kg, one grouped bar each.

### 5c. Data + wiring

`BiteAnalyticsController` gains a `WeightRepository` (already provided in
`main.dart`; inject it alongside the bite repo) and loads **raw daily weights**
over the same 30-day window via `getAllWeights()` filtered to `[from30, to)`.
Weight is day-granular, so it aligns one-to-one with the bite days. A day with a
weigh-in but no bites still shows its weight bar; a day with no weigh-in shows only
the bite bar — no gap-filling, raw values as decided. Weight stays in kg.

Density note: two rods per day over 30 days is tight, so each rod is drawn at
roughly **half** the current single-rod width to fit both. The 30-day window
stays as is.

---

## 6. Settled decisions

All confirmed — these fix the behaviour on screen:

1. **Avg meal size counts only qualifying meals** (`≥ minMealBites`), excluding
   snacks, and is shown as a whole number of bites. `—` when the window has no
   meal.
2. **Breakdown-day selection is tap-to-select on the chart**, defaulting to today,
   with an explicit "Back to today" control. The top stat tiles and "Meals today"
   stay today/window metrics — only the bottom breakdown card follows the
   selection.
3. **Current meal is derived, not counted** — recomputed from today's stored
   bites (trailing `mealGapThreshold` cluster) alongside the day count, with no
   running counter. It reuses `mealGapThreshold` (5 min) and ignores
   `minMealBites` for the live count (it counts from bite 1 of the sitting).
4. **Current meal is bite-driven, not timer-driven** — the recency check and
   recompute run on a bite or on open, not at the instant 5 min elapses; the line
   can linger past 5 min only until the next refresh (§3c).
5. **Current-meal line is hidden when no meal is in progress** — the day has no
   bites, or the most recent bite is more than `mealGapThreshold` (5 min) ago.
6. **Chart/stat dates follow the device locale**, numeric (no month names) —
   `14/7` or `7/14` per the phone — through one shared `intl` helper. Full ISO
   dates elsewhere (history list, dialogs, home header, backup filename) are left
   as-is (§4a).
7. **Weight rides the bite chart as a second grouped bar per day** (`fl_chart`
   `barRods`), on a **secondary right-hand kg axis fitted to the weight range** —
   not from zero, which would flatten the day-to-day change (§5b). Raw daily
   weights, in kg, no gap-filling.

---

## 7. Phases

Each phase is one sitting on a single subject, ends **green** (`flutter analyze`
+ `flutter test` pass), and is independently committable. Ordered so each assumes
the earlier ones; every phase ships with its tests — the "verify" bullet is the
definition of done. The shared date helper (Phase 1) lands first so the later
chart and stat phases render dates through it from the start.

**Phase 1 — Locale-aware dates in charts and stats (shared foundation)**

The cross-cutting date fix, retrofitting both features' existing charts/stats.
- [x] Add `intl` to `pubspec.yaml`; call `initializeDateFormatting()` once at
      startup in `main.dart`
- [x] Add a shared date helper in `lib/core/` — `shortDate` (`DateFormat.Md`,
      numeric month/day) for axes and tiles, `fullDate` (`DateFormat.yMd`) for
      tooltips — formatting against `PlatformDispatcher.instance.locale`
- [x] Retrofit the hardcoded month/day axis labels and ISO tooltips in
      `daily_bites_chart.dart` and `weight_chart.dart`, and `_formatDay` (the
      30-day-max tile) in `bite_analytics_page.dart`, to the helper
- [x] **Verify:** unit-test the helper renders `7/14` under `en_US` and `14/7`
      under `en_GB`; pin the locale in the existing `stat_tile_test` /
      `bite_analytics_page_test` date expectations so they stay deterministic

**Phase 2 — `averageMealSize` on `BiteAnalytics` + the stat tile**

Pure computation first, then wire it into the existing meals summary row.
- [ ] Add `averageMealSize(from, to)` to `BiteAnalytics`, factoring the shared
      "meal clusters across a window" walk out of `averageMealsPerDay` so the two
      can't diverge
- [ ] Add `averageMealSizeLast30` to `BiteAnalyticsController`, loaded over the
      existing `from30 … to` window
- [ ] Add the third tile ("30-day avg meal size") to `_MealsSummaryRow`
- [ ] **Verify:** unit-test avg meal size with snacks excluded, a window with no
      meal (0/`—`), a single meal, and multiple meals across several days; the
      tile reads correctly against a seeded fixture

**Phase 3 — Pickable breakdown day**

Chart tap drives the breakdown card; no new analytics.
- [ ] Replace `breakdownToday` with `selectedDay` / `selectedBreakdown` /
      `isSelectedDayToday` on the controller, plus `selectDay(day)` re-querying
      `breakdownForDay` behind a per-card loading flag; seed `selectedDay = today`
      in `load()`
- [ ] Add `selectedDay` + `onDaySelected` to `DailyBitesChart`: select via
      `barTouchData.touchCallback` (tap-up → `firstDay + index`), and highlight the
      selected bar
- [ ] `_MealBreakdownCard` titles the selected date and shows a "Back to today"
      control only when `!isSelectedDayToday`; keep the per-day empty state
- [ ] **Verify:** unit-test `selectDay` loads the right day's breakdown and
      `isSelectedDayToday` flips; widget-test that tapping a bar calls
      `onDaySelected` with that day and that "Back to today" resets to today

**Phase 4 — Current-meal bites on the Bite page**

- [ ] Extract the meal-clustering rule (`_clusterBites` / `mealGapThreshold`) from
      `BiteAnalytics` into a shared spot so the manager and the analytics screen
      apply one identical rule
- [ ] Add `currentMealBites` to `BiteManager`, **recomputed** from today's bites
      (trailing `mealGapThreshold` cluster) in the same refresh that recomputes the
      day count, gated on recency — 0 when the most recent bite is more than
      `mealGapThreshold` ago; no running counter, no `initialize` special-casing
      beyond that refresh
- [ ] Show a quiet "This meal: N" line under the day total in `bite_page.dart`,
      hidden when `currentMealBites == 0`
- [ ] **Verify:** unit-test the trailing cluster's size when the last bite is
      recent, 0 when the last bite is older than `mealGapThreshold`, a fresh
      cluster of 1 after a `> mealGapThreshold` gap, a fresh manager at 0, and that
      it recomputes after a logged bite; widget-test the line shows with a current
      meal and hides when no meal is in progress

**Phase 5 — Body weight as a second bar on the bite chart**

- [ ] Inject `WeightRepository` into `BiteAnalyticsController` and load raw daily
      weights over the 30-day window (`getAllWeights()` filtered to `[from30, to)`)
- [ ] Add a second `BarChartRodData` per group in `daily_bites_chart.dart` for
      weight, on a secondary right-hand kg axis fitted to the weight min/max
      (normalise the rod's `toY`, label `rightTitles` in kg); distinct colour, a
      two-item legend, and each rod at ~half the current `_barWidth` (two per day)
      over the kept 30-day window
- [ ] Weight bar omitted on days with no weigh-in; bite-only days unchanged
- [ ] **Verify:** the chart renders bite-only, weight-only, and both-present days;
      the weight axis fits the weight range (small changes stay visible, not
      flattened from zero); a day without a weigh-in shows only the bite bar

**Phase 6 — Polish**
- [ ] Accessibility labels on the new tile, the selected-bar highlight, the
      current-meal line, and the weight bars/legend; consistent theming/spacing; a
      final `flutter analyze` / `flutter test` pass before pushing
