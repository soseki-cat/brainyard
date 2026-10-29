# Security Policy

> A knowledge vault often contains more sensitive data than a source-code repository.

## Recommended practice

- Use a private Git remote for personal material by default.
- Keep credentials and tokens outside the vault.
- Treat screenshots and PDFs as potentially sensitive.
- Review image metadata before publishing.
- Do not store identity documents, student numbers, medical records, or authentication secrets in a synced Markdown vault.
- Store `.obsidian/plugins/*/data.json` outside version control because it may contain OAuth tokens.

## Reporting a vulnerability

Open a private security advisory through the repository's GitHub Security tab. Do not include secrets or personal records in a public issue.

## Automated maintenance risks

- AI output can be incorrect.
- A passing validator proves structure, not factual truth.
- A commit is recoverable; a public push may not be effectively reversible.
- Test scheduled automation on a private repository first.

## Supported versions

Security fixes target the latest release on `main`.
