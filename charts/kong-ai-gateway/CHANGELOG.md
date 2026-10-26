# Changelog

## Unreleased

### Fixes

- The PodDisruptionBudget now selects pods with the same labels as the
  Deployment selector. Previously it also matched `helm.sh/chart` and
  `app.kubernetes.io/version`, so after an upgrade that changed either label it
  did not cover the pods from the previous release until they were replaced.

## 0.3.0

### Changes

- Update the default AI Gateway DataPlane image to `kong/kong-ai-gateway:2.2.0`.

## 0.2.1

### Fixes

- Preserve the configured readiness probe path instead of applying Kong Gateway
  version compatibility rules to the AI Gateway image version.

## 0.2.0

### Changes

- Update the default AI Gateway DataPlane image to
  `kong/kong-ai-gateway-dev:2.0.3`.
  [#5459](https://github.com/Kong/kong-operator/pull/5459)

## 0.1.0

### Changes

- Initial release of the `kong-ai-gateway` chart: deploys Kong AI Gateway as
  a standalone, Konnect-only hybrid-mode data plane without requiring Kong
  Operator.
  [#1554](https://github.com/Kong/charts/issues/1554)
