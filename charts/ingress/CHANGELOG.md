# Changelog

## 1.0.0

This major release consolidates the `kong` and `ingress` chart that behaves
like the `ingress` chart (a KIC-managed Kong installation with separate
Deployments for the controller and proxy) by default. Existing users of 2.x
`kong` chart and the 0.x `ingress` chart should both upgrade to `ingress` 1.x
following the [upgrade guide](https://github.com/Kong/charts/blob/main/charts/kong/UPGRADE.md#100).

## Breaking changes

- A number of values.yaml keys have moved to accomodate the revised controller
  Deployment configuration. The [migration tool](https://github.com/Kong/chart-migrate)
  can automate most of the required changes.
- The controller sidecar container previously used by default in the `kong`
  chart is no longer supported. The controller must reside in its own
  Deployment. Although the transition between sidecar and standalone Deployment
  is not expected to cause issues, you may need to add Deployment-level and
  Pod-level configuration to the new Deployment under
  `ingressController.deployment` in values.yaml.
- The controller uses gateway discovery mode by default. This mode uses a
  single leader controller instance to update all proxy instances in either
  DB-less or DB-backed mode. It is a requirement for deploying the controller
  in a separate Deployment for DB-less mode.
- The controller and proxy admin API now use mutual TLS to secure their
  communications by default. Defaults use chart-generated certificates. You can
  configure alternate certificates under `ingressController.adminApi` and
  `admin.tls.client`.

## 0.10.0

### Improvements

- Bumped dependencies on `kong/kong` chart to `>=2.33.0`.
  [#964](https://github.com/Kong/charts/pull/964)

## 0.9.0

### Improvements

- Bumped dependencies on `kong/kong` chart to `>=2.31.0`.
  This most notably brings a default version of KIC to [v3.0][kic_3_0].
  [#930](https://github.com/Kong/charts/pull/930)

[kic_3_0]: https://github.com/Kong/kubernetes-ingress-controller/releases/tag/v3.0.0

## 0.8.0

### Improvements

- Controller Pods now include annotations to exempt the gateway admin API port
  from Kuma and Istio mesh interception. Controller to admin API configuration
  uses its own mTLS configuration, which is not compatible with mesh mTLS.
  [#913](https://github.com/Kong/charts/pull/913)
- Allow using templates (via `tpl`) when specifying `controller.proxy.nameOverride`.
  [#915](https://github.com/Kong/charts/pull/915)
- Bumped dependency `kong/kong` to `2.30.0`.
  [#915](https://github.com/Kong/charts/pull/915)

## 0.7.0

- Bumped dependency `kong/kong` minimum to `2.28.1`. Review the [kong chart
  changelog](https://github.com/Kong/charts/blob/kong-2.33.2/charts/kong/CHANGELOG.md#2281)
  for details.

## 0.6.0

### Improvements

- Bumped dependency `kong/kong` to `2.26.2`.
  [#862](https://github.com/Kong/charts/pull/862)

## 0.5.0

### Breaking changes

The new `kong/kong` chart requires manual changes to values.yaml if using this
chart with controller versions <=2.10 and Kong versions >=3.3. See the 
[the kong/kong 2.26 upgrade instructions](https://github.com/Kong/charts/blob/kong-2.33.2/charts/kong/UPGRADE.md#2260)
for details.

### Improvements

- Bumped dependencies on `kong/kong` chart to `>=2.26.0`.
  [#855](https://github.com/Kong/charts/pull/855)

## 0.4.0

### Improvements

- Generate the `adminApiService.name` value from `.Release.Name` rather than
  hardcoding to `kong`
  [#840](https://github.com/Kong/charts/pull/840)

## 0.3.0

### Fixes

- Changed default `gateway.admin` service from `NodePort` to headless `ClusterIP`
  which is expected for Gateway Discovery to work.
  [#835](https://github.com/Kong/charts/pull/835)

## 0.2.0

### Improvements

- Bumped dependencies on `kong/kong` chart to `>=2.23.0`.
  [#817](https://github.com/Kong/charts/pull/817)

## 0.1.0

### Improvements

- Created opinionated KIC + Gateway Discovery chart with predefined `values.yaml`
  [#806](https://github.com/Kong/charts/pull/806)
