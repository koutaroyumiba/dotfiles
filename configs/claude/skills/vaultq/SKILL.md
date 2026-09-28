---
name: vaultq
description: Survey the user's Obsidian vault and suggest what to research next to expand it — gaps, stubs, dangling links, and rabbit holes that connect to what is already there. Callable from any directory - the vault path comes from $OBSIDIAN_VAULT or ~/.claude/obsidian-vault. Use when the user says "what should I learn", "what should I research", "expand my notes", "where are the gaps", "give me a rabbit hole", or invokes /vaultq. Optional arg = topic to scope the suggestions.
---

# Vault Q — what to research next

Read the vault to find where knowledge thins out, then propose research
directions. Vault decides **what is already known**; outside knowledge supplies
**what could come next**. Every suggestion must anchor to a real note.

This is a suggestion engine, not an answer engine. Do not write the research —
name it, justify it, and show how it wires into existing notes.

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

## Two modes

### Mode A — no prompt given

Pick one rabbit hole worth going down, then offer two alternates in a line each.
Do not dump a menu of ten.

Survey first, then choose. Signals that mark a good rabbit hole:

- **Dangling links** — `[[Wikilinks]]` pointing at notes that do not exist.
  Grep link targets, diff against filenames. A heavily-linked missing note is
  the strongest signal in the vault.
- **Stubs** — notes under ~500 bytes, or empty. `find . -name '*.md' -size -1k`.
- **TODO / `?` / "check this"** markers left in otherwise developed notes.
- **Orphan clusters** — a real topic with notes but nothing linking in or out.
- **Stale but active areas** — a dense cluster untouched for months (`ls -lt`)
  while adjacent areas keep growing.
- **Asymmetry** — one branch of a subject deep, its sibling branch bare
  (e.g. lots on supervised ML, nothing on evaluation).

Bias toward what the vault shows the user actually cares about — the biggest
clusters and most recent edits — not toward whatever is objectively largest.

### Mode B — prompt given

The arg is a direction, not a search query. The user already decided the
subject; the job is to make it land in *their* vault, not a generic syllabus.

1. Find what the vault already holds on and near the topic — the exact notes,
   the adjacent ones, the tags.
2. Identify the actual edge: what they clearly already know vs. where notes
   stop.
3. Suggest 3-6 concrete things to learn, starting from that edge. Skip
   anything the notes show they already have.
4. For each, name the existing note it should link to and why the connection
   is real.

Example shape: vault has Go notes covering syntax, structs, interfaces;
user says "concurrency in Go". Do not suggest "learn goroutines" as if from
zero if [[Goroutines]] already exists — suggest the channel-select-context
progression, point at the note on interfaces for `context.Context` as an
interface, and flag that the vault's [[Deadlock]] note from an OS course is
the same idea in a new setting.

## Output shape

Per suggestion, keep it tight:

- **What to research** — a specific, searchable thing. "Go's `sync.Once` and
  lazy init patterns", not "concurrency primitives".
- **Why now** — the vault-grounded reason. Cite the note: stub, dangling link,
  gap next to [[Note]].
- **Hooks** — which existing notes it connects to, and what the connection is.
  Real `[[Note Name]]`s only.
- **First move** — one concrete entry point: a paper, a doc page, a specific
  question to answer. Enough to start today.

Optionally close with a one-line note on where the resulting note would live,
following the vault's own folder and naming conventions.

## Labelling

Vault claims and outside knowledge get separated. Anything the notes do not
say — a paper title, a technique name, a claim about the field — is outside
knowledge and gets marked once, plainly. Do not blur the two.

## Never edit the notes

**Read-only. No exceptions.** This skill never writes, edits, renames, moves,
or deletes anything in the vault — not a stub fill, not a new note for the
suggested topic, not a frontmatter tweak. No Write, no Edit, no shell
redirect, no `sed -i`, no `mv`/`rm` inside the vault root.

Suggesting a note be created is the point. Creating it is not. If the user
wants the note written, that is a separate, explicit request.

## Do not

- Do not suggest topics with no anchor in the vault — this is expansion of an
  existing base, not a reading list from scratch.
- Do not suggest what the notes already cover well. Check before suggesting.
- Do not produce a flat list of ten equal-weight items. Rank, and commit to a
  lead suggestion.
- Do not answer the research question in the process of suggesting it.
