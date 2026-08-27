---
name: vault
description: Answer a question using ONLY the notes in the user's Obsidian vault, citing every source note. Callable from any directory - the vault path comes from $OBSIDIAN_VAULT or ~/.claude/obsidian-vault. Use when the user says "from my vault", "from my notes", "what do my notes say", asks a question about their notes' subject matter, or invokes /vault. Never mixes in outside knowledge.
---

# Vault Answer — closed-book, cited

Answer from the vault and nothing else. The vault is the only corpus. Training
knowledge, web, and inference beyond what notes state are all off-limits for the
answer body.

## Locate the vault

The vault is configured, not inferred from cwd — this skill works from any
directory. Resolve in this order, first hit wins:

1. `$OBSIDIAN_VAULT` if set.
2. First non-comment, non-empty line of `~/.claude/obsidian-vault` (expand `~`).
3. Nearest ancestor of cwd containing `.obsidian/`.

```bash
vault="${OBSIDIAN_VAULT:-$(grep -vE '^\s*(#|$)' ~/.claude/obsidian-vault 2>/dev/null | head -1)}"
vault="${vault/#\~/$HOME}"
```

If the config file lists several paths and the user's request does not name
one, ask which vault. If nothing resolves or the path is missing, say so and
ask the user to set it in `~/.claude/obsidian-vault` — do not guess a path or
fall back to searching the home directory.

All reads stay inside the resolved root. Skip `.obsidian/`, `.trash/`, `.git/`.

## Procedure

1. **Search wide before answering.** One grep is not enough.
   - Grep the question's key terms over `**/*.md`, plus synonyms and likely
     note-title casing.
   - Glob filenames — vault notes are often titled as the concept itself.
   - Check `#tags` and frontmatter fields (`tags:`, `aliases:`) for the topic.
   - Follow `[[wikilinks]]` out of every hit one hop; linked notes usually hold
     the rest of the answer. Follow a second hop when the first is thin.
   - Check for a MOC / index / "map of content" note on the topic.

2. **Read the hits in full**, not just the matching line. Note context matters —
   a claim under "Open questions" or "TODO" is not a settled claim.

3. **Answer using only what those notes assert.** Synthesis across notes is
   fine; new facts are not.

## Citation rules

Every substantive claim gets a source inline, in Obsidian link form:

> Spaced repetition works because retrieval effort strengthens recall
> ([[Spaced Repetition]], §"Why it works").

- Cite `[[Note Name]]`, plus heading or line number when the note is long.
- Multiple notes for one claim: cite all.
- End with a **Sources** list of every note read that fed the answer.

## Gaps — the important part

When the vault is silent or partial, say so explicitly. Do not paper over it.

- Nothing found: "**Not in vault.** No note covers X. Closest: [[Y]] (adjacent
  only)." Then offer: "Want an answer from outside knowledge instead?" — and
  wait for a yes before giving one.
- Partial: answer the covered part, then flag the uncovered part in a
  **Gaps in the vault** section.
- Notes contradict each other: report both sides with their sources. Do not
  pick a winner using outside knowledge; say which note is newer if
  frontmatter dates allow.
- Note is uncertain/stubby (marked TODO, `?`, "check this"): carry that
  uncertainty into the answer rather than stating it as fact.

## Never edit the notes

**Read-only. No exceptions.** This skill never writes, edits, renames, moves,
or deletes anything in the vault — not a typo fix, not a new note, not a
frontmatter tweak, not "while I'm here". No Write, no Edit, no shell redirect,
no `sed -i`, no `mv`/`rm` inside the vault root.

If a note needs changing, say what should change and where, and let the user
make the change themselves. Do this even if the user asks mid-answer for a fix
— tell them this mode is read-only and hand them the exact edit as text.

## Do not

- Do not fill gaps with training data, even "obvious" background.
- Do not correct a note's errors in the answer body — flag them separately
  under **Possible errors in notes** if certain, marked as outside knowledge.
