---
name: implement-next-phase
description: Implement the next phase of a phased design-document plan in the current repo and open a PR for it. Use this whenever the user names a plan document and asks to continue, implement, or work on it — e.g. "bite analytics plan", "do the next phase of the pacing plan", "continue the analytics plan" — even if they don't say the words "phase" or "PR". The plan is a markdown file in the repo whose final section is a numbered list of phases with `- [ ]` checklists.
---
# Implement Next Phase

Given the name of a plan document, implement exactly one phase — the next incomplete one — mark it complete inside the plan document, open a PR, and iterate on it until the PR checks are green.

## 1. Locate the plan document

The user gives a loose, human name like "bite analytics plan". Find the file:

- List tracked markdown files (`git ls-files '*.md'`) and match the name against filenames and, if needed, the documents' H1 titles. Normalize (case, spaces vs. `_`/`-`) before matching.
- Never ask the user anything — resolve autonomously:
  - Exactly one plausible match → proceed.
  - Multiple plausible matches → prefer the ones that still have unimplemented phases (an unchecked `- [ ]` item); if more than one of those remains, pick the best match and proceed.
  - No plausible match → do nothing: report that no plan document was found and stop.

## 2. Identify the next phase

Read the entire plan document, not just the phases. The sections before the phase list (guiding principles, scope, settled decisions, architecture) are binding constraints on how the phase must be implemented.

- The next phase is the first phase whose checklist contains at least one unchecked `- [ ]` item.
- If every phase is fully checked, report that the plan is complete and stop.
- Do not look at open PRs, branches, or what other agents may be doing. The plan file on `main` is the single source of truth for what is done.

## 3. Branch

- Update `main` (`git fetch` + checkout/reset to `origin/main`).
- Create a branch named `phase-<N>-<short-slug>` off it, e.g. `phase-2-bite-analytics-averages`.

## 4. Implement the phase

- Do every checklist item of the phase — no more, no less. Never start the next phase, even if it is small or convenient.
- Follow the plan's stated file paths, names, constants, and design decisions exactly. If the plan and the code have drifted in a way that makes an item impossible as written, implement the closest faithful equivalent and note the deviation in the PR description.
- Match the existing code style and the precedents the plan points to.

## 5. Verify locally — without installing anything

The phase's Verify bullet is the definition of done. Run the verification it describes (e.g. the repo's analyzer/tests) only if the required tools are already available in the environment.

- Tools present → run them, fix failures, repeat until green.
- Tools missing → do not install them. Skip local verification and rely on the PR checks in step 7 instead. Say so in the PR description.

## 6. Mark the phase complete

In the same branch, edit the plan document: flip every checklist item of the implemented phase from `- [ ]` to `- [x]`, including its Verify bullet. (The PR is not finished until its checks are green, so the checked state is truthful by the time the PR is mergeable.)

If this phase was the **last** one — after flipping it, no unchecked `- [ ]` item remains anywhere in the document — also mark the plan itself complete: if the document carries a top-level status line or banner (e.g. `> **Status: ready to build.**`, "Nothing here is built yet", or similar), update it to say the plan is shipped/complete. Leave that banner alone on any earlier phase, and touch nothing else in the document either way.

## 7. Open the PR and iterate until green

- Match the repo's commit-message convention. Check first (a `CLAUDE.md`/`CONTRIBUTING` note, a `commitlint`/`release-please` config, or the existing `git log`). If the repo uses **Conventional Commits**, both the commit message and the PR title must carry a type prefix (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, …) chosen from what the phase actually did — user-facing behaviour is usually `feat:`, pure-logic/test-only phases often `test:` or `refactor:`. This is not cosmetic: a squash-merge takes its subject from the PR title, and tools like release-please parse that subject to compute the next version, so a non-conforming title lands a commit that breaks versioning.
- Commit with a concise message; the commit includes both the implementation and the plan-document update.
  - Conventional-Commits repo: `<type>: <phase title> (Phase <N>)`, e.g. `feat: daily bites chart card (Phase 5)`.
  - Otherwise: `Phase <N>: <phase title>`.
- Push and open a PR against `main` using whatever GitHub access is available (the `gh` CLI or a GitHub MCP tool — use whichever exists; do not install anything).
  - Title: same convention as the commit — `<type>: <phase title> (Phase <N>)` where Conventional Commits are used, otherwise `Phase <N>: <phase title> (<plan name>)`.
  - Body: what was implemented, keyed to the phase's checklist; how it was verified (locally, or deferred to PR checks); any deviations from the plan.
- Immediately after the PR is created, subscribe this session to its activity (`subscribe_pr_activity`, or the equivalent for the GitHub access in use) so CI results and review comments flow back into the conversation. If no subscription mechanism is available, skip this silently.
- Watch the PR checks (`gh pr checks --watch` or the MCP equivalent). While any check fails: read the failure logs, fix, commit, push, and watch again.
- After 5 failed fix rounds, stop pushing and report: link the PR, summarize what still fails and why, and suggest next steps.

## 8. Report

End by giving the user the PR link, the phase implemented, and a one-paragraph summary of what changed and how it was verified. One phase, one PR — then stop.
