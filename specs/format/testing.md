---
spec: format.spec.md
---

## Automated Testing

- `Tests/FledgeSwiftFormatTests/FormatTests.swift` — FormatCommand unit tests
- `Tests/FledgeSwiftFormatTests/ArgumentParsingTests.swift` — Plugin argument parsing tests

## Manual QA Checklist

- [ ] Run `swift build -c release` successfully
- [ ] Run `.build/release/fledge-plugin-swift-format` on a test project
- [ ] Verify files are modified in-place
- [ ] Verify bundled config rules are applied (check indentation is 4 spaces)
- [ ] Verify `--use-project-config` uses project's own config
- [ ] Verify no Swift files in `.build/` or `DerivedData/` are touched

## Edge Cases

- Empty project with no `.swift` files
- Project with deeply nested directory structure
- Project with a mix of Swift and non-Swift files
- Running on a file with syntax errors (swift-format should report it)
