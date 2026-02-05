# Changelog

## Unreleased

### Changed

- Bootstrapping CA certificate (that is used for signing certificates for
  ControlPlane - DataPlane communication) is done automatically by Helm.
  The existing certificate can be referenced by setting options
  `certificateAuthority.secret.name` and `certificateAuthority.secret.namespace`.
  [#3084](https://github.com/Kong/kong-operator/pull/3084)

## 1.1.0

### Changed

- Update Gateway API to 1.4.0
  [#2451](https://github.com/Kong/kong-operator/pull/2451)

## 1.0.2

### Fixes

- Use proper certificate for validating webhook when `cert-manager` is used.
  [#2356](https://github.com/Kong/kong-operator/pull/2356)
- Bump `ko-crds` subchart to `1.0.1`, which includes:
  - Add the `status.clusterType` field in `KonnectGatewayControlPlane` CRD.
    [#2311](https://github.com/Kong/kong-operator/pull/2311)

## 1.0.1

### Added

- Support for specifying image digest via `image.digest` in `values.yaml`
  [#2311](https://github.com/Kong/kong-operator/pull/2311)

## 1.0.0

This is the first release of the new Helm Chart dedicated to install
[Kong Operator](https://github.com/Kong/kong-operator), it uses
[v2.0.0](https://github.com/Kong/kong-operator/releases/tag/v2.0.0) image
for operator and `3.11` for Kong Gateway.

Read more about migration in the official docs.

### ⚠️ **IMPORTANT NOTICE ABOUT CONVERSION WEBHOOKS:**

Since conversion webhooks are bound to a CRD definition, installing more than 1
helm release has to be done with caution to avoid conflicts.

Users can use `ko-crds.enabled` to install and manage operator's CRDs.
`global.webhooks.conversion.enabled` can be set to `true` to enable the conversion webhook.
Any subsequent helm release after the first one that enables these options,
must not set either of these to `true` to prevent ownership conflicts.

Moreover, `env.enable_conversion_webhook` must be set to `false` in all
releases except the first one that enables it, otherwise operator deployments may fail.
The operator deployment that has been installed as first, will handle the conversions.
