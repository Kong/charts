# kubernetes-configuration subchart

This sub-chart contains Kong's [Kubernetes Configuration][kconf] CRDs, allowing users to control whether to install them.

[kconf]: https://github.com/Kong/kubernetes-configuration

### Contributing

#### Syncing CRDs with `kong/kubernetes-configuration` repository

To update the CRDs, you can run the following command:

```bash
kustomize build github.com/kong/kubernetes-configuration/config/crd/gateway-operator > ./charts/gateway-operator/charts/kubernetes-configuration-crds/crds/kubernetes-configuration-crds.yaml
```
