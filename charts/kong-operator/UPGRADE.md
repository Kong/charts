# Upgrade considerations

New versions of this chart may add significant new functionality or
deprecate/entirely remove old functionality. This document covers how and why
users should update their chart configuration to take advantage of new features
or migrate away from deprecated features.

In general, breaking changes deprecate their old features before removing them
entirely. While support for the old functionality remains, the chart will show
a warning about the outdated configuration when running
`helm install/status/upgrade`.

Note that not all versions contain breaking changes. If a version is not
present in the table of contents, it requires no version-specific changes when
upgrading from a previous version.

## Upgrading from KGO - Kong Gateway Operator chart

If you're upgrading from KGO - Kong Gateway Operator chart you will need to
update the CRDs manually since [Helm does not manage CRD updates][helm_crd_update].

This can be done by running the following command:

```sh
kustomize build github.com/kong/kong-operator/config/crd/gateway-operator | kubectl apply --server-side -f -
```

[helm_crd_update]: https://helm.sh/docs/chart_best_practices/custom_resource_definitions/

## Updating operator version

The operator version is following [SemVer][semver].
This means that users should not expect breaking changes without a major version change.

Any changes requiring manual user action will be called out in operator [release notes][ko_release_notes].

[semver]: https://semver.org/
[ko_release_notes]: https://github.com/Kong/kong-operator/blob/main/CHANGELOG.md

## Updates to CRDs

Helm installs CRDs at initial install but [does not update them after][hip0011].
Some chart releases include updates to CRDs that must be applied to successfully
upgrade. Because Helm does not handle these updates, you must manually apply
them before upgrading your release.

[hip0011]: https://github.com/helm/community/blob/main/hips/hip-0011.md

For example, upgrading Kong Operator CRDs to v2.0.1 requires
running:

```sh
kustomize build github.com/Kong/kong-operator/config/crd/gateway-operator?ref=v2.0.1 | kubectl apply -f -
```

Upgrading [Gateway API][gwapi] to v1.5.1 requires running:

```sh
kustomize build github.com/kubernetes-sigs/gateway-api/config/crd\?ref=v1.5.1 | kubectl apply -f -
```

[gwapi]: https://github.com/kubernetes-sigs/gateway-api/

## CRD field descriptions

Starting with chart version 1.5.0-rapid.1, the Kong Operator CRDs shipped with
this chart (`ko-crds`) no longer carry per-field `description` doc strings.
With them the Helm release manifest grows past the 1MiB `Secret` size limit,
which makes `helm install`/`helm upgrade` fail. As a result, `kubectl explain`
does not print field documentation for these CRDs.

If you want the field documentation in your cluster, apply the full CRDs for
your operator version (the chart's `appVersion`) with server-side apply under
a separate field manager:

```sh
# Set to the appVersion of the installed chart, e.g.
# helm get metadata <release> -n <namespace> -o json | jq -r .appVersion
KO_VERSION=<version>

kubectl apply --server-side --force-conflicts --field-manager=kong-operator-crd-docs \
  -k "https://github.com/Kong/kong-operator/config/crd/kong-operator?ref=v${KO_VERSION}"
```

The chart's CRDs differ from the full ones only by the doc strings, and the
full CRDs do not set `spec.conversion`, so the conversion webhook configuration
templated by the chart is left untouched. However, `spec.versions` (which holds
the schemas) is an atomic list, so this apply takes ownership of the whole list
away from Helm. This has consequences for every later `helm upgrade`:

- With Helm 4 (server-side apply, the default), `helm upgrade` fails with
  `conflict with "kong-operator-crd-docs": .spec.versions`. Run it with
  `--force-conflicts` so that Helm takes the list back.
- With client-side apply (Helm 3, or Helm 4 with `--server-side=false`),
  `helm upgrade` replaces the list without reporting a conflict.

Either way, the upgrade restores the CRDs without the doc strings, so re-run
the `kubectl apply` above, with `KO_VERSION` set to the new `appVersion`, after
every `helm upgrade`.

Do not install the CRDs from `config/crd/kong-operator` in place of the chart's
`ko-crds` (i.e. with `ko-crds.enabled=false`): they do not contain the
conversion webhook configuration that the chart templates for your release.
