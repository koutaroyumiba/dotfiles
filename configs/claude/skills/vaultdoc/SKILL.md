---
name: vaultdoc
description: Generate a NotebookLM-style document from a slice of the user's Obsidian vault — briefing doc, study guide, FAQ, or timeline and cast of characters — grounded only in the notes and citing every one. Callable from any directory - the vault path comes from $OBSIDIAN_VAULT or ~/.claude/obsidian-vault. Use when the user says "briefing doc", "study guide", "FAQ from my notes", "timeline of", "notebook doc", or invokes /vaultdoc. Read-only; never mixes in outside knowledge.
---

# Vault Doc — NotebookLM artifacts over the vault

Build one long-form document from a **source set** of vault notes. Same closed
book as `vault`: the notes are the only corpus. Training knowledge, web, and
inference past what the notes state are off-limits for the document body.

```
/vaultdoc [brief|study|faq|timeline] <topic, folder, tag, or list of notes>
```

No artifact named → ask which of the four, do not guess. No topic and an
ongoing conversation about the vault → use that topic.

## Locate the vault

Configured, not inferred from cwd. First hit wins:

1. `$OBSIDIAN_VAULT` if set.
2. First non-comment, non-empty, non-keyed line of `~/.claude/obsidian-vault`.
3. Nearest ancestor of cwd containing `.obsidian/`.

```bash
vault="${OBSIDIAN_VAULT:-$(grep -vE '^\s*(#|$)' ~/.claude/obsidian-vault 2>/dev/null | grep -vE '^[a-z.]+:' | head -1)}"
vault="${vault/#\~/$HOME}"; vault="${vault%/}"
```

Nothing resolves, or several vaults listed and the request names none → ask.
Do not guess a path or search the home directory. All reads stay inside the
root. Skip `.obsidian/`, `.trash/`, `.git/`.

## Step 1 — assemble the source set, then show it

The source set is the notebook. Get it wrong and every artifact is wrong, so
build it explicitly before writing a word of the document.

- **Folder given** (`in 200 Papers`, a path) → every `.md` under it, recursive.
- **Tag given** (`#llm`) → grep `#tag` in body plus `tags:` frontmatter.
- **Explicit notes** (`[[A]], [[B]]`) → exactly those, plus one hop of their
  wikilinks when the set is under ~5 notes.
- **Bare topic** → search wide, the way `vault` does: grep key terms and
  synonyms over `**/*.md`, glob filenames (vault notes are often titled as the
  concept), check `#tags`/`aliases:`, look for a MOC or index note, then follow
  `[[wikilinks]]` one hop out of every hit. Second hop when the first is thin.

**Read every note in the set in full.** These documents synthesise across a
corpus — a matching line without its context produces confident nonsense.

Then print the set as a numbered list of `[[Note Name]]` and say how many
notes and roughly how much text, before generating. If it is over ~40 notes,
say so and offer to narrow. If it is 1 note, say so — a briefing doc over one
note is a summary, and the user may have meant a wider slice.

## Step 2 — write the artifact

Every artifact is **cited inline**, `([[Note Name]], §"Heading")`, and ends
with a **Sources** list of every note that fed it. Long note → include the
heading or line number.

### brief — briefing document

Executive-brief shape, for someone who must act on the corpus without reading
it.

1. **TL;DR** — 3–5 bullets, the load-bearing claims only.
2. **Key themes** — one `###` per theme, each opening with the theme stated in
   one sentence, then the evidence from the notes under it.
3. **Notable facts, figures, quotes** — verbatim where the wording matters,
   quoted and cited.
4. **Open questions and contradictions** — what the notes leave unresolved.
5. **Sources**.

### study — study guide

1. **Short-answer questions** — 10–15, each answerable in 2–3 sentences from
   the notes, cited. Answers in a collapsed section *after* all questions, not
   inline.
2. **Essay prompts** — 4–6, no answers. Each must require synthesis across at
   least two notes; name them.
3. **Glossary** — every term the notes define, defined in the notes' own terms.
4. **Sources**.

### faq

8–15 questions a reader would actually ask of this corpus, in the order a
newcomer would ask them, each answered in one short paragraph. Question in
bold, answer under it, cited. Prefer questions the notes answer *well*; if an
obvious question is unanswered, put it under **Unanswered by the notes** at the
end rather than answering it from outside knowledge.

### timeline — timeline and cast of characters

1. **Timeline** — chronological, `**YYYY-MM-DD** — event ([[Note]])`. Coarser
   granularity when notes only give a year or "early 2023"; keep their
   vagueness rather than inventing precision. Undated but ordered events go in
   a **Sequence, undated** list below.
2. **Cast of characters** — every person, org, project, and system the notes
   name, with what the notes say each one is and did. One entry each, cited.
3. **Sources**.

Best fit when the corpus is narrative — a project log, a paper trail, an
incident. On a conceptual corpus, say so and offer `brief` instead.

## Gaps — the important part

Same rule as `vault`: silence in the corpus is reported, never papered over.

- Thin source set: say the document is thin and name what is missing, rather
  than padding it out.
- Notes contradict: report both sides with sources, name the newer one if
  frontmatter dates allow, pick no winner.
- Stubby or `TODO`-marked note: carry that uncertainty into the document; do
  not launder a question mark into a fact.
- Nothing found for the topic: "**Not in vault.**", closest adjacent notes,
  then offer an outside-knowledge version and wait for a yes.

## Read-only

**No writes to the vault. No exceptions** — not the artifact, not a typo fix,
not an index update. No Write/Edit, no shell redirect, no `sed -i`, no `mv`,
no `rm` inside the vault root.

Render the document in the response. Saving it is a separate, user-initiated
step: offer `/vaultw` (writes one new note through the user's template), or
write outside the vault if the user names a path.

## Do not

- Do not fill gaps with training data, even "obvious" background.
- Do not cite a note you did not read in full.
- Do not invent dates, numbers, or attributions the notes do not state.
- Do not merge the four artifacts — one call, one document.
