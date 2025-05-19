# GWAPI experimental CRDs subchart

This sub-chart contains Gateway API experimental CRDs, allowing users to control whether to install the CRDs.

## How to update

In order to update this with new version CRDs run:

```
kustomize build github.com/kubernetes-sigs/gateway-api/config/crd/experimental\?ref=${VERSION} > crds/gwapi-crds.yaml
```
