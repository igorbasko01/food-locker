# Food Locker — Bite Analytics Plan

A phased plan to add a **Bite Analytics** screen to the Bite tab: a read-only
dashboard reached from a small chart button in the top-right corner, surfacing
daily-bite trends, averages, and a meal/snack breakdown derived from the stored
timestamps.

> **Status: draft.** Nothing here is built yet. This document scopes the feature
> and records the design decisions before any code lands. Open questions that
> need a call before implementation are collected in §6.

---

## 0. Guiding principles

These carry over from the pacing plan (`bite_pacing_plan.md` §0) and constrain
every decision below.

- **Store facts, derive views.** The `bites` table stays exactly as it is — an
  append-only log of raw `at_ms` timestamps. Every analytic (daily counts,
  averages, meals, snacks) is a **read-time projection** of that log. Nothing new
  is persisted; no schema change, no migration.
- **Bite count is the headline metric.** The analytics screen elaborates on the
  count the main screen already shows — it never introduces a competing number.
- **Read-only.** This screen only reads. It logs nothing, mutates nothing, and
  touches no pacing state. It can be opened and closed without side effects.
- **Local-day granularity, DST-safe.** Days are calendar days in the device's
  local zone, bounded by the half-open `[startOfDay, startOfNextDay)` window and
  built with the `DateTime(y, m, d ± 1)` idiom already used in `BiteManager` and
  `WeightAnalytics` — never fixed 24-hour arithmetic.

---

## 1. What the screen shows (v1 scope)

1. **Daily bites chart** — a bar chart of total bites per calendar day over a
   window (default: last 30 days). One bar per day, gaps for zero days.
2. **Averages** — mean daily bites over the **last 30 days** and the **last
   year**. (Mean over calendar days in the window, including or excluding
   zero-bite days — see §6.)
3. **Max daily bites — last 30 days** — the single highest day's count in the
   window, and the day it fell on.
4. **Meals per day** — count of *meals* per day, where a **meal** is a cluster of
   bites no more than **5 minutes** apart (§2). Shown as today's number plus an
   average over the window.
5. **Daily meal breakdown** — for a selected day (default: today), the bite count
   in each meal, plus a total of bites that fell **outside** any meal (**snacks**,
   §2).

"…and maybe more" — candidates parked for later in §5.

---

## 2. The meal model (the one genuinely new concept)

Everything except the meal/snack split is a straight count or average. The meal
model is the piece that needs a precise definition, because the rest of the
screen (items 4 and 5) is built on it.

### 2a. Clustering

Walk a day's bites in chronological order. Start a cluster at the first bite;
keep adding bites while the gap from the **previous bite** is `≤ 5 min`; a gap
`> 5 min` closes the current cluster and starts a new one.

- The threshold is between **consecutive** bites, not from the cluster's start —
  a long, slow meal stays one cluster as long as no single gap exceeds 5 min.
- `5 min` is a named constant (`mealGapThreshold`), defined once so it is easy to
  retune. See §6 for whether it should be user-configurable.

### 2b. Meal vs. snack

Not every cluster is a "meal" — item 5 explicitly separates *meals* from *bites
outside meals (snacks)*. So a cluster is promoted to a **meal** only if it has at
least `minMealBites` bites; smaller clusters count as **snacks**.

- **Proposed default: `minMealBites = 5`.** A cluster of fewer than 5 bites is
  treated as snacking, and its bites roll into the day's snack total.
- "Bites outside meals (snacks)" = every bite in the day that is not part of a
  qualifying meal cluster: `todayCount − Σ(bites in meal clusters)`.

This threshold is a **decision, not a fact** — flagged in §6. If we'd rather every
cluster be a meal (so "snacks" only means truly isolated single bites), set
`minMealBites = 1` and the snack total collapses to lone bites separated by
`> 5 min` on both sides.

### 2c. Day boundaries

Clustering runs **within a single local day**. A meal that straddles midnight is
split at the day boundary (the bites before midnight belong to one day, those
after to the next). This keeps "meals per day" consistent with every other
per-day metric and avoids a single late-night meal being double-counted or
attributed to the wrong day. Noted as a known edge in §6 in case we later prefer
gap-based splitting that ignores midnight.

---

