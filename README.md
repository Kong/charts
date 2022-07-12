# Kong Helm Charts

This is the official Helm Charts repository for installing Kong on Kubernetes.

## Setup

```bash
$ helm repo add kong https://charts.konghq.com
$ helm repo update

# Helm 2
$ helm install kong/kong

# Helm 3
$ helm install kong/kong --generate-name --set ingressController.installCRDs=false
```

## Documentation

The documentation for Kong's Helm Chart is available at
[here](https://github.com/Kong/charts/blob/main/charts/kong/README.md).

## Seeking help

If you run into an issue, bug or have a question, please reach out to the Kong
community via [Kong Nation](https://discuss.konghq.com) or open Github
issues in [this](https://github.com/kong/charts/issues) repository.

## Releasing and forking

This repo uses [chart releaser](https://github.com/helm/chart-releaser-action/)
to automatically update a GitHub pages branch containing a Helm repo. When you
[bump the `version` field in
Chart.yaml](https://github.com/Kong/charts/commit/c599f4bc78a0ef73eb3cc8a6b22d881864dc0188#diff-466edb10b903c1c9f9019fd0128824ba889bbe1bdff3da186cf698e3a5703af8)
in one of the charts under `charts/` and merge to main, GitHub Actions will
trigger a release job to generate a GitHub release and add the new release to
the Helm repo.

Forks of this repo can use this release functionality without (much) additional
configuration. Enabling GitHub pages for the `gh-pages` branch will make a Helm
repo with your fork's changes available on your GitHub Pages URL. You can then
use this with:

```
helm repo add kong-fork https://myuser.github.io/charts/
```
