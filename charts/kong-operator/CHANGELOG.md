# Changelog

## Unreleased

### Fixes

- Fix config dump service and template issue.
  [#2129](https://github.com/Kong/kong-operator/pull/2129)

### Changes

- Conversion webhook can be deployed with `cert-manager`.
  [#2135](https://github.com/Kong/kong-operator/pull/2135)

## 0.0.4

### Changes

- Add support for dumping Kong configuration translated from controlplanes.
  You can set `enableContronplaneConfigDump` to `true` to enable config dump,
  and configure the port of config dump server by `controlplaneConfigDumpPort`.
  [#1894](https://github.com/Kong/kong-operator/pull/1894)

## 0.0.3

### Changes

- Add support for pod annotations in `PodTemplateSpec` for kong-operator deployments.
  [#1709](https://github.com/kong/kong-operator/pull/1709)
