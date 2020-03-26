# Changelog

## 1.4.1

### Documentation

* Fixed an issue with the 1.4.1 upgrade steps.

## 1.4.0

### Improvements

* Service and listen configuration now use a unified configuration format.
  Listen configuration now supports specifying parameters. Kubernetes service
  creation can now be enabled or disabled for all Kong services. Users should
  review the [1.4.0 upgrade
  guide](https://github.com/Kong/charts/blob/next/charts/kong/UPGRADE.md#changes-to-kong-service-configuration)
  for details on how to update their values.yaml.
  ([#72](https://github.com/Kong/charts/pull/72))
* Updated the default controller version to 0.8. This adds new
  KongClusterPlugin and TCPIngress CRDs and RBAC permissions for them. Users
  should also note that `strip_path` now defaults to disabled, which will
  likely break existing configuration. See [the controller
  changelog](https://github.com/Kong/kubernetes-ingress-controller/blob/master/CHANGELOG.md#080---20200325)
  and [upgrade-guide](https://github.com/Kong/charts/blob/next/charts/kong/UPGRADE.md#strip_path-now-defaults-to-false-for-controller-managed-routes)
  for full details.
  ([#77](https://github.com/Kong/charts/pull/77))
* Added support for user-supplied ingress controller CLI arguments.
  ([#79](https://github.com/Kong/charts/pull/79))
* Added support for annotating the chart's deployment.
  ([#81](https://github.com/Kong/charts/pull/81))
* Switched to the Bitnami Postgres chart, as the chart in Helm's repository has
  [moved
  there](https://github.com/helm/charts/tree/master/stable/postgresql#this-helm-chart-is-deprecated).
  ([#82](https://github.com/Kong/charts/pull/82))

### Fixed

* Corrected the app version in Chart.yaml.
  ([#86](https://github.com/Kong/charts/pull/86))

### Documentation

* Fixed incorrect default value for `installCRDs`.
  ([#78](https://github.com/Kong/charts/pull/78))
* Added detailed upgrade guide covering breaking changes and deprecations.
  ([#74](https://github.com/Kong/charts/pull/74))
* Improved installation steps for Helm 2 and Helm 3.
  ([#83](https://github.com/Kong/charts/pull/83))
  ([#84](https://github.com/Kong/charts/pull/84))
* Remove outdated `ingressController.replicaCount` setting.
  ([#87](https://github.com/Kong/charts/pull/87))

## 1.3.1

### Fixed

* Added missing newline to NOTES.txt template.
  ([#66](https://github.com/Kong/charts/pull/66))

### Documentation

* Instruct users to create secrets for both the kong-enterprise-k8s and
  kong-enterprise-edition Docker registries.
  ([#65](https://github.com/Kong/charts/pull/65))
* Updated maintainer information.

## 1.3.0

### Improvements

* Custom plugin mounts now support subdirectories. These are necessary for
  plugins that include their own migrations. Note that Kong versions prior to
  2.0.1 [have a bug](https://github.com/Kong/kong/pull/5509) that prevents them
  from running these migrations. ([#24](https://github.com/Kong/charts/pull/24))
* LoadBalancer services will now respect their NodePort.
  ([#48](https://github.com/Kong/charts/pull/41))
* The proxy TLS listen now enables HTTP/2 (and, by extension, gRPC).
  ([#47](https://github.com/Kong/charts/pull/47))
* Added support for `priorityClassName` to the Kong deployment.
  ([#56](https://github.com/Kong/charts/pull/56))
* Bumped default Kong version to 2.0 and controller version to 0.7.1.
  ([#60](https://github.com/Kong/charts/pull/60))
* Removed dedicated Portal auth settings, which are unnecessary in modern
  versions. ([#55](https://github.com/Kong/charts/pull/55))

### Fixed

* Fixed typo in HorizontalPodAutoscaler template.
  ([#45](https://github.com/Kong/charts/pull/45))

### Documentation

* Added contributing guidelines. ([#41](https://github.com/Kong/charts/pull/41))
* Added README section for Helm 2 versus Helm 3 considerations.
  ([#34](https://github.com/Kong/charts/pull/41))
* Added documentation for `proxy.annotations` to README.md.
  ([#57](https://github.com/Kong/charts/pull/57))
* Added FAQ entry for init-migrations job conflicts on upgrades.
  ([#59](https://github.com/Kong/charts/pull/59)
* Move changelog out of README.md into CHANGELOG.md.
  ([#60](https://github.com/Kong/charts/pull/60)
* Improved formatting for 1.2.0 changelog.

## 1.2.0

### Improvements
* Added support for HorizontalPodAutoscaler.
  ([#12](https://github.com/Kong/charts/pull/12))
* Environment variables are now consistently sorted alphabetically.
  ([#29](https://github.com/Kong/charts/pull/29))

### Fixed
* Removed temporary ServiceAccount template, which caused upgrades to break the
  existing ServiceAccount's credentials. Moved template and instructions for
  use to FAQs, as the temporary user is only needed in rare scenarios.
  ([#31](https://github.com/Kong/charts/pull/31))
* Fix an issue where the wait-for-postgres job did not know which port to use
  in some scenarios. ([#28](https://github.com/Kong/charts/pull/28))

### Documentation
* Added warning regarding volume mounts.
  ([#25](https://github.com/Kong/charts/pull/25))

## 1.1.1

### Fixed

* Add missing `smtp_admin_emails` and `smtp_mock = off` to SMTP enabled block in
  `kong.env`.

### CI changes

* Remove version bump requirement in preparation for new release model.

## 1.1.0

> https://github.com/Kong/charts/pull/4

### Improvements

* Significantly refactor the `env`/EnvVar templating system to determine the
  complete set of environment variables (both user-defined variables and
  variables generated from other sections of values.yaml) and resolve conflicts
  before rendering. User-provided values are now guaranteed to take precedence
  over generated values. Previously, precedence relied on a Kubernetes
  implementation quirk that was not consistent across all Kubernetes providers.
* Combine templates for license, session configuration, etc. that generate
  `secretKeyRef` values into a single generic template.

## 1.0.3

- Fix invalid namespace for pre-migrations and Role.
- Fix whitespaces formatting in README.

## 1.0.2

- Helm 3 support: CRDs are declared in crds directory. Backward compatible support for helm 2.

## 1.0.1

Fixed invalid namespace variable name causing ServiceAccount and Role to be generated in other namespace than desired.

## 1.0.0

There are not code changes between `1.0.0` and `0.36.5`.
From this version onwards, charts are hosted at https://charts.konghq.com.

The `0.x` versions of the chart are available in Helm's
[Charts](https://github.com/helm/charts) repository are are now considered
deprecated.

## 0.36.5

> PR https://github.com/helm/charts/pull/20099

### Improvements

- Allow `grpc` protocol for KongPlugins

## 0.36.4

> PR https://github.com/helm/charts/pull/20051

### Fixed

- Issue: [`Ingress Controller errors when chart is redeployed with Admission
  Webhook enabled`](https://github.com/helm/charts/issues/20050)

## 0.36.3

> PR https://github.com/helm/charts/pull/19992

### Fixed

- Fix spacing in ServiceMonitor when label is specified in config

## 0.36.2

> PR https://github.com/helm/charts/pull/19955

### Fixed

- Set `sideEffects` and `admissionReviewVersions` for Admission Webhook
- timeouts for liveness and readiness probes has been changed from `1s` to `5s`

## 0.36.1

> PR https://github.com/helm/charts/pull/19946

### Fixed

- Added missing watch permission to custom resources

## 0.36.0

> PR https://github.com/helm/charts/pull/19916

### Upgrade Instructions

- When upgrading from <0.35.0, in-place chart upgrades will fail.
  It is necessary to delete the helm release with `helm del --purge $RELEASE` and redeploy from scratch.
  Note that this will cause downtime for the kong proxy.

### Improvements

- Fixed Deployment's label selector that prevented in-place chart upgrades.

## 0.35.1

> PR https://github.com/helm/charts/pull/19914

### Improvements

- Update CRDs to Ingress Controller 0.7
- Optimize readiness and liveness probes for more responsive health checks
- Fixed incorrect space in NOTES.txt

## 0.35.0

> PR [#19856](https://github.com/helm/charts/pull/19856)

### Improvements

- Labels on all resources have been updated to adhere to the Helm Chart
  guideline here:
  https://v2.helm.sh/docs/developing_charts/#syncing-your-chart-repository

## 0.34.2

> PR [#19854](https://github.com/helm/charts/pull/19854)

This release contains no user-visible changes

### Under the hood

 - Various tests have been consolidated to speed up CI.

## 0.34.1

> PR [#19887](https://github.com/helm/charts/pull/19887)

### Fixed

- Correct indentation for Job securityContexts.

## 0.34.0

> PR [#19885](https://github.com/helm/charts/pull/19885)

### New features

- Update default version of Ingress Controller to 0.7.0

## 0.33.1

> PR [#19852](https://github.com/helm/charts/pull/19852)

### Fixed

- Correct an issue with white space handling within `final_env` helper.

## 0.33.0

> PR [#19840](https://github.com/helm/charts/pull/19840)

### Dependencies

- Postgres sub-chart has been bumped up to 8.1.2

### Fixed

- Removed podDisruption budge for Ingress Controller. Ingress Controller and
  Kong run in the same pod so this was no longer applicable
- Migration job now receives the same environment variable and configuration
  as that of the Kong pod.
- If Kong is configured to run with Postgres, the Kong pods now always wait
  for Postgres to start. Previously this was done only when the sub-chart
  Postgres was deployed.
- A hard-coded container name is used for kong: `proxy`. Previously this
  was auto-generated by Helm. This deterministic naming allows for simpler
  scripts and documentation.

### Under the hood

Following changes have no end user visible effects:

- All Custom Resource Definitions have been consolidated into a single
  template file
- All RBAC resources have been consolidated into a single template file
- `wait-for-postgres` container has been refactored and de-duplicated

## 0.32.1

### Improvements

- This is a doc only release. No code changes have been done.
- Post installation steps have been simplified and now point to a getting
  started page
- Misc updates to README:
  - Document missing variables
  - Remove outdated variables
  - Revamp and rewrite major portions of the README
  - Added a table of content to make the content navigable

## 0.32.0

### Improvements

- Create and mount emptyDir volumes for `/tmp` and `/kong_prefix` to allow
  for read-only root filesystem securityContexts and PodSecurityPolicys.
- Use read-only mounts for custom plugin volumes.
- Update stock PodSecurityPolicy to allow emptyDir access.
- Override the standard `/usr/local/kong` prefix to the mounted emptyDir
  at `/kong_prefix` in `.Values.env`.
- Add securityContext injection points to template. By default,
  it sets Kong pods to run with UID 1000.

### Fixes

- Correct behavior for the Vitals toggle.
  Vitals defaults to on in all current Kong Enterprise releases, and
  the existing template only created the Vitals environment variable
  if `.Values.enterprise.enabled == true`. Inverted template to create
  it (and set it to "off") if that setting is instead disabled.
- Correct an issue where custom plugin configurations would block Kong
  from starting.

## 0.31.0

### Breaking changes

- Admin Service is disabled by default (`admin.enabled`)
- Default for `proxy.type` has been changed to `LoadBalancer`

### New features

- Update default version of Kong to 1.4
- Update default version of Ingress Controller to 0.6.2
- Add support to disable kong-admin service via `admin.enabled` flag.

## 0.31.2

### Fixes

- Do not remove white space between documents when rendering
  `migrations-pre-upgrade.yaml`

## 0.30.1

### New Features

- Add support for specifying Proxy service ClusterIP

## 0.30.0

### Breaking changes

- `admin_gui_auth_conf_secret` is now required for Kong Manager
  authentication methods other than `basic-auth`.
  Users defining values for `admin_gui_auth_conf` should migrate them to
  an externally-defined secret with a key of `admin_gui_auth_conf` and
  reference the secret name in `admin_gui_auth_conf_secret`.

## 0.29.0

### New Features

- Add support for specifying Ingress Controller environment variables.

## 0.28.0

### New Features

- Added support for the Validating Admission Webhook with the Ingress Controller.

## 0.27.2

### Fixes

- Do not create a ServiceAccount if it is not necessary.
- If a configuration change requires creating a ServiceAccount,
  create a temporary ServiceAccount to allow pre-upgrade tasks to
  complete before the regular ServiceAccount is created.

## 0.27.1

### Documentation updates
- Retroactive changelog update for 0.24 breaking changes.

## 0.27.0

### Breaking changes

- DB-less mode is enabled by default.
- Kong is installed as an Ingress Controller for the cluster by default.

## 0.25.0

### New features

- Add support for PodSecurityPolicy
- Require creation of a ServiceAccount

## 0.24.0

### Breaking changes

- The configuration format for ingresses in values.yaml has changed.
Previously, all ingresses accepted an array of hostnames, and would create
ingress rules for each. Ingress configuration for services other than the proxy
now accepts a single hostname, which allows simpler TLS configuration and
automatic population of `admin_api_uri` and similar settings. Configuration for
the proxy ingress is unchanged, but its documentation now accurately reflects
the TLS configuration needed.
