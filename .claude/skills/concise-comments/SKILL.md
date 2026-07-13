---
name: concise-comments
description: >-
  Write concise code comments that say only what the code can't make clear on its
  own. Use whenever writing or editing comments in this repo's source (Dart under
  lib/ and test/), whenever asked to "clean up comments", "tidy comments", or told
  "the comments are too verbose", and when reviewing a diff before committing.
  Favours well-named code over narration, keeps comments self-contained (no plan
  phases, spec sections, or ticket IDs), and trims anything that restates the
  code. Apply proactively — a verbose or plan-referencing comment is worth fixing
  even if the user didn't single it out.
---

# Concise comments

The code is the primary documentation. A comment is worth writing when a specific
piece of code won't be clear on its own — and then it should be the shortest thing
that supplies the missing understanding. Start from "the code speaks for itself,"
and add a comment only where that breaks down.

## Comment what the code can't say

Clear code already shows *what* it does. A comment adds what a reader can't get
from the code itself: the reason behind a choice, a constraint, a gotcha, a
subtle ordering, a contract a caller must honour. Reach for a comment when one of
those is in play; skip it when the line already tells the whole story.

## Keep comments inside the repository

Write for a reader who has only this repo and its git history — not the plan,
phase list, or ticket you happen to be working from. Describe the code and its
domain, not the process that produced the change. Phase numbers (`Phase 10`),
spec sections (`§3b`), and ticket IDs (`JIRA-431`, `#58`) belong in the commit
message, PR, or plan doc; in source they are noise to everyone who arrives later.
Likewise, describe the code at hand, not how some other feature happens to work.

## Say what a thing is

State a thing directly rather than by contrast. "A local ticker rebuilds the zone
over time" lands cleanly; "clock-driven, *not* data-driven" makes the reader
wonder who thought otherwise. A contrast is worth including only when it heads off
a specific wrong assumption a reader is genuinely likely to make — for example,
warning against a tempting alternative that would introduce a bug.

## Name the intent, not the mechanics

Describe what code is *for*, not the expression it uses to get there. "The time
since the last bite" stays true across refactors; "`now − lastBite`" duplicates
the line below it and goes stale the moment that line changes. A good comment
survives a rewrite of the code beneath it.

## Let a field's name carry its meaning

Name members well enough that they don't need a comment. Add one only to say what
a field *represents* when the name and type can't — not to narrate where it is
read or how it is kept in sync, which the code already shows. A well-named field
usually needs nothing.

Before:
```dart
// The pacing reference point, held in memory. The live view derives every
// zone from `now − _lastBiteAt`; the store is not re-read per tick.
DateTime? _lastBiteAt;
```
After:
```dart
DateTime? _lastBiteAt;
```

## Before / after

**Insight worth keeping, trimmed of scaffolding:**
Before: `// Publish every tick, not just on a zone change, so the countdown readout (Phase 10) updates within a single zone — driven by this same clock ticker.`
After: `// Publish on every tick so the countdown keeps updating within a zone.`

**A line that only restates itself — drop the comment:**
```dart
// Loop over the bites and add each one to the list.   ← remove this
for (final bite in bites) {
  result.add(bite);
}
```

**A genuine gotcha, kept:** a comment that stops someone from "simplifying" into a
bug is doing real work — the case where a contrast earns its place.
`// day + 1 via the DateTime constructor keeps month/year rollover and DST correct.`

## Cleaning up existing comments

When tidying comments or reviewing a change before commit, work from the diff, not
the whole tree:

1. `git diff` (and `git diff --staged`) for the added/changed lines.
2. For each comment, ask: *would this help a reader who has only the code?* Keep
   what supplies missing understanding; trim scaffolding, outside references, and
   restatements of the code.
3. When a comment mixes a real insight with noise, keep the insight and cut the
   rest rather than deleting the whole line.
4. Touch only comments — this is an editing pass, not a refactor.

## Judgment

This is a bias toward clarity, not a war on comments. A genuinely subtle invariant
deserves a sentence or two. The single test behind all of the above: *does this
comment tell a future reader something the code can't?* If yes, keep it, tightly
worded. If not, the code already says it.
