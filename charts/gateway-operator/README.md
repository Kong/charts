## Kong Gateway Operator

[Kong Gateway Operator](https://docs.konghq.com/gateway-operator/latest/) is a Kubernetes Operator that can manage your Kong Ingress Controller, Kong Gateway Data Planes, or both together when running on Kubernetes.

## Usage

```bash
helm repo add kong https://charts.konghq.com
helm repo update

helm install kgo kong/gateway-operator -n kong-system --create-namespace
```
