---
spec: format.spec.md
---

## User Stories

- As a Swift developer, I want to format my code with a single command so that I don't have to remember swift-format flags.
- As a team lead, I want a locked style configuration so that all team members use the same formatting rules.

## Acceptance Criteria

- [ ] `fledge swift-format` formats all `.swift` files in the project recursively
- [ ] The bundled CorvidLabs style config is applied by default
- [ ] `--use-project-config` allows opting out of the bundled config
- [ ] Specific file paths can be passed as arguments
- [ ] Exit code is 0 on success, non-zero on failure
- [ ] Works both as a Fledge plugin and standalone CLI

## Constraints

- Must support macOS 14+ and Linux
- Must not require additional dependencies beyond swift-format
- Must handle large projects efficiently (use --parallel)

## Out of Scope

- Custom rule extensions beyond what swift-format supports
- IDE integration (VS Code extension, etc.)
