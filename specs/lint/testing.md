---
spec: lint.spec.md
---

## Automated Testing

- `Tests/FledgeSwiftFormatTests/LintTests.swift` — LintCommand unit tests

## Manual QA Checklist

- [ ] Run `fledge swift-format --lint` on a project with style issues
- [ ] Verify violations are printed but files are not modified
- [ ] Run `fledge swift-format --check` on a project with style issues
- [ ] Verify exit code is non-zero
- [ ] Run `fledge swift-format --check` on a clean project
- [ ] Verify exit code is 0

## Edge Cases

- Project with no violations (clean output)
- Project with only warnings (non-strict should pass, strict should fail)
- Project with syntax errors (should always fail)
- Empty project with no Swift files
