# Spec directory rules

This directory holds the requirement/spec documents that drive development. Read this before creating or editing any spec.

## File naming

Every spec file is named:

```
yyyymmdd-<FEATURENAME>.md
```

`yyyymmdd` is the date the spec was first created (not last edited). `<FEATURENAME>` is a short kebab/camel-ish slug identifying the feature or area (e.g. `20260925-attribute-inspector-redesign.md`).

## Old specs are immutable

Once a spec file exists, its original content is never rewritten or deleted. If requirements change later, or a later spec conflicts with an earlier one, **append** a new section to the end of the old file (or add a new dated spec that references it) explaining the change and why. The historical record of what was originally decided must stay intact and legible.

## One commit = one clean, final state

Requirements change back and forth during a single round of work before they're committed — that's expected. But the spec content that actually gets **committed** must reflect only the final, settled state of that round, not the churn it took to get there.

Concretely, before committing any spec change:

- Do one last review pass over what you're about to commit.
- If the discussion went A → B → A, the committed document should read as if only A ever happened. Remove B entirely — don't leave it in as a rejected alternative, a "we considered but decided against" note, or a strikethrough. If the final state is A, B never existed as far as the committed spec is concerned.
- Never phrase a committed spec as "we do A, not B" (or "we removed B", "instead of B", etc.) when B was just an intermediate idea that got reverted before commit. That framing keeps B alive as information a future reader has to parse and discard, and it's actively misleading — B was never real. Just state A.
- This rule is about **churn inside one uncommitted round of iteration**, not about genuine history. A real, previously-committed decision that gets superseded later is a real change — record that with an appended note (per "Old specs are immutable" above), not by scrubbing it.

The goal: anyone reading a committed spec later should see a clean statement of what was decided, with zero noise from intermediate back-and-forth.
