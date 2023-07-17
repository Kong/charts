# Changelog

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
