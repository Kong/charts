# Changelog

## 0.4.1

### Changes

- Update operator's RBAC policy rules.
  [#1153](https://github.com/Kong/charts/pull/1153)

## 0.4.0

### Changes

- Bump the operator's default version to 1.4.0 and `kong/kubernetes-configuration` CRDs to 0.0.41.
  [#1161](https://github.com/Kong/charts/pull/1161)

## 0.3.0

### Changes

- Added a `kubernetes-configuration-crds` subchart to install Kong's Kubernetes Configuration CRDs.
  It's off by default.
  [#1151](https://github.com/Kong/charts/pull/1151)

## 0.2.3

### Fixes

- Fixed manager's policy rules
  [#1148](https://github.com/Kong/charts/pull/1148)

## 0.2.2

### Changes

- Updated CRDs for KGO 1.4.0 release
  [#1139](https://github.com/Kong/charts/pull/1139)
- Update RBAC policy rules for KGO 1.4.0
  [#1138](https://github.com/Kong/charts/pull/1138)

## 0.2.1

### Changes

- Added the ability to define deployment selector labels
  [#1118](https://github.com/Kong/charts/pull/1118)

## 0.2.0

### Changes

- Bump default version to 1.3.0 and Gateway API CRDs to 1.1.0.
  [#1115](https://github.com/Kong/charts/pull/1115)

## 0.1.11

### Changes

- Added `poddisruptionbudgets` to RBAC policy rules in operator's manager-role.
  [#1114](https://github.com/Kong/charts/pull/1114)

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