## 3. Where the computation lives

Mirror the weight feature's shape: a pure computation class over the repository,
exactly as `WeightAnalytics` sits over `WeightRepository`.

### 3a. `BiteAnalytics` — pure, read-time computation

A new `lib/features/bite/data/bite_analytics.dart`, constructed from a
`BiteRepository`. Async (the bite store is async, unlike Hive's cached weights),
returning plain value objects:

```dart
class BiteAnalytics {
  BiteAnalytics(this._repository);
  final BiteRepository _repository;

  Future<List<DailyBiteCount>> dailyCounts(DateTime from, DateTime to);
  Future<double> averagePerDay(DateTime from, DateTime to);
  Future<DailyBiteCount?> maxDay(DateTime from, DateTime to);   // last-30 max
  Future<List<Meal>> mealsForDay(DateTime day);                 // clusters ≥ minMealBites
  Future<DayMealBreakdown> breakdownForDay(DateTime day);       // meals + snack total
  Future<double> averageMealsPerDay(DateTime from, DateTime to);
}
```

Value types (`DailyBiteCount`, `Meal`, `DayMealBreakdown`) are small immutable
data classes in the same file, following the `OvereatingStats` precedent.

### 3b. Repository seam — one aggregate query added

Per the pacing plan §1a, day-grouped counts are a SQL sweet spot, so add **one**
aggregate method to `BiteRepository` rather than pulling a year of raw rows into
Dart just to count them:

```dart
/// Bites per local calendar day in [from, to), one entry per day that has
/// at least one bite. Grouped in SQL via date(at_ms/1000,'unixepoch','localtime').
Future<List<DailyBiteCount>> dailyBiteCounts(DateTime from, DateTime to);
```

Meal clustering needs the actual inter-bite gaps, so it keeps using the existing
`bitesInRange(from, to)` and clusters in Dart — the volume there is one day (or a
window) of raw bites, which is small. No new table, no `schemaVersion` bump.

### 3c. UI wiring

The screen loads async, so give it a lightweight controller rather than reusing
the pacing-oriented `BiteManager`:

- **Recommended:** a `BiteAnalyticsController extends ChangeNotifier` that holds
  the loaded results + a loading flag, created per-screen from the injected
  `BiteRepository` (`context.read<BiteRepository>()`), loading in `initState`.
  Keeps `BiteManager` focused on live logging/pacing and keeps analytics work off
  the main screen's hot path.
- **Alternative:** a bare `FutureBuilder` in the page if the state stays trivial.
  Fine for a first cut; promote to a controller once there's a window selector or
  a day picker driving re-loads.

---

## 4. Navigation — the chart button

The chart button lives at the **top-right of the Bite tab's app bar**, and the
app bar is owned by `AppShell` (one shared `AppBar` across all four tabs), so the
button is added there, shown only for the Bite tab.

- **Recommended:** in `AppShell`, add `actions:` to the shared `AppBar` that
  render an `IconButton(Icons.bar_chart_rounded /* or insights */)` **only when
  `_currentIndex == 2`** (the Bite tab), pushing a full-screen route to a new
  `BiteAnalyticsPage`. That page owns its **own** `Scaffold` + `AppBar` (title
  "Bite Analytics", automatic back arrow), so it is self-contained and does not
  fight the shell's chrome.
- **Why a pushed route, not a fifth tab:** analytics is a drill-down off the Bite
  tab, not a peer of Home/Weight/Bite/Settings. A route keeps the bottom nav at
  four items and gives a natural back affordance.
- **Alternative considered:** give `BitePage` its own `AppBar` with the action.
  Rejected — it would double the app bar inside the shell's existing one. The
  conditional-action approach reuses the shell's single app bar cleanly.

New files: `lib/ui/pages/bite_analytics_page.dart`, plus widgets under
`lib/ui/widgets/` (e.g. `daily_bites_chart.dart`, a stat-tile widget for the
averages/max, a meal-breakdown list). Charts use **`fl_chart`**, already a
dependency (used by `weight_chart.dart`) — a `BarChart` for daily bites, matching
the existing chart's theming.

---

## 5. Follow-up candidates ("…and maybe more")

Parked, not in v1 — listed so v1 doesn't accidentally foreclose them:

- **Window selector** (7 / 30 / 365 days) driving the chart and averages.
- **Day picker** for the meal breakdown (browse past days, not just today).
- **Meals-per-day trend** as its own small chart.
- **Time-of-day distribution** (bites/meals by hour) — a snacking-pattern view.
- **Pacing overlay** — average inter-bite gap or share of well-paced bites,
  joining the analytics with the pacing thresholds (`pacingConfigAt`).
- **Best/worst day, current low-bite streak** — echoing the weight streak banners.

---

## 6. Open questions / decisions to confirm

These change the numbers on screen, so they're worth settling before building:

1. **Snack threshold (`minMealBites`).** Proposed default **5**. Alternative:
   `1` (every cluster is a meal; snacks = lone `>5 min`-isolated bites). Drives
   items 4 and 5. *(Leaning: 5.)*
2. **Averages over zero-bite days.** Does the daily average divide by *all*
   calendar days in the window (zeros included, so a skipped day drags the mean
   down) or only by days that have at least one bite? *(Leaning: include zero
   days — it reflects real adherence, per §0's adherence framing.)*
3. **Meal gap threshold configurability.** Ship `5 min` as a fixed constant for
   v1, or expose it like the pacing thresholds? *(Leaning: fixed constant in v1;
   revisit if requested.)*
4. **Midnight-straddling meals** (§2c) — split at the day boundary (proposed) or
   cluster purely by gaps, attributing the whole meal to its first bite's day?
   *(Leaning: split at boundary, consistent with every other per-day metric.)*
5. **Default breakdown day** — today, or the most recent day with any bites?
   *(Leaning: today, with an empty state when today has none.)*

---

## 7. Tasks

Ordered so each phase assumes the earlier ones; beyond that they're independent.
Each is one sitting on a single subject, following the pacing plan's cadence.

**Phase 0 — Settle the open questions (§6)**
- [ ] Confirm `minMealBites`, the zero-day averaging rule, and the midnight
      handling so the analytics have a single defined meaning before code lands

**Phase 1 — `dailyBiteCounts` on the repository seam**
- [ ] Add `dailyBiteCounts(from, to)` to `BiteRepository` (SQL `GROUP BY` on the
      local day) and implement it in `DriftBiteRepository`; add the `DailyBiteCount`
      value type
- [ ] Add a fake/in-memory path for tests (existing `BiteDatabase.forTesting`)
- [ ] Unit-test grouping, the half-open window, and the empty range

**Phase 2 — `BiteAnalytics` computation**
- [ ] New `bite_analytics.dart` over `BiteRepository`: `dailyCounts`,
      `averagePerDay`, `maxDay`, per the confirmed averaging rule
- [ ] Meal clustering (`mealsForDay`, `breakdownForDay`, `averageMealsPerDay`)
      over `bitesInRange`, with the `mealGapThreshold` / `minMealBites` constants
- [ ] Unit-test clustering edges: empty day, single bite, a gap of exactly the
      threshold, back-to-back clusters, sub-`minMealBites` clusters → snacks,
      and a day that straddles midnight

**Phase 3 — Navigation + screen scaffold**
- [ ] Add the conditional chart action to `AppShell`'s app bar (Bite tab only),
      pushing `BiteAnalyticsPage`
- [ ] `BiteAnalyticsPage` with its own `Scaffold`/`AppBar` and a
      `BiteAnalyticsController` (or `FutureBuilder`) loading from the injected
      `BiteRepository`; loading and empty states

**Phase 4 — Daily bites chart**
- [ ] `daily_bites_chart.dart` — an `fl_chart` `BarChart` over `dailyCounts`,
      themed like `weight_chart.dart`, with the last-30-days default window

**Phase 5 — Averages + max stat tiles**
- [ ] Stat row/tiles: 30-day average, 1-year average, 30-day max (with its date)

**Phase 6 — Meal breakdown**
- [ ] Meals-per-day (today + window average) and the per-day meal breakdown list
      with the snack total, for the default day from §6

**Phase 7 — Polish**
- [ ] Empty/first-run states throughout, accessibility labels on the chart and
      tiles, and a `flutter analyze` / `flutter test` pass before pushing
</content>
</invoke>
