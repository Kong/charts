# Contributing to Kong Helm charts

Feel free to contribute fixes or minor features, we love to receive pull
requests! If you are planning to develop a larger feature, please submit a
GitHub issue describing your proposal first, to discuss it with the chart
maintainers.

## Submitting a pull request

### Preparing a pull request

Before submitting a pull request, please run through the following steps:
- Rebase your branch off the current tip of the `main` branch.
- Run `helm lint` and correct any issues it finds.
- If your change adds new user-facing (exposed in values.yaml) features or
  changes existing features, update README.md accordingly. Documentation should
  adhere to the [Microsoft Writing Style Guide](https://docs.microsoft.com/en-us/style-guide/welcome/).

All contributors must sign our Community License Agreement. If you have not yet
signed it, we will add a comment asking you to do so.

### Review process

Changes to Kong charts undergo automatic and manual review. When you create a
pull request, CI will run automated tests against a standard set of values.yaml
configurations. If any fail, you will receive an email alert with details of
the failure.

If changes are requested or tests find an issue with your changes, please
add separate fix commits on top of your initial pull request. Do not squash
changes; the maintainers will squash as needed when merging the pull request.

### Accepted pull requests

Accepted pull requests are merged into the `main` branch and are not typically
released immediately. The chart maintainers periodically merge a version bump
into `main` to create a release.

## Commit message format

To maintain a healthy Git history, we ask that you follow the [Kong commit
message format](https://github.com/Kong/kong/blob/master/CONTRIBUTING.md#commit-message-format).

Briefly, commit message headers should begin with _type(area)_, where type
indicates the type of change and area indicates what section of the chart it
updates. For example:

- `feat(services) add support for foobar` for a new feature in the Service
  templates.
- `docs(hybrid) clarify foobar` for documentation updates related to hybrid
  mode.
- `fix(helpers) handle foobar correctly` for a bugfix in a generic helper
  template.

### Header

Your commit header/subject should contain a succinct description of the change.
It should be written so that:

- It uses the present, imperative tense: "fix typo", and not "fixed" or "fixes"
- It is **not** capitalized: "fix typo", and not "Fix typo"
- It does **not** include a period. :smile:

### Body

The body of your commit message should contain a detailed description of your
changes. Ideally, if the change is significant, you should explain its
motivation, the chosen implementation, and justify it.

Lines in the commit messages should not exceed 72 characters.

## Stale issue and pull request policy

To ensure our backlog is organized and up to date, we will close issues and
pull requests that have been inactive awaiting a community response for over 2
weeks. Please feel free to reopen an inactive closed issue if you would like to
continue work on it.

