# GWAPI standard CRDs subchart

This sub-chart contains Gateway API standard CRDs, allowing users to control whether to install the CRDs.

## How to update

In order to update this with new version CRDs run:

```
kustomize build github.com/kubernetes-sigs/gateway-api/config/crd\?ref=${VERSION} > crds/gwapi-crds.yaml
```
