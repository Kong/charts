# Kong Helm Charts

This is the official Helm Charts repository for installing Kong on Kubernetes.

## Setup

```bash
helm repo add kong https://charts.konghq.com
helm repo update
# helm2
helm install kong/kong
# helm3
helm install kong kong/kong --skip-crds
```

## Documentation

The documentation for Kong's Helm Chart is available at
[here](https://github.com/Kong/charts/blob/master/charts/kong/README.md).

## Seeking help

If you run into an issue, bug or have a question, please reach out to the Kong
community via [Kong Nation](https://discuss.konghq.com) or open Github
issues in [this](https://github.com/kong/charts/issues) repository.
