## Kong Ingress Controller

[Kong for Kubernetes](https://github.com/Kong/kubernetes-ingress-controller)
is an open-source Ingress Controller for Kubernetes that offers
API management capabilities with a plugin architecture.

This is a meta chart that deploys an opinionated Kong Ingress Controller with
Kong Gateway using [Helm](https://helm.sh) package manager.

## Usage

```bash
$ helm repo add kong https://charts.konghq.com
$ helm repo update

$ helm install kong kong/ingress -n kong
```

If you need more control over what is deployed, see the [kong/kong chart](https://github.com/Kong/charts/blob/main/charts/kong/README.md). Any `values.yaml` setting can be specified in the `controller` or `proxy` section of your `values.yaml` using this chart.
