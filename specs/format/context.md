---
spec: format.spec.md
---

## Key Decisions

- Use Apple's official swift-format instead of a custom formatter for compatibility and maintenance.
- Embed the CorvidLabs config as a build-time resource so it's always available.
- Support both Fledge protocol mode and standalone CLI mode for flexibility.

## Files to Read First

- `Sources/FledgeSwiftFormat/Plugin.swift` — argument parsing and command dispatch
- `Sources/FledgeSwiftFormat/FormatCommand.swift` — format execution logic
- `Sources/FledgeSwiftFormat/Resources/.swift-format.json` — bundled configuration

## Current Status

- Plugin structure scaffolded
- FormatCommand implemented
- Tests written for format arguments and execution

## Notes

- The bundled config enforces: 4-space indent, 120-char lines, K&R braces, no force unwrap/try.
- File discovery excludes common non-source directories to avoid formatting generated code.
