# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

FoodLocker is a Flutter (mobile, primarily Android) app for tracking daily weight and derived health stats. Data is stored locally with Hive CE; state is exposed to the UI via Provider. Despite the name and README, the shipped feature set is weight tracking and analytics (a `food`/`days` feature described in the README no longer exists in `lib/`).

## Commands

- `flutter pub get` — install dependencies
- `flutter analyze` — static analysis / lint (rules from `analysis_options.yaml` → `flutter_lints`)
- `flutter test` — run all tests
- `flutter test test/features/weight/weight_manager_test.dart` — run a single test file
- `flutter test --name "substring"` — run tests whose description matches
- `flutter run` — run on a connected device/emulator (see `.agents/skills/flutter-emulator-run/SKILL.md` for the emulator workflow)
- `dart run build_runner build --delete-conflicting-outputs` — regenerate Hive adapters after changing any `@HiveType`/`@HiveField` model
- `./setup.sh` — one-time local setup; points `core.hooksPath` at `.githooks`

`flutter analyze` and `flutter test` both gate pushes locally (`.githooks/pre-push`) and PRs to `main` (`.github/workflows/flutter_ci.yml`). Run them before pushing.

## Code Generation

`*.g.dart` files (e.g. `lib/features/weight/data/weight.g.dart`) and `lib/hive_registrar.g.dart` are generated and checked in — do not edit them by hand. After adding or changing a Hive model, or adding a new `@HiveType`, rerun `build_runner`. Hive `typeId`s must be unique and stable across the app's history (weight uses 3 and 4); reusing an old id breaks existing users' stored boxes, so pick a fresh id rather than renumbering.

## Architecture

Code is organized as `lib/features/<feature>/data` (domain + persistence) and `lib/ui` (`pages/`, `widgets/`, shell, theme). The dependency wiring lives in `lib/main.dart`: Hive is initialized, the `weights` box is opened, and everything is provided through a `MultiProvider` before `runApp`. `AppShell` is a three-tab `BottomNavigationBar` (Home / Weight / Settings) over an `IndexedStack`.

Key layering for the weight feature:

- **`Weight` / `WeightUnit`** (`weight.dart`) — Hive-annotated domain model.
- **`WeightRepository`** — abstract persistence interface. `WeightRepositoryHelper` is a mixin providing shared lowest-weight logic + caching. Three implementations exist: `PersistentWeightRepository` (Hive-backed, production), `InMemoryWeightRepository` (tests), and it is injected as a `Provider<WeightRepository>` so callers depend on the interface, not the box.
- **`WeightManager extends ChangeNotifier`** — the UI-facing state holder (`ChangeNotifierProvider`). It owns the in-memory `_weights` list and, after every mutation, re-reads from the repository and `notifyListeners()` to stay consistent. Wraps `WeightAnalytics` and re-exports its `StreakType`/`OvereatingStats` types.
- **`WeightAnalytics`** — pure computation over the repository (lowest all-time / last 30 / last 7 days, overeating & streak stats).

Dates are treated as day-granular throughout: repository keys and equality normalize to `(year, month, day)`, so "one entry per day" is the invariant. When adding mutation paths, follow the existing pattern (write through the repository, then refresh `_weights` from it).

### Backup / restore

`SerializationService` (Settings tab) exports/imports one zip spanning **both** stores. Each dataset owns a per-store codec — `WeightBackupCodec` (`weight.csv`) and `BiteBackupCodec` (`bites.csv`, storing only the raw `at_ms`) — and `SerializationService` coordinates them into a single archive. `restoreFromBackup` is the destructive clear-then-restore core, kept separate from file-picker/IO so it stays unit-testable; it always replaces weights, and replaces bites only when the archive actually carries a bite entry (an older weight-only backup leaves bites untouched), deduping repeated instants on import. Core CSV helpers live in `lib/core/` (`csv_serializer.dart`, `where.dart`).

## Testing

Tests mirror `lib/` under `test/`. Prefer `InMemoryWeightRepository` over Hive in unit tests. `test/features/weight/hive_ce_migration_test.dart` guards persistence/migration behavior — treat it as a compatibility contract when touching models or `typeId`s.

## Commit Messages & Releases

This project uses **Conventional Commits** — always prefix commit messages and PR titles with `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, etc. On every push to `main`, the **release-please** CI workflow (`.github/workflows/release-please.yml`) reads these commits to calculate the next version, bump `pubspec.yaml`, and update `CHANGELOG.md` via a release PR — so the prefix directly drives versioning (`feat:` → minor, `fix:` → patch, `!`/`BREAKING CHANGE:` → major). Do not bump the version manually. `RELEASING.md` documents the full flow and `build_install_release.sh` builds/installs a release APK.
