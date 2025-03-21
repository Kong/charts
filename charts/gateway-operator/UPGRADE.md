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

## Updating operator version

The operator version is following [SemVer][semver].
This means that users should not expect breaking changes without a major version change.

Any changes requiring manual user action will be called out in operator [release notes][kgo_release_notes].

[semver]: https://semver.org/
[kgo_release_notes]: https://github.com/Kong/gateway-operator/blob/main/CHANGELOG.md

## Updates to CRDs

Helm installs CRDs at initial install but [does not update them after][hip0011].
Some chart releases include updates to CRDs that must be applied to successfully
upgrade. Because Helm does not handle these updates, you must manually apply
them before upgrading your release.

[hip0011]: https://github.com/helm/community/blob/main/hips/hip-0011.md

For example, upgrading Kong's [kubernetes-configuration][kcfg] CRDs to v0.0.45 requires
running:

```
kustomize build github.com/Kong/kubernetes-configuration/config/crd/gateway-operator?ref=v0.0.45 | kubectl apply -f -
```

[kcfg]: https://github.com/Kong/kubernetes-configuration

Upgrading [Gateway API][gwapi] to v1.2.0 requires running:

```
kustomize build github.com/kubernetes-sigs/gateway-api/config/crd\?ref=v1.2.0 | kubectl apply -f -
```

[gwapi]: https://github.com/kubernetes-sigs/gateway-api/

## Relevant changes by chart version

Default operator version is `1.5` now.

### v0.5.0

#### CRDs

KGO 1.5 uses the CRDs that are hosted in [kubernetes-configuration][kcfg] repository.

The compatibility matrix between the operator and the CRDs can be found in operator's docs at [docs.konghq.com][kgo_docs_compat_matrix].

To install/upgrade these CRDs please consult: [kubernetes-configuration install instructions][kcfg_crds_install].

[kgo_docs_compat_matrix]: https://docs.konghq.com/gateway-operator/latest/reference/version-compatibility/#kubernetes-configuration-crds
[kcfg_crds_install]: https://github.com/Kong/kubernetes-configuration?tab=readme-ov-file#install-crds

### `kube-rbac-proxy` removal

KGO 1.5 removed usage of `kube-rbac-proxy`.
Its functionality of can be now achieved by using the new flag `--metrics-access-filter`
(or a corresponding `GATEWAY_OPERATOR_METRICS_ACCESS_FILTER` env).
The default value for the flag is `off` which doesn't restrict the access to the metrics
endpoint. The flag can be set to `rbac` which will configure KGO to verify the token
sent with the request.
For more information on this migration please consult [kubernetes-sigs/kubebuilder#3907][kubebuilder_3907].

[kubebuilder_3907]: https://github.com/kubernetes-sigs/kubebuilder/discussions/3907
