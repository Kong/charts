# Changelog

## 0.1.10

### Changes

- Added `tolerations` and `affinity` fields support to specify on operator's Pods

## 0.1.9

### Fixes

- Fix missing `customentities` RBAC policy rules in operator's manager-role
  [#1089](https://github.com/Kong/charts/pull/1089)
- Bump KIC's CRDs to 3.2.0
  [#1089](https://github.com/Kong/charts/pull/1089)

## 0.1.8

### Features

- Fix missing `renderTpl` which is used when specifying `.Values.extraLabels`
  [#1075](https://github.com/Kong/charts/pull/1075)

## 0.1.7

### Features

- Add ability to specify probes
  [#1062](https://github.com/Kong/charts/pull/1062)

## 0.1.6

### Features

- Add args and provide current defaults via env
  [#1058](https://github.com/Kong/charts/pull/1058)

## 0.1.4

### Fixes

- Add missing cert-manager Certificate watch RBAC policy rule
  [#1042](https://github.com/Kong/charts/pull/1042)

## 0.1.3

### Fixes

- Add missing RBAC policy rules for cert-manager's Certificate resources
  [#1040](https://github.com/Kong/charts/pull/1040)

## 0.1.0

### Improvements

- Initial version of chart deploying [Kong Gateway Operator][kgo_gh_repo]

[kgo_gh_repo]: https://github.com/Kong/gateway-operator
