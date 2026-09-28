# Versioning

This project uses [Semantic Versioning](https://semver.org/) in the form `MAJOR.MINOR.PATCH`.

- **MAJOR** versions contain incompatible changes to the repository's setup workflow, configuration layout, or ownership of installed tools.
- **MINOR** versions add backward-compatible features, managed tools, configurations, or setup steps.
- **PATCH** versions contain backward-compatible fixes and documentation improvements.

Examples:

- `2.0.0` — a breaking redesign of the bootstrap system.
- `2.1.0` — a new optional installer step that does not break the existing workflow.
- `2.1.1` — a fix to that installer step.

## Release status

Work that has not yet been released is documented as **Unreleased** in [CHANGELOG.md](./CHANGELOG.md). The target version identifies the release that the work is intended to become.

Git tags for releases should use a `v` prefix, such as `v2.0.0`. The version itself remains `2.0.0`.

## What counts as a breaking change

For this dotfiles project, a major version increase is appropriate when users must take manual action or when an established interface changes. Examples include:

- Changing setup commands or command-line flags incompatibly.
- Moving managed configuration files or changing symlink targets.
- Reassigning a tool between package managers.
- Dropping support for an operating system or supported environment.
- Removing previously managed behavior without a compatible migration path.

Personal configuration changes that do not affect the documented setup contract may be released as minor or patch changes, depending on their scope.
