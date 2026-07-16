# Food Locker — Bite Analytics Enhancements Plan

A follow-up to `bite_analytics_plan.md` (now shipped) adding three refinements
across the Bite tab and its analytics screen:

1. **Average meal size** over the last 30 days, as a new stat tile.
2. **A pickable breakdown day** — tapping a bar in the daily-bites chart switches
   the meal-breakdown card below it to that day.
3. **Current-meal bites on the main Bite page** — the in-progress meal's running
   count, alongside the day's headline total.

> **Status: ready to build.** Nothing here is built yet; the design decisions
> below (§4) are proposed defaults — confirm or adjust before Phase 1.

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

`_MealBreakdownCard`'s title becomes the selected date ("Meals — Jul 14", "Today's
meals" when it's today), with a small "Back to today" action shown only when
`!isSelectedDayToday`. The card keeps its own empty state for a selected day with
no bites.

---

## 3. Current-meal bites on the main Bite page

### 3a. What it is

Under "Today's Bites", show the number of bites in the **current meal** — the
trailing cluster of bites whose consecutive gaps are `≤ mealGapThreshold`
(5 min), using the same rule as the analytics meal model. It answers "how much
have I eaten *this* sitting?" next to the all-day total.

A meal is "in progress" while the last bite is within `mealGapThreshold` of now;
once that lapses the current-meal count clears (the next bite after the gap starts
a fresh meal at 1). No `minMealBites` gate applies to the live count — it counts
from the first bite of the sitting, before the cluster is big enough to have
"qualified" as a meal in the analytics sense.

### 3b. Where it lives

`BiteManager` already holds `_lastBiteAt` in memory and drives the live screen, so
the current-meal count lives there as derived state:

```dart
/// Bites in the current (in-progress) meal: the trailing run of bites no more
/// than [BiteAnalytics.mealGapThreshold] apart, ending at the last bite. 0 when
/// no meal is in progress (no bite within the threshold of now).
int get currentMealBites;
```

- **On `logBite`:** if the previous bite is within `mealGapThreshold` of now,
  increment; otherwise reset to 1 (this tap starts a new meal).
- **On `initialize`:** seed by reading today's bites, clustering the tail, and
  taking the trailing cluster's size — but only when the last bite is within
  `mealGapThreshold` of now; otherwise seed 0, so opening the app hours later
  shows no stale in-progress meal.
- Reuse `BiteAnalytics.mealGapThreshold` as the single source of the 5-min rule
  rather than redefining it on the manager.

### 3c. UI

`bite_page.dart` shows the count as a quiet secondary line under the big day total
(e.g. "This meal: N"), rendered only when `currentMealBites > 0` so an empty day
stays clean. It reads `biteManager.currentMealBites`; no new provider.

**Live-clear caveat (settled, §4.4):** the number is bite-driven. Between bites it
does not auto-clear at the 5-min mark — the pacing ticker stops at `b2` (~30 s), so
there's no periodic rebuild to hide it on. It clears on the next bite after a gap
(reset to 1) or when the tab/app is left and the page rebuilds. A timer to blank it
exactly at the 5-min boundary is deliberately out of scope for v1.

---

## 4. Proposed decisions

Defaults chosen to match the shipped screen; confirm or adjust before building.

1. **Avg meal size counts only qualifying meals** (`≥ minMealBites`), excluding
   snacks, and is shown as a whole number of bites. `—` when the window has no
   meal.
2. **Breakdown-day selection is tap-to-select on the chart**, defaulting to today,
   with an explicit "Back to today" control. The top stat tiles and "Meals today"
   stay today/window metrics — only the bottom breakdown card follows the
   selection.
3. **Current meal reuses `mealGapThreshold` (5 min)** and ignores `minMealBites`
   for the live count (it counts from bite 1 of the sitting).
4. **Current meal is bite-driven, not timer-driven** — it clears on the next
   post-gap bite, not at the instant 5 min elapses (§3c).
5. **Current-meal line is hidden when the day has no bites.**

---

## 5. Phases

Each phase is one sitting on a single subject, ends **green** (`flutter analyze`
+ `flutter test` pass), and is independently committable. Ordered so each assumes
the earlier ones; every phase ships with its tests — the "verify" bullet is the
definition of done.

**Phase 1 — `averageMealSize` on `BiteAnalytics` + the stat tile**

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

**Phase 2 — Pickable breakdown day**

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

**Phase 3 — Current-meal bites on the Bite page**

- [ ] Add `currentMealBites` to `BiteManager`: increment/reset in `logBite` on the
      `mealGapThreshold` rule, and seed it in `initialize` from today's trailing
      cluster (0 when the last bite is older than the threshold)
- [ ] Reference `BiteAnalytics.mealGapThreshold` as the single source of the 5-min
      rule
- [ ] Show a quiet "This meal: N" line under the day total in `bite_page.dart`,
      hidden when `currentMealBites == 0`
- [ ] **Verify:** unit-test increment within the threshold, reset to 1 after a
      gap, a fresh manager at 0, and the initialize seed (recent tail vs. a stale
      last bite → 0); widget-test the line shows with a current meal and hides on
      an empty day

**Phase 4 — Polish**
- [ ] Accessibility labels on the new tile, the selected-bar highlight, and the
      current-meal line; consistent theming/spacing; a final `flutter analyze` /
      `flutter test` pass before pushing
