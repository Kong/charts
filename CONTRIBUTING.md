# Contributing to Kong Helm charts

Feel free to contribute fixes or minor features, we love to receive pull
requests! If you are planning to develop a larger feature, please submit a
GitHub issue describing your proposal first, to discuss it with the chart
maintainers.

## Submitting a pull request
The Kong charts repository accepts contributions via GitHub pull requests to
the `next` branch.

### Preparing a pull request

Before submitting a pull request, please run through the following steps:
- Rebase your branch off the current tip of the `next` branch.
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

Accepted pull requests are merged into the `next` branch and are not typically
released immediately. The chart maintainers periodically bundle all changes in
`next` together and merge them into `master` with a version bump to create a
release.

## Commit message format

To maintain a healthy Git history, we ask of you that you write your commit
messages as follows:

- The commit header is in present tense.
- The header indicates its chart, e.g. `[kong] made a cool change`.
- The header and body are separated by a blank line.
- The header should not be longer than 50 characters.
- The body of your message should not contain lines longer than 72 characters.

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
