---
name: vaultw
description: Write a new note into the user's Obsidian vault from a fleeting idea or a summary of the current chat. Callable from any directory - vault path, target folder, and templates all come from $OBSIDIAN_VAULT or ~/.claude/obsidian-vault. Use when the user says "save this to my vault", "note this down", "capture this idea", "summarise this chat into a note", or invokes /vaultw. Creates one new note; never rewrites existing ones.
---

# Vault Write — capture into the vault

Create **one new note** in the vault from either a fleeting idea or a summary
of the current conversation. Where notes land is config, not an argument.

The whole arg is plain language — no flags, no options:

```
/vaultw <what to capture, plus optionally which template and what title>
```

With no arg and an ongoing conversation, assume "summarise this chat".

## Locate the vault and read config

Config is the same file the `vault` and `vaultq` skills use. First non-comment
line is the vault path; keyed `key: value` lines below it hold write settings.

1. `$OBSIDIAN_VAULT` if set, else first non-comment, non-empty, non-keyed line
   of `~/.claude/obsidian-vault` (expand `~`).
2. Nearest ancestor of cwd containing `.obsidian/` as a last resort.

```bash
cfg=~/.claude/obsidian-vault
vault="${OBSIDIAN_VAULT:-$(grep -vE '^\s*(#|$)' "$cfg" 2>/dev/null | grep -vE '^[a-z.]+:' | head -1)}"
vault="${vault/#\~/$HOME}"; vault="${vault%/}"

cfgval() { grep -E "^$1:" "$cfg" 2>/dev/null | head -1 | sed -E "s/^$1:[[:space:]]*//"; }
dir="$(cfgval 'write-dir')"              # e.g. 000 Inbox
name="$(cfgval 'template')"              # default template name
tpl="$(cfgval "template\.$name")"        # name -> vault-relative path
```

Template paths are vault-relative. **Read the template file** — it is the
user's, its shape is not known in advance and must never be guessed.

Stop and say so, rather than improvising, when: the vault does not resolve;
`write-dir` is unset or missing on disk; or the resolved template file does not
exist. Do not create folders, template files, or guess a path.

## Folder and template

**Folder is never an argument.** Notes go in the configured `write-dir`,
shared by every vault skill. If the user names a different folder in the
request, use it only if it already exists in the vault; otherwise say so and
write to `write-dir`. If `write-dir` is unset or missing on disk, stop and ask
— do not create folders, do not write to the vault root.

**Template comes from the request in plain language**, matched against the
`template.<name>` lines in the config: "use the paper template", "book note",
"as a daily note" → `paper`, `book`, `daily`. Nothing named → use the
`template:` default (`ai` → `Templates/AI Template.md`), for fleeting ideas and chat
summaries alike. A template named but unknown → list the configured names and
ask; do not pick one.

## Procedure

1. **Resolve** vault, folder, template as above. Read the template file.
2. **Gather the content.**
   - *Fleeting idea*: the user's words are the seed. Keep their phrasing and
     their claim. Sharpen wording, do not add research, do not argue with it.
     Short is correct — a fleeting note that is three lines stays three lines.
   - *Chat summary*: summarise **this conversation**, in detail, for the user
     re-reading it cold in six months. What the problem was, what was tried,
     what worked, what did not, exact commands/file paths/decisions, and what
     is still open. Prefer concrete specifics over tidy prose. Include code
     blocks verbatim when they carry the answer.
3. **Fill the template.** The template is the user's file — follow it, do not
   redesign it. Fill every `{{placeholder}}` it contains from the content:
   Templater only runs inside the Obsidian UI, so a raw `{{...}}` left in the
   written note is a bug.
   - `{{title}}`, `{{body}}`, `{{summary}}`/`{{tldr}}` and friends → the
     gathered content, matched to what the placeholder's name and surrounding
     heading ask for.
   - `{{date}}` → `date +%Y-%m-%d` (or `%Y-%m-%d %H:%M` where a time reads
     better).
   - `{{source}}` → for chat summaries: `Claude Code — <repo or cwd basename>`.
   - A placeholder name may be a prose instruction rather than a field name
     (`{{date and time}}`, `{{one line summary about the note}}`) — do what it
     says, and keep it to what it asks for: one line means one line.
   - Placeholder with nothing to fill → delete the line.
   - Template with no slot for the main content (only a title/summary) → write
     the body below the filled template, under headings you add for it. That is
     the one case where new headings are allowed.
   - Keep every heading and frontmatter field the template ships, even when a
     section ends up empty — the shape is the point. Do not invent sections
     beyond it. Content that fits no section goes under the closest one.
4. **Wikilink into the vault — actively look for links.** A note that connects
   to nothing is a note that will never be found again, so this step is not
   optional: search before writing, do not link only what happens to come to
   mind.
   - Grep/glob the vault for every concept, tool, person, course, and paper the
     content names, plus obvious synonyms and the vault's own title casing.
   - Also check the neighbours: notes one hop out from a hit often name the
     idea better than the hit itself.
   - Link every real match as `[[Note Name]]` at its first natural mention, or
     on a `See:` line at the end when it fits nowhere in the body.
   - **Only notes that exist.** Verify each target resolves to a file before
     writing it; a dangling `[[link]]` is worse than none.
   - Links must be **reasonable**: a real relationship the reader would agree
     with, stated where it makes sense. Do not stuff every match in, do not
     link a word that merely appears in the title, and do not bend the note's
     wording to make a link fit. Two apt links beat eight decorative ones.
   - Found no honest match → say so in the report rather than inventing one.
5. **Name the note.** Title-case, descriptive, filesystem-safe (no `/` `:`).
   Match the folder's existing naming style. Use the user's own title if the
   request gave one.
6. **Check for a collision.** If `<dir>/<title>.md` exists, stop and ask:
   append to it, pick a new name, or cancel. Never overwrite.
7. **Write it**, then report the full path and show the note body back.

## Only ever create

This skill writes exactly one new file, inside the resolved folder. It does not
edit, rename, move, or delete any existing note — not a typo fix, not a
frontmatter tweak, not an index update elsewhere. No `sed -i`, no `mv`, no `rm`
inside the vault root.

Appending to an existing note is allowed **only** after the user says so at
step 6.

## Do not

- Do not pad a fleeting idea into an essay. Capture beats polish.
- Do not summarise a chat into vagueness — specifics are the whole value.
- Do not add outside knowledge the conversation did not contain, unless the
  user asked for the idea to be developed; if you do, mark it as outside
  knowledge in the note.
- Do not leave raw `{{placeholders}}` in the written file.
- Do not create the target folder, or write to the vault root when the folder
  is missing.
