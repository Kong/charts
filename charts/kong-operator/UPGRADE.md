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


```
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

Upgrading [Gateway API][gwapi] to v1.2.0 requires running:

```sh
kustomize build github.com/kubernetes-sigs/gateway-api/config/crd\?ref=v1.2.0 | kubectl apply -f -
```

[gwapi]: https://github.com/kubernetes-sigs/gateway-api/
