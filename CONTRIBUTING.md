# Contributing

Thanks! Project use **GitHub Flow** — light branch-and-pull-request flow. Keeps
`main` always deployable.

## The workflow in brief

1. **Branch** off latest `main`. Category-prefixed name (see below).
2. **Commit** small, focused changes. Conventional-commit messages.
3. **Open Pull Request** against `main`. Fill PR template.
4. **Review & CI** — get review. Checks must pass.
5. **Merge** into `main`. Then **delete** branch.

`main` = single long-lived branch. No `develop`, no `release` branch. Every
change short-lived branch. Merges back into `main`.

## Branch naming

Use **category prefix**. Every branch (and PR) self-categorizing:

```
<category>/<short-kebab-description>
```

Optional issue number: `<category>/<issue#>-<description>`
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

Match existing history: [Conventional Commits](https://www.conventionalcommits.org).
**Same categories** as branch prefixes. Optional scope.

```
feat(watchlist): add status filter tabs
fix(search): debounce Jikan requests to 450ms
docs: document the branching convention
```

Align branch prefix, commit type, PR category. History easy to scan.

## Pull requests

- Base every PR on `main`.
- PR title mirrors branch category, e.g. `feat: add status filter tabs`.
- Fill [PR template](.github/pull_request_template.md). Include **Type of
  change** checkbox.
- Keep PRs small, focused — one category per PR.
- `flutter test` must pass before requesting review.

## Recommended branch protection (repo admin)

Branch protection not configurable from codebase. Set once in GitHub UI under
**Settings → Branches → Add branch ruleset** for `main`:

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
