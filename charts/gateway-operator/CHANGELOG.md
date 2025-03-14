# Changelog

## Unreleased

### Changes

- Update `ClusterRole` for 1.5
  [#1271](https://github.com/Kong/charts/pull/1271)

## 0.4.10-rc.1

### Changes

- Set `readOnlyRootFilesystem: true` for kube-rbac-proxy
  [#1057](https://github.com/Kong/charts/pull/1057)
- Add `ValidatingAdmissionPolicy` validating `DataPlane` ports.
  [#1263](https://github.com/Kong/charts/pull/1263)

## 0.4.9

## Changes

- Fix using non semver tags (e.g. `nightly`) without specifying the
  `.image.effectiveSemver`. Now the latter default to current chart `appVersion`.
  [#1246](https://github.com/Kong/charts/pull/1246)

## 0.4.8

### Changes

- Remove kube-rbac-proxy for operator versions 1.5+.
  In order to controler metrics endpoint access for these version please see
  [kubernetes-sigs/kubebuilder/discussions/3907][kubebuilder_discussion_3907].
  Operator exposes `--metrics-access-filter` flag to control access to the metrics endpoint.
  [#1243](https://github.com/Kong/charts/pull/1243)

[kubebuilder_discussion_3907]: https://github.com/kubernetes-sigs/kubebuilder/discussions/3907

## 0.4.7

### Changes

- Bumped `kong/kubernetes-configuration` CRDs to 1.0.8.
  [#1238](https://github.com/Kong/charts/pull/1238)

## 0.4.6

### Changes

- Remove `ValidatingAdmissionPolicy` validating `DataPlane` ports.
  [#1234](https://github.com/Kong/charts/pull/1234)

## 0.4.5

### Changes

- Fix rules of `ValidatingAdmissionPolicy` validating `DataPlane` ports.
  [#1215](https://github.com/Kong/charts/pull/1215)
- Bumped `kong/kubernetes-configuration` CRDs to 1.0.7.
  [#1231](https://github.com/Kong/charts/pull/1231)

## 0.4.4

### Changes

- Added permissions to `get/list/watch` `backendtlspolicies` and `update/patch`
  `backendtlspolicies/status` to enable BackendTLSPolicy controller in KIC.
  [#1230](https://github.com/Kong/charts/pull/1230)

## 0.4.3

### Changes

- Added `ValidatingAdmissionPolicy` and `ValidatingAdmissionPolicyBinding` for
  validating `DataPlane` ports.
  [#1215](https://github.com/Kong/charts/pull/1215)

## 0.4.2

### Changes

- Update kubernetes-configuration CRDs to 1.0.3
  [#1203](https://github.com/Kong/charts/pull/1203)

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
