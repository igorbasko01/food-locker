# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

FoodLocker is a Flutter (mobile, primarily Android) app with two shipped features: daily **weight** tracking + analytics, and in-meal **bite** counting + pacing. State is exposed to the UI via Provider. The two features use different local stores: weight is on Hive CE, bite is on Drift/SQLite (see Architecture). Despite the name and README, those are the whole feature set (a `food`/`days` feature described in the README no longer exists in `lib/`).

## Commands

- `flutter pub get` — install dependencies
- `flutter analyze` — static analysis / lint (rules from `analysis_options.yaml` → `flutter_lints`)
- `flutter test` — run all tests
- `flutter test test/features/weight/weight_manager_test.dart` — run a single test file
- `flutter test --name "substring"` — run tests whose description matches
- `flutter run` — run on a connected device/emulator (see `.agents/skills/flutter-emulator-run/SKILL.md` for the emulator workflow)
- `dart run build_runner build --delete-conflicting-outputs` — regenerate generated code: Hive adapters after changing a `@HiveType`/`@HiveField` model, and the Drift database (`bite_database.g.dart`) after changing a bite table
- `./setup.sh` — one-time local setup; points `core.hooksPath` at `.githooks`

`flutter analyze` and `flutter test` both gate pushes locally (`.githooks/pre-push`) and PRs to `main` (`.github/workflows/flutter_ci.yml`). Run them before pushing.

## Code Generation

`*.g.dart` files (e.g. `lib/features/weight/data/weight.g.dart`, `lib/features/bite/data/bite_database.g.dart`) and `lib/hive_registrar.g.dart` are generated and checked in — do not edit them by hand. After adding or changing a Hive model, or adding a new `@HiveType`, rerun `build_runner`. Hive `typeId`s must be unique and stable across the app's history (weight uses 3 and 4); reusing an old id breaks existing users' stored boxes, so pick a fresh id rather than renumbering. The bite store is Drift: rerun `build_runner` after changing a `@DriftDatabase` table, and bump `BiteDatabase.schemaVersion` with a matching migration so existing users' SQLite files upgrade.

## Architecture

Code is organized as `lib/features/<feature>/data` (domain + persistence) and `lib/ui` (`pages/`, `widgets/`, shell, theme). The dependency wiring lives in `lib/main.dart`: Hive is initialized and the `weights` box opened, the Drift `BiteDatabase` is opened, and both features' repositories/managers are provided through a `MultiProvider` before `runApp`. `AppShell` is a four-tab `BottomNavigationBar` (Home / Weight / Bite / Settings) over an `IndexedStack`.

Key layering for the weight feature:

- **`Weight` / `WeightUnit`** (`weight.dart`) — Hive-annotated domain model.
- **`WeightRepository`** — abstract persistence interface. `WeightRepositoryHelper` is a mixin providing shared lowest-weight logic + caching. Three implementations exist: `PersistentWeightRepository` (Hive-backed, production), `InMemoryWeightRepository` (tests), and it is injected as a `Provider<WeightRepository>` so callers depend on the interface, not the box.
- **`WeightManager extends ChangeNotifier`** — the UI-facing state holder (`ChangeNotifierProvider`). It owns the in-memory `_weights` list and, after every mutation, re-reads from the repository and `notifyListeners()` to stay consistent. Wraps `WeightAnalytics` and re-exports its `StreakType`/`OvereatingStats` types.
- **`WeightAnalytics`** — pure computation over the repository (lowest all-time / last 30 / last 7 days, overeating & streak stats).

Dates are treated as day-granular throughout: repository keys and equality normalize to `(year, month, day)`, so "one entry per day" is the invariant. When adding mutation paths, follow the existing pattern (write through the repository, then refresh `_weights` from it).

The bite feature mirrors this shape (interface + manager) on Drift instead of Hive:

- **`BiteDatabase`** (`bite_database.dart`) — two tables: `bites` (append-only `at_ms` epoch-millis log; only the raw timestamp is stored) and `pacing_config` (versioned `b1_s`/`b2_s` thresholds, a slowly-changing dimension seeded with a default on first run).
- **`BiteRepository`** — persistence interface; `DriftBiteRepository` is the production impl, injected as a `Provider<BiteRepository>`.
- **`BiteManager extends ChangeNotifier`** — UI state for the Bite tab: owns today's count and drives the pacing ticker/zone in memory. Counts, inter-bite deltas, and pacing zones (`PacingZone`) are all **derived at read time** from the stored timestamps, never persisted.

### Backup / restore

`SerializationService` (Settings tab) exports/imports one zip spanning **both** stores. Each dataset owns a per-store codec — `WeightBackupCodec` (`weight.csv`), `BiteBackupCodec` (`bites.csv`, raw `at_ms`), and `PacingConfigBackupCodec` (`pacing_config.csv`, the threshold versions) — and `SerializationService` coordinates them into a single archive. `restoreFromBackup` is the destructive clear-then-restore core, kept separate from file-picker/IO so it stays unit-testable; it always replaces weights, and replaces bites / pacing config only when the archive actually carries that entry (an older backup missing an entry leaves that store untouched), deduping on import (repeated instants for bites, repeated `effective_ms` for config). Core CSV helpers live in `lib/core/` (`csv_serializer.dart`, `where.dart`).

## Testing

Tests mirror `lib/` under `test/`. Prefer `InMemoryWeightRepository` over Hive in unit tests; for bite tests use `BiteDatabase.forTesting(NativeDatabase.memory())` or a fake `BiteRepository`. `test/features/weight/hive_ce_migration_test.dart` guards persistence/migration behavior — treat it as a compatibility contract when touching models or `typeId`s.

## Commit Messages & Releases

This project uses **Conventional Commits** — always prefix commit messages and PR titles with `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, etc. On every push to `main`, the **release-please** CI workflow (`.github/workflows/release-please.yml`) reads these commits to calculate the next version, bump `pubspec.yaml`, and update `CHANGELOG.md` via a release PR — so the prefix directly drives versioning (`feat:` → minor, `fix:` → patch, `!`/`BREAKING CHANGE:` → major). Do not bump the version manually. `RELEASING.md` documents the full flow and `build_install_release.sh` builds/installs a release APK.
