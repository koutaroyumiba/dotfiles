# Personal PI Instructions

## Communication

- Be concise unless I ask for detail.
- Prefer structured outputs with clear headings.
- Avoid unnecessary praise or filler.
- If I ask to learn something, explain practically with examples.

## Default Mode

- Default to read-only analysis.
- Do not edit, write, delete, move or rename fies unless I explicitly permit changes.
- Do not run destructive commands.
- Do not modify anything outside the current project unless I explicitly ask.

## Safety

Ask before:
- deleting files
- installing packages
- running migrations
- modifying secrets or `.env` files
- committing or pushing
- changing lockfiles
- touching generated files

## Coding Preferences

- Prefer small, focused changes.
- Follow existing style and project conventions.
- Do not introduce dependencies unless necessary and approved.
- Prefer simple, maintainable code over clever code.
- For TypeScript, prefer explicit types where they improve clarity.
- For Python, prefer readable, idiomatic code.
- For C/C++/Go/systems code, pay extra attention to memory, error handling, concurrency, and edge cases.

## Verification

If changes are made, suggest or run the smallest relevant checks:
- tests
- typescheck
- lint
- build

Do not run expensive or broad checks unless useful.
