# Design References

> Brainyard is an original framework assembled from tested local workflows. It does not copy application code from the projects below.

| Reference | What was adopted | What was not adopted |
|---|---|---|
| [Obsidian documentation](https://docs.obsidian.md/Home) | Plain-Markdown vaults, properties, internal links, and editable views | A dependency on one proprietary database |
| [Basic Memory](https://github.com/basicmachines-co/basic-memory) | Optional semantic search over durable Markdown knowledge | Mandatory indexing or AGPL-licensed code reuse |
| [PARA](https://fortelabs.com/blog/para/) | Action-aware separation of durable areas, projects, and source resources | The exact PARA folder names and workflow |
| [AGENTS.md](https://agents.md/) | Repository-local operating instructions for coding agents | Any claim of affiliation with the AGENTS.md project |
| [GitHub community profile guidance](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/about-community-profiles-for-public-repositories) | README, license, contribution, security, and issue templates | GitHub-only hosting requirements |
| [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) | Human-readable release history | Strict release automation |
| [Semantic Versioning](https://semver.org/) | Version labels for reusable releases | A guaranteed compatibility promise before `1.0.0` |
| [MIT License](https://choosealicense.com/licenses/mit/) | Permissive reuse | Any warranty or endorsement |

## Provenance statement

The framework generalizes ideas exercised in a private, tested Obsidian workflow:

- Markdown as the source of truth;
- raw evidence separated from synthesized knowledge;
- explicit classification and merge rules;
- Git checkpoints before risky work;
- change discovery based on both working-tree state and commit history;
- validation before commit;
- rebuildable semantic indexing;
- deferred maintenance during idle periods.

All personal examples, education records, project details, credentials, scores, and private links were excluded from this public framework.

## Third-party software

Brainyard's scripts call external tools when configured, but the repository does not vendor or redistribute them. Review each dependency's current license and security posture before production use.
