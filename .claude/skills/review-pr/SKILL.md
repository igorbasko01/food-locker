---
name: review-pr
description: >-
  Review a FoodLocker pull request or working-tree diff against this repo's own
  invariants — Hive typeIds and generated code, Drift schema migrations, the
  one-entry-per-day rule, repository-then-notify mutations, backup-codec
  compatibility, and Conventional Commit titles — and post the findings as a PR
  comment. Use when asked to review a PR, review a diff, or check a change before
  merge ("review #105", "review this branch", "does this look right to merge"),
  and when another skill or agent hands over a PR number for review. Reports only;
  never pushes, approves, or merges.
---
# Review a FoodLocker PR

Read one change carefully, report what is actually wrong with it, and stop.
This is a reporting role: never push a commit, never approve, never merge, and
never resolve someone else's review thread. The author — human or agent —
decides what to do with the findings.

Read `CLAUDE.md` first. Its architecture notes and code-generation rules are the
standard this review measures against.

## 1. Get the change

A PR number → read the PR's title, body and diff, and the files it touches at
that head. No target given → review the working-tree diff against `origin/main`.

Use whatever GitHub access exists, in this order: the GitHub MCP tools
(`pull_request_read`, `get_file_contents`, `add_issue_comment`, …), then the
`gh` CLI if it happens to be installed. Do not install either — web sessions
have MCP only.

Before reviewing a PR, check whether a comment containing `<!-- review-pr -->`
already exists on it. If one does and the PR head has not moved since, say so
and stop rather than posting the same findings twice.

A diff alone is not enough context to judge most of the checks below. Open the
files around the change — the repository interface being implemented, the
manager that wraps it, the test that guards it.

## 2. The invariants that matter here

These are the failures a general-purpose reviewer will miss and CI will not
catch. Work through them against the actual diff; skip the ones the change
cannot possibly touch.

**Generated code.** `*.g.dart` and `lib/hive_registrar.g.dart` are checked in
but generated. A hand-edit is a defect even when it looks correct. A changed
`@HiveType`/`@HiveField` model or `@DriftDatabase` table with no corresponding
regenerated output is the same defect inverted — the generated file is now stale.

**Hive typeIds.** Weight owns 3 and 4. A new `@HiveType` needs a fresh id; a
renumbered or reused id silently breaks every existing user's stored box. The
same goes for `@HiveField` indices on existing models — stable forever, and a
removed field's index must not be recycled. Changes to
`test/features/weight/hive_ce_migration_test.dart` deserve real scrutiny: it is
a compatibility contract, not a normal test, and loosening it to make a change
pass is backwards.

**Drift schema.** A changed bite table needs a `BiteDatabase.schemaVersion` bump
*and* a migration that carries existing SQLite files forward. One without the
other ships a crash to anyone who already has the app.

**Day granularity.** Weight is day-granular throughout: repository keys and
equality normalize to `(year, month, day)`, and "one entry per day" is the
invariant. Watch for a new path that stores or compares a full `DateTime`, or
that can produce two entries for one day.

**Mutation shape.** Weight mutations write through the repository, then re-read
`_weights` from it and `notifyListeners()`. A path that mutates the in-memory
list directly, or writes without refreshing, drifts out of sync with storage.

**Derived, not stored.** Bite counts, inter-bite deltas and `PacingZone` are
derived at read time from stored timestamps. A change that persists one of them
introduces a second source of truth.

**Interfaces over stores.** Callers depend on `WeightRepository` /
`BiteRepository` through Provider, not on Hive boxes or the Drift database.
New wiring belongs in the `MultiProvider` in `lib/main.dart`.

**Backup compatibility.** A new store or field needs its own codec and
coordination in `SerializationService`. `restoreFromBackup` must keep tolerating
an archive that lacks an entry (leave that store untouched, do not clear it) and
must keep deduping on import. Changing a CSV's columns breaks archives users
already have — flag it unless the change reads both shapes.

**Versioning.** release-please owns `pubspec.yaml`'s version and `CHANGELOG.md`;
a manual bump to either is a defect. The PR title needs a Conventional Commit
prefix that matches what the change actually does, since the squashed subject is
what computes the next version — a `feat:` on a bug fix inflates the minor, a
`chore:` on a user-visible change hides it from the changelog.

**Tests.** Tests mirror `lib/` under `test/`, and prefer
`InMemoryWeightRepository` and `BiteDatabase.forTesting(NativeDatabase.memory())`
over real stores. Ask whether the change's actual behaviour is covered, not
whether a test file was touched.

## 3. The ordinary pass

Then read it as a reviewer: logic that does not do what the PR says it does,
null and async mistakes, state read after dispose, a `ChangeNotifier` or
database left undisposed, off-by-one and boundary errors on date ranges,
timezone and DST hazards around day normalization and epoch-millis conversion,
and anything that is simply more code than the job needs.

Skip what the toolchain already handles. `flutter analyze` and `flutter test`
gate every PR, so lint and formatting nits are noise. Keep comments in scope of
the `concise-comments` standard, and flag comment noise only when it is genuinely
misleading or restates the code at length.

## 4. Report

Post one comment on the PR (or print the review, when there is no PR). Lead
with a one-line verdict — whether anything blocks merge — then the findings,
most serious first. For each: the file and line, what breaks, and the concrete
case where it breaks. A finding you cannot state a failure case for is a
suspicion; either verify it or leave it out.

Say plainly when the change is clean. Padding a good PR with speculative
findings costs more trust than it buys.

Open the comment with `<!-- review-pr -->` on its own line so later runs can
tell the PR was already reviewed, and end it with the attribution footer:

```
---
_Generated by [Claude Code](https://claude.ai/code)_
```

Then stop. No pushes, no approval, no merge — report the findings and hand the
PR back to its author.
