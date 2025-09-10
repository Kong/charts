# Kong Operator

[Kong Operator](https://docs.konghq.com/kong-operator/latest/) is a Kubernetes Operator
that can manage and configure your Kong Gateway Data Planes when running on Kubernetes.

## Usage

```bash
helm repo add kong https://charts.konghq.com
helm repo update

helm install ko kong/kong-operator -n kong-system --create-namespace
```

### CRD management

Helm 3 introduced a simplified CRD management method that is safer than what was
available in Helm 2, but requires some manual work when a chart added or modified CRDs:
CRDs are created on install if they are not already present, but are not modified during
release upgrades or deletes. Our chart release upgrade instructions will call out
when manual action is necessary to update CRDs. This CRD handling strategy is
recommended for most users.

Some users may wish to manage their CRDs automatically. If you manage your CRDs
this way, we _strongly_ recommend that you back up all associated custom
resources in the event you need to recover from unintended CRD deletion.

Any changes requiring manual CRD updates will be called out in the release notes.
Those manual steps can be found in [UPGRADE.md](UPGRADE.md).

#### CRD sources

This project uses CRDs from 2 sources at this moment:

- [Gateway API](https://gateway-api.sigs.k8s.io/)
- [Kong Operator CRDs](https://github.com/Kong/kong-operator)
