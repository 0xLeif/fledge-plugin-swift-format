# Contributing

Thank you for considering a contribution to `fledge-plugin-swift-format`.

## Development Setup

```bash
git clone https://github.com/0xLeif/fledge-plugin-swift-format.git
cd fledge-plugin-swift-format
swift build
swift test
```

## Before Submitting

1. Run tests: `swift test`
2. Run self-lint: `swift-format lint --strict -r --configuration .swift-format.json Sources Tests`
3. Run spec-sync check: `specsync check --strict`
4. Update relevant specs if the public API changes

## Commit Style

- `Add:` new feature
- `Fix:` bug description
- `Update:` existing feature
- `Remove:` deleted functionality
- `Refactor:` code restructuring

## PR Format

```markdown
## Summary
- Bullet points

## Test Plan
- [ ] Tests pass locally
```
