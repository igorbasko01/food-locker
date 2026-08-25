---
name: resolve-github-issue
description: Resolve one open GitHub issue in this repo end to end — pick it (or take the number given), implement it on a branch, open a PR, and drive its checks green — without asking the user anything. Use when told to resolve, fix, handle, or take on an issue ("resolve #103", "fix the import confirmation issue"), and for unattended runs that say only "resolve an open issue" or "handle a single issue up to a PR".
---
# Resolve GitHub Issue

Take one issue from open to an open PR, autonomously. Assume nobody is
available to answer questions: never ask, decide instead, and write the
decision down in the PR description.

Read `CLAUDE.md` before touching code — its commands, code-generation rules and
architecture notes are binding here.

## 1. Pick the issue

If an issue number was given, use it. Otherwise choose one:

- List open issues. Skip any that already have an open PR referencing them, an
  existing remote branch for them, or a label marking them blocked or still
  under discussion.
- Among the rest, take the one that is smallest and most fully specified — an
  explicit **Scope** or **Acceptance criteria** section counts for a lot.
  Tie-break by oldest.
- If nothing qualifies, report that and stop. Never invent work.

Read the issue body **and all of its comments** before planning anything; the
comments often carry the decisions the body is missing.

## 2. GitHub access

Use whatever exists in the environment, in this order:

1. The GitHub MCP tools (`list_issues`, `issue_read`, `create_pull_request`,
   `pull_request_read`, `actions_list`, `get_job_logs`, `add_issue_comment`, …).
2. The `gh` CLI, if it is installed.

Do not install either. Claude Code web sessions have MCP only — `gh` is absent
there — so never make `gh` the assumed path.

## 3. Branch

Fetch and branch off the latest `origin/main` as `issue-<N>-<short-slug>`.
Never commit to `main`.

## 4. Implement

- Do exactly the issue's stated scope. No drive-by refactors, no adjacent
  issues, nothing the issue lists as out of scope.
- Where the issue leaves a question open ("decisions worth making", "worth
  deciding while doing it"), pick the option that is smallest and most
  consistent with the existing code, and record the choice and the reasoning in
  the PR description.
- Follow the existing architecture: `lib/features/<feature>/data` for domain +
  persistence, `lib/ui` for pages/widgets, dependency wiring in `lib/main.dart`,
  and calls against repository interfaces rather than concrete stores.
- Match surrounding style, and keep comments to what the code cannot say itself.
- Never edit a `*.g.dart` file by hand. After changing a Hive model or a Drift
  table, rerun `build_runner`; a Drift table change also needs a
  `schemaVersion` bump with a matching migration, and a new `@HiveType` needs a
  fresh `typeId` (never a reused one).
- Cover the acceptance criteria with tests, mirroring `lib/` under `test/`.
  Prefer `InMemoryWeightRepository` and `BiteDatabase.forTesting` over real
  stores.

If the issue turns out to be far larger than it reads, already fixed on `main`,
or resting on a wrong premise: stop, comment on the issue with what you found,
and open no PR.

## 5. Verify without installing anything

- Flutter already on `PATH` → run `flutter analyze` and `flutter test`, fix what
  they catch, repeat until both are green.
- Flutter absent → **do not install it.** The toolchain is heavy and the
  sandboxed sqlite3 native-asset download is unreliable. Keep the diff small and
  self-reviewed, and let the `flutter_ci.yml` checks on the PR do the verifying.

Either way, say which of the two happened in the PR description.

## 6. Commit and open the PR

This repo uses **Conventional Commits**, and release-please computes the next
version from the squashed PR subject — so a non-conforming title breaks
versioning, and the prefix must reflect what the change actually does
(`fix:`, `feat:`, `refactor:`, `docs:`, `test:`, `chore:`).

- Commit as `<type>: <what changed> (#<N>)`.
- Push the branch and open a PR against `main` with the same `<type>:` prefix in
  the title.
- PR body: what changed, how each acceptance criterion is met, every assumption
  or decision made along the way, how it was verified (locally or deferred to
  CI), and `Closes #<N>`.

## 7. Drive the checks green

Subscribe to the PR's activity if a subscription mechanism exists
(`subscribe_pr_activity` or equivalent); skip silently if not.

While a check fails: read the failing job's logs, fix the cause, push, look
again. Never skip, disable or delete a test to get green, and never push an
empty commit to re-trigger CI. After 5 failed rounds, stop pushing and comment
on the PR with what still fails and why.

## 8. Stop

One issue, one PR. Report the PR link, the issue it closes, and a short summary
of the change and how it was verified. Leave the PR for human review — never
merge it, and never close the issue by hand (`Closes #<N>` does that on merge).
