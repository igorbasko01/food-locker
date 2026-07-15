# Food Locker — Bite Analytics Plan

A phased plan to add a **Bite Analytics** screen to the Bite tab: a read-only
dashboard reached from a small chart button in the top-right corner, surfacing
daily-bite trends, averages, and a meal/snack breakdown derived from the stored
timestamps.

> **Status: ready to build.** Nothing here is built yet, but every design
> decision is settled (§6) — implementation can start at Phase 1.

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
   year**, counting only days with at least `minBitesForAverage` (**40**) bites;
   zero and lightly-logged days are excluded so partial-logging noise doesn't drag
   the mean down (§6.2).
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
- `5 min` is a fixed named constant (`mealGapThreshold`), defined once so it is
  easy to retune in code — **not** user-configurable in v1 (§6.3, settled).

### 2b. Meal vs. snack

Not every cluster is a "meal" — item 5 explicitly separates *meals* from *bites
outside meals (snacks)*. So a cluster is promoted to a **meal** only if it has at
least `minMealBites` bites; smaller clusters count as **snacks**.

- **`minMealBites = 10`** (§6.1, settled). A cluster of fewer than 10 bites is
  treated as snacking, and its bites roll into the day's snack total — so a small
  snack never gets promoted to a full meal.
- "Bites outside meals (snacks)" = every bite in the day that is not part of a
  qualifying meal cluster: `todayCount − Σ(bites in meal clusters)`.

### 2c. Day boundaries

Clustering runs **within a single local day** (§6.4, settled). A meal that
straddles midnight is split at the day boundary — the bites before midnight
belong to one day, those after to the next. This keeps "meals per day" consistent
with every other per-day metric and avoids a single late-night meal being
double-counted or attributed to the wrong day.

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

## 6. Settled decisions

All confirmed — these fix the numbers on screen:

1. **Snack threshold `minMealBites = 10`.** A cluster qualifies as a *meal* only
   with 10+ bites; smaller clusters are snacks and roll into the day's snack
   total, so a snack-sized cluster is never promoted to a meal.
2. **Averages count only days with ≥ `minBitesForAverage` (40) bites.** Zero and
   lightly-logged days are excluded from both the numerator and the denominator,
   so a day you forgot to log — or only logged a few bites — never dilutes the
   mean. A fixed code constant, like the meal thresholds. The chart flags these
   excluded days visually (Phase 5) so the average stays legible against it.
3. **`mealGapThreshold = 5 min` is a fixed code constant** in v1 — not
   user-configurable.
4. **Midnight-straddling meals split at the day boundary**, consistent with every
   other per-day metric.
5. **Default meal-breakdown day is today**, with an empty state when today has no
   bites yet.

---

## 7. Phases

Each phase is one sitting on a single subject, ends **green** (`flutter analyze`
+ `flutter test` pass), and is independently committable. Phases are ordered so
each assumes the earlier ones. Every implementation phase ships with its tests —
the "verify" bullet is the definition of done, not a separate phase.

Data first (1–3), then the screen shell (4), then one card per phase (5–8), then
polish (9). Nothing before Phase 4 is user-visible, so 1–3 can land as pure,
fully-tested logic behind no UI.

**Phase 1 — `dailyBiteCounts` on the repository seam**

The one new persistence query; a SQL `GROUP BY`, no schema change.
- [ ] Add the `DailyBiteCount` value type (`day` + `count`) in `bite_analytics.dart`
- [ ] Add `dailyBiteCounts(from, to)` to `BiteRepository`; implement in
      `DriftBiteRepository` grouping on `date(at_ms/1000,'unixepoch','localtime')`
- [ ] **Verify:** unit-test grouping, the half-open `[from, to)` window, an empty
      range, and two bites on the same day collapsing to one entry

**Phase 2 — `BiteAnalytics`: counts, averages, max**

Pure computation over the repository — no meals yet.
- [ ] New `lib/features/bite/data/bite_analytics.dart` constructed from a
      `BiteRepository`
- [ ] `minBitesForAverage = 40` constant
- [ ] `dailyCounts(from, to)`, `averagePerDay(from, to)` (mean over only the days
      with ≥ 40 bites — §6.2), `maxDay(from, to)` returning the peak `DailyBiteCount`
- [ ] **Verify:** unit-test that sub-40 and zero days are excluded from the
      average, a window with no qualifying day (average null/0), max with ties, and
      empty data (max null)

**Phase 3 — `BiteAnalytics`: meal clustering**

The meal/snack model (§2), the one genuinely new logic.
- [ ] `mealGapThreshold = 5 min` and `minMealBites = 10` constants
- [ ] `mealsForDay(day)` — cluster a day's `bitesInRange` by ≤-5-min gaps, keep
      clusters with ≥ 10 bites as meals; split at the local-day boundary (§2c)
- [ ] `breakdownForDay(day)` → `DayMealBreakdown` (per-meal counts + snack total)
      and `averageMealsPerDay(from, to)`
- [ ] **Verify:** unit-test empty day, single bite, a gap of *exactly* 5 min,
      back-to-back clusters, a sub-10-bite cluster → snacks, all-snack day, and a
      meal straddling midnight splitting into two days

**Phase 4 — Screen scaffold + navigation**

Get an (empty) screen reachable before filling it in.
- [ ] Chart `IconButton` in `AppShell`'s app bar, rendered only when
      `_currentIndex == 2`, pushing `BiteAnalyticsPage`
- [ ] `bite_analytics_page.dart` with its own `Scaffold`/`AppBar` ("Bite
      Analytics", back arrow) and a `BiteAnalyticsController extends ChangeNotifier`
      loading from the injected `BiteRepository` in `initState`
- [ ] Loading spinner and a global empty state (no bites logged ever)
- [ ] **Verify:** the button shows only on the Bite tab and the route opens/pops

**Phase 5 — Daily bites chart card**
- [ ] `daily_bites_chart.dart` — an `fl_chart` `BarChart` over `dailyCounts`
      (last 30 days), one bar per day, themed like `weight_chart.dart`
- [ ] Flag days that don't count toward the average (§6.2): a faint horizontal
      reference line at `minBitesForAverage` (40), and muted/desaturated fill on
      bars below it — so the chart visibly explains why those days are excluded
- [ ] **Verify:** renders with sparse data and a zero-bite gap day; a sub-40 bar
      shows muted below the 40 line and a ≥40 bar shows full-colour above it

**Phase 6 — Averages + max stat tiles**
- [ ] A stat-tile widget and a row of three: 30-day average, 1-year average,
      30-day max (with its date)
- [ ] **Verify:** tiles read correctly against a seeded fixture

**Phase 7 — Meals-per-day summary**
- [ ] Surface today's meal count and the window average (`averageMealsPerDay`)
- [ ] **Verify:** matches a hand-counted fixture

**Phase 8 — Daily meal breakdown card**
- [ ] For today (§6.5): a list of each meal's bite count plus the snack total,
      with an empty state when today has no bites yet
- [ ] **Verify:** meals, snacks, and the empty state each render

**Phase 9 — Polish**
- [ ] Accessibility labels on the chart and tiles, consistent theming/spacing,
      and a final `flutter analyze` / `flutter test` pass before pushing
</content>
</invoke>
