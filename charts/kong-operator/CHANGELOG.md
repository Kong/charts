# Changelog

## 0.0.6

### ⚠️ **IMPORTANT NOTICE ABOUT MIGRATION WEBHOOKS:**

Since migration webhooks are bound to a CRD definition, installing more than 1
helm release has to be done with caution to avoid conflicts.

Users can use `ko-crds.enabled` to install and manage operator's CRDs.
`global.conversionWebhook.enabled` can be set to `true` to enable the conversion webhook.
Any subsequent helm release after the first one that enables these options,
must not set either of these to `true` to prevent ownership conflicts.

Moreover, `env.enable_conversion_webhook` must be set to `false` in all
releases except the first one that enables it, otherwise operator deployments may fail.
The operator deployment that has been installed as first, will handle the conversions.

### Changes

- Update kong-operator image version to 2.0.0-alpha.5.
  [#2175](https://github.com/Kong/kong-operator/pull/2175)
- Add support for helm generated self signed certs for conversion webhook
  [#2141](https://github.com/Kong/kong-operator/pull/2141)
- Add support for cert-manager certificate generation for conversion webhook
  [#2122](https://github.com/Kong/kong-operator/pull/2122)

## 0.0.5

### Fixes

- Fix config dump service and template issue.
  [#2129](https://github.com/Kong/kong-operator/pull/2129)

### Changes

- Update kong-operator image version to 2.0.0-alpha.4.
  [#2147](https://github.com/Kong/kong-operator/pull/2147)
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
