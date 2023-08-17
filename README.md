# Kong Helm Charts

This is the official Helm Charts repository for installing Kong on Kubernetes.

## Setup

Add the repo on your machine:

```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

If you plan to use the Kong Ingress Controller, use the `kong/ingress` chart:

```bash
helm install kong/ingress --generate-name
```

If you plan to install Kong on Kubernetes in Hybrid or Traditional mode use the `kong/kong` chart:

```bash
helm install kong/kong --generate-name
```

## Documentation

The documentation for Kong's Helm Charts is available on GitHub.

* [kong/ingress](https://github.com/Kong/charts/blob/main/charts/ingress/README.md)
* [kong/kong](https://github.com/Kong/charts/blob/main/charts/kong/README.md)

## Seeking help

If you run into an issue, bug or have a question, please reach out to the Kong
community via [Kong Nation](https://discuss.konghq.com) or open Github
issues in [this](https://github.com/kong/charts/issues) repository.
