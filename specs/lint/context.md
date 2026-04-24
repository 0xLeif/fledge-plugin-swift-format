---
spec: lint.spec.md
---

## Key Decisions

- Reuse the same file discovery and config resolution logic as the format command.
- `--check` is a convenience alias for `--lint --strict` to match common CI conventions.
- Lint output is passed through directly from swift-format for familiarity.

## Files to Read First

- `Sources/FledgeSwiftFormat/LintCommand.swift` — lint execution logic
- `Sources/FledgeSwiftFormat/Plugin.swift` — argument parsing

## Current Status

- LintCommand implemented
- Tests written for lint arguments and strict mode
- `--check` alias wired in argument parser

## Notes

- In non-strict mode, swift-format may exit 1 for style violations but we don't throw. The violation output is printed and the plugin exits 0.
- In strict mode, we propagate the non-zero exit as an error so CI pipelines fail.
