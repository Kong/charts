# Kong Helm Charts

This is the official Helm Charts repository for installing Kong on Kubernetes.

## Setup

Add the repo on your machine:

```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

## Charts

- [`kong/ingress`][#kongingress]: An umbrella chart for Kong Gateway and [Kong Ingress Controller][kic_gh].
- [`kong/kong`][#kongkong]: A flexible building block for supporting a wide variety of environment configurations.
- [`kong/gateway-operator`][#konggateway-operator]: Installs [Kong Gateway Operator][kgo_gh].

[#kongingress]: #kongingress
[#kongkong]: #kongkong
[#konggateway-operator]: #konggateway-operator
[kic_gh]: https://github.com/Kong/kubernetes-ingress-controller

### `kong/ingress`

`kong/ingress` provides an opinionated ingress controller-managed DB-less
environment.
It is **the recommended chart** for new installations. To use it:

```bash
helm install kong/ingress --generate-name
```

`kong/ingress` is an umbrella chart using two instances of the `kong/kong`
chart with some pre-configured `values.yaml` settings.
The `controller` and `gateway` subsections support additional settings available
in the `kong/kong` `values.yaml`.

### `kong/kong`

`kong/kong` is a flexible building block for supporting a wide variety of
environment configurations not supported by `kong/ingress`, such as hybrid mode
or unmanaged (no controller) Kong instances.

To use it:

```bash
helm install kong/kong --generate-name
```

For more details about the configuration required to support various
environments, see the ["Deployment Options" subsection][kong_deployment_options]
of the `kong/kong` documentation's table of contents.

[kong_deployment_options]: ./charts/kong#deployment-options

### `kong/gateway-operator`

`kong/gateway-operator` installs [Kong Gateway Operator][kgo_gh].

To use it:

```bash
helm install kong/gateway-operator --generate-name
```

[kgo_gh]: https://github.com/Kong/gateway-operator

## Documentation

The documentation for Kong's Helm Charts is available on GitHub:

- [kong/ingress](https://github.com/Kong/charts/blob/main/charts/ingress/README.md)
- [kong/kong](https://github.com/Kong/charts/blob/main/charts/kong/README.md)
- [kong/gateway-operator](https://github.com/Kong/charts/blob/main/charts/gateway-operator/README.md)

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
the Helm repo:

1. Make a new branch and add a [release commit](https://github.com/Kong/charts/pull/576/commits/aa6e73442e5d32c8af3f4e2f000e439578020996).
   This commit updates the Chart.yaml chart version, finalizes that version's changelog, and optionally adds upgrade instructions.
2. Open a PR to main and merge once approved.
3. Wait for CI to release the new version. Investigate errors if the release job fails.

Chart `kong/ingress` uses `kong/kong` as a dependency, so when changes released in `kong/kong` are beneficial for users of `kong/ingress` bump its version `cd charts/ingress && helm dependency update` and prepare a new release of `kong/ingress` as described above.

Forks of this repo can use this release functionality without (much) additional
configuration. Enabling GitHub pages for the `gh-pages` branch will make a Helm
repo with your fork's changes available on your GitHub Pages URL. You can then
use this with:

```sh
helm repo add kong-fork https://myuser.github.io/charts/
```
