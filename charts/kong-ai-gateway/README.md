## Kong AI Gateway

[Kong AI Gateway](https://hub.docker.com/r/kong/kong-ai-gateway) is Kong's
dedicated AI Gateway data-plane binary. This chart deploys it as a standalone,
Konnect-only hybrid-mode data plane, without requiring [Kong
Operator](https://github.com/Kong/kong-operator) or any of its CRDs.

This chart is derived from the [`kong` chart](https://github.com/Kong/charts/tree/main/charts/kong)
and shares most of its configuration surface (`env`, `proxy`, `admin`,
`secretVolumes`, `certificates`, etc.) but removes everything that doesn't
apply to a Konnect AI Gateway data plane: Kong Ingress Controller, Postgres
and migrations, Kong Manager, and the Developer Portal.

## Table of contents

- [Kong AI Gateway](#kong-ai-gateway)
- [Table of contents](#table-of-contents)
- [Prerequisites](#prerequisites)
- [Install](#install)
- [Configuration](#configuration)
  - [Konnect connection](#konnect-connection)
  - [Certificates](#certificates)
  - [Exposing the AI Gateway ingress listener](#exposing-the-ai-gateway-ingress-listener)
- [Uninstall](#uninstall)

## Prerequisites

- A Konnect AI Gateway control plane already created in
  [Konnect](https://konghq.com/products/kong-konnect). Note its control plane
  and telemetry hybrid connection hostnames from its connection details page.
- A client mTLS certificate/key pair that Konnect is configured to trust for
  that control plane, either as a Kubernetes Secret you create yourself, or
  issued in-cluster via [cert-manager](https://cert-manager.io/).

## Install

```shell
helm repo add kong https://charts.konghq.com
helm repo update
helm install my-ai-gateway kong/kong-ai-gateway -f my-values.yaml
```

See [`example-values/`](./example-values) for starting points: one using a
user-provided certificate Secret, and one using cert-manager.

## Configuration

### Konnect connection

Set the following under `env` to your Konnect AI Gateway control plane's
connection details (see
[`example-values/minimal-konnect-byo-cert.yaml`](./example-values/minimal-konnect-byo-cert.yaml)):

```yaml
env:
  cluster_control_plane: CHANGEME-control-plane-endpoint.konghq.com:443
  cluster_server_name: CHANGEME-control-plane-endpoint.konghq.com
  cluster_telemetry_endpoint: CHANGEME-telemetry-endpoint.konghq.com:443
  cluster_telemetry_server_name: CHANGEME-telemetry-endpoint.konghq.com
```

All other `KONG_*` environment variables required to boot as a Konnect data
plane (`role`, `database`, `cluster_mtls`, `vitals`, `konnect_mode`,
`lua_ssl_trusted_certificate`, `status_listen`, etc.) are already set by this
chart's defaults and normally should not need to change.

### Certificates

By default, `env.cluster_cert` / `env.cluster_cert_key` point at
`/etc/secrets/kong-cluster-cert/tls.crt` and `tls.key`. Create a Secret named
`kong-cluster-cert` containing the client certificate/key Konnect expects, and
list it in `secretVolumes` so the chart mounts it:

```yaml
secretVolumes:
- kong-cluster-cert
```

Alternatively, set `certificates.enabled: true` and `certificates.cluster.enabled: true`
to have [cert-manager](https://cert-manager.io/docs/) issue the certificate
for you (see [`example-values/minimal-konnect-cert-manager.yaml`](./example-values/minimal-konnect-cert-manager.yaml)).
When using cert-manager, point `env.cluster_cert` / `env.cluster_cert_key` at
`/etc/cert-manager/cluster/tls.crt` / `tls.key` instead.

### Exposing the AI Gateway ingress listener

The `proxy` section configures the Kubernetes Service that exposes the AI
Gateway's ingress listener, the same way it does in the `kong` chart's
`proxy` section. `admin.enabled` defaults to `false`; enable it only if you
need local Admin API access for debugging.

## Uninstall

```shell
helm uninstall my-ai-gateway
```
