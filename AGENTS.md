# AGENTS.md

Guidance for AI coding agents working in this repository. Read this before
making changes; it tells you how to build, test, and — just as importantly —
what this codebase deliberately does not do.

## Project overview

Reusable Terraform modules that bootstrap **per-repository** GitHub
governance and optional GCP GitHub OIDC / Workload Identity Federation.
Consumers source a module by git tag from their own Terragrunt stack.
Canonical GitHub layout (what agents create and manage):

- `bootstrap/github/repository` — settings, teams, branch protection, CODEOWNERS
- `bootstrap/github/actions` — environments and Actions variables only
  (`manage_repository_settings = false`)
- `bootstrap/gcp` — optional WIF / identity, applied first

This repository does **not** manage a GitHub organization and does **not**
write GitHub Actions workflow YAML. Do not add org-level resources
(members, org rulesets, org secrets) or invent workflow files for
consumers.

## Environment

- Terraform `>= 1.7`, Terragrunt for stacks under `bootstrap/github/` and
  `examples/`
- GitHub operations need `GITHUB_TOKEN` and `GITHUB_OWNER`
- GCP identity examples need Application Default Credentials and the
  `EXAMPLE_*` overrides documented in
  `examples/repository-consumer/README.md`
- Agents should not `apply` or deploy unless explicitly asked

## Commands

Prefer the Makefile targets; `make` lists them all.

| Task                                  | Command        |
| ------------------------------------- | -------------- |
| Format                                | `make fmt`     |
| Validate modules and stacks           | `make validate`|
| Lint (TFLint, skipped if missing)     | `make lint`    |
| Trivy config scan (skipped if missing)| `make scan`    |
| **Full pre-push gate (what CI runs)** | **`make check`** |

Run `make check` before considering any code change done. A change that
does not pass `make check` is not finished.

## Architecture invariants

These are load-bearing. Breaking them breaks the consumer contract.

1. **Per-repo only.** Modules manage one GitHub repository (and optional
   GCP identity for that repo). Org-wide policy lives elsewhere.
2. **Existing repos import by default.**
   `import_existing_repository = true` avoids `422 name already exists`
   when `manage_repository_settings = true`. Set it `false` only when the
   stack should create a brand-new repository.
3. **No secrets in examples.** Examples take project IDs, owners, and
   repo names from environment variables. Never commit tokens, keys, or
   live project numbers.
4. **Pin by tag.** README and examples source
   `?ref=vX.Y.Z`. Do not tell consumers to track `main`.
5. **Conventional commits.** `feat:` / `fix:` / `BREAKING CHANGE:` drive
   `semantic-release`. PR titles are checked in CI.
6. **Nested GitHub stacks.** Agents create `bootstrap/github/repository`
   and `bootstrap/github/actions`, not sibling `github-repository` /
   `github-actions` folders or `repo` / `env-vars` names. Leave an
   existing non-standard path in a consumer unless the human asks to
   move state.

## Code style

- Terraform `>= 1.7`. Run `make fmt` rather than hand-formatting.
- Variable descriptions are sentences. Defaults are the safe choice
  (private visibility, no team access, no environments).
- Comments only for non-obvious intent (see the `import` block in
  `modules/github-repository/main.tf`).
- Keep examples generic: `your-org`, `your-repo`, `your-project`. Do not
  re-introduce a company name as a default.

## Testing

CI runs `terraform fmt -check -recursive` and `terraform init` +
`validate` for each directory under `modules/`. There is no live GitHub
or GCP apply in CI. A change that cannot validate with `-backend=false`
is not finished.

New module inputs need a matching `variable` description, a default or a
clear required contract, and a README / example mention when they change
the consumer path.

## CI/CD

- `.github/workflows/ci.yml` = conventional PR title + Terraform checks
- CodeQL and dependency-review scan PRs
- Releases: pushes to `main` run `semantic-release` and cut `vX.Y.Z`
- `CHANGELOG.md` follows Keep a Changelog — add user-facing changes
  under `## [Unreleased]`

## Boundaries for agents

- **Never commit secrets.** `GITHUB_TOKEN`, GCP keys, and `.env` files
  stay out of git. `.gitignore` already covers the usual names; keep it
  that way.
- **Don't apply Terraform** unless the human explicitly asks.
- **Don't weaken security posture.** Signed commits, CODEOWNERS, protected
  production environments, and least-privilege workflow permissions are
  features. Propose tightening, not loosening.
- **Don't add a runtime or a workflow generator.** This is a Terraform
  library. If the request needs GitHub Actions YAML, say so and stop.
- **Keep dependencies minimal.** Prefer the GitHub and Google providers
  you already have over new tools.
