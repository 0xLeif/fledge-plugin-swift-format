---
spec: lint.spec.md
---

## User Stories

- As a CI pipeline maintainer, I want a strict lint command that fails on style violations so that only properly formatted code is merged.
- As a developer, I want to see style issues without modifying files so I can review and fix them manually.

## Acceptance Criteria

- [ ] `fledge swift-format --lint` diagnoses style issues without modifying files
- [ ] `fledge swift-format --check` exits non-zero on any style violation (CI mode)
- [ ] Violations are printed to stdout with file path, line, and rule name
- [ ] The bundled CorvidLabs config is applied by default
- [ ] Works both as a Fledge plugin and standalone CLI

## Constraints

- Must support macOS 14+ and Linux
- Must not modify files in lint mode
- Must use `--parallel` for performance on large codebases

## Out of Scope

- Auto-fix suggestions beyond what swift-format provides
- SARIF or other structured output formats (future enhancement)
