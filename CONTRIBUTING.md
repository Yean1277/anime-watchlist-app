# Contributing

Thanks for helping out! This project follows **GitHub Flow** — a lightweight
branch-and-pull-request workflow that keeps `main` always deployable.

## The workflow in brief

1. **Branch** off the latest `main` using a category-prefixed name (see below).
2. **Commit** small, focused changes with conventional-commit messages.
3. **Open a Pull Request** against `main`; fill in the PR template.
4. **Review & CI** — get a review and make sure checks pass.
5. **Merge** into `main`, then **delete** the branch.

`main` is the single long-lived branch. There is no `develop` or `release`
branch — every change is a short-lived branch that merges back into `main`.

## Branch naming

Use a **category prefix** so every branch (and its PR) is self-categorizing:

```
<category>/<short-kebab-description>
```

Optionally include an issue number: `<category>/<issue#>-<description>`
(e.g. `feat/42-status-filter`).

| Prefix      | Use for                                  | Example                          |
| ----------- | ---------------------------------------- | -------------------------------- |
| `feat/`     | new feature                              | `feat/status-filter-tabs`        |
| `fix/`      | bug fix                                  | `fix/search-debounce`            |
| `docs/`     | documentation only                       | `docs/setup-guide`               |
| `refactor/` | restructuring, no behavior change        | `refactor/watchlist-provider`    |
| `test/`     | adding or fixing tests                   | `test/status-serialization`      |
| `chore/`    | deps, tooling, config, housekeeping      | `chore/bump-supabase`            |
| `ci/`       | CI/CD or workflow changes                | `ci/web-deploy-cache`            |

```bash
git switch main && git pull
git switch -c feat/status-filter-tabs
```

## Commit messages

Match the existing history: [Conventional Commits](https://www.conventionalcommits.org)
using the **same categories** as the branch prefixes, with an optional scope.

```
feat(watchlist): add status filter tabs
fix(search): debounce Jikan requests to 450ms
docs: document the branching convention
```

Keeping the branch prefix, commit type, and PR category aligned makes history
easy to scan.

## Pull requests

- Base every PR on `main`.
- The PR title should mirror the branch category, e.g.
  `feat: add status filter tabs`.
- Fill in the [PR template](.github/pull_request_template.md), including the
  **Type of change** checkbox.
- Keep PRs small and focused — one category of change per PR.
- Make sure `flutter test` passes before requesting review.

## Recommended branch protection (repo admin)

Branch protection can't be configured from the codebase — set it once in the
GitHub UI under **Settings → Branches → Add branch ruleset** for `main`:

- Require a pull request before merging.
- Require status checks to pass (the deploy/build workflow).
- Block direct pushes to `main`.

## Local checks

```bash
flutter pub get
flutter test
```

See [SETUP.md](SETUP.md) for full environment setup and
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for how the code is organized.
