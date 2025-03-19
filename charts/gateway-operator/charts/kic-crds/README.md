# KIC CRDs subchart

This sub-chart contains Kong Ingress Controller (KIC)'s CRDs, allowing users to control whether to install them.

> NOTE: KIC CRDs have been moved to the [Kong/kubernetes-configuration][kconf] repository
> under the `config/crd/ingress-controller` directory.

[kconf]: https://github.com/Kong/kubernetes-configuration

```bash
kustomize build https://github.com/kong/kubernetes-configuration/config/crd/ingress-controller\?ref\=${VERSION} > crds/kic-crds.yaml
```

For example:

```bash
kustomize build https://github.com/kong/kubernetes-configuration/config/crd/ingress-controller\?ref\=v1.2.0 > crds/kic-crds.yaml
```
