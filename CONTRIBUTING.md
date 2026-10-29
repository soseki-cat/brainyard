# Contributing to Brainyard

Thanks for improving the framework.

## Before opening a pull request

1. Keep personal data out of examples and test fixtures.
2. Explain the behavior the change affects.
3. Add or update a rule scenario when automation behavior changes.
4. Run:

```powershell
pwsh ./tools/tests/test_scan_changes.ps1
pwsh ./tools/wiki_check.ps1 -IncludeWarnings
```

5. Report tested and untested areas separately.

## Commit style

Use a short imperative subject. Conventional Commit prefixes are welcome but not required:

```text
feat: add a new card template
fix: exclude a raw-material path from scanning
docs: clarify scheduler setup
test: cover checkpoint rollback
```

## Pull requests

Include:

- motivation;
- changed behavior;
- validation commands and results;
- migration notes;
- security or privacy impact.

## Scope

Keep the core framework domain-neutral. Domain-specific additions belong in a user's vault or a separate template, not in the default skeleton.

## License

By contributing, you agree that your contribution is licensed under the repository's MIT License.
