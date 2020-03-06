## Kong for Kubernetes

[Kong for Kubernetes](https://github.com/Kong/kubernetes-ingress-controller)
is an open-source Ingress Controller for Kubernetes that offers
API management capabilities with a plugin architecture.

This chart bootstraps all the components needed to run Kong on a
[Kubernetes](http://kubernetes.io) cluster using the
[Helm](https://helm.sh) package manager.

## TL;DR;

```bash
$ helm repo add kong https://charts.konghq.com
$ helm repo update
$ helm install kong/kong
```

## Table of content

- [Prerequisites](#prerequisites)
- [Helm 2 vs Helm 3](#important-helm-2-vs-helm-3)
- [Install](#install)
- [Uninstall](#uninstall)
- [Kong Enterprise](#kong-enterprise)
- [FAQs](#faqs)
- [Deployment Options](#deployment-options)
  - [Database](#database)
  - [Runtime package](#runtime-package)
  - [Configuration method](#configuration-method)
- [Configuration](#configuration)
  - [Kong Parameters](#kong-parameters)
  - [Ingress Controller Parameters](#ingress-controller-parameters)
  - [General Parameters](#general-parameters)
  - [The `env` section](#the-env-section)
- [Kong Enterprise Parameters](#kong-enterprise-parameters)
  - [Prerequisites](#prerequisites-1)
    - [Kong Enterprise License](#kong-enterprise-license)
    - [Kong Enterprise Docker registry access](#kong-enterprise-docker-registry-access)
  - [Service location hints](#service-location-hints)
  - [RBAC](#rbac)
  - [Sessions](#sessions)
  - [Email/SMTP](#emailsmtp)
- [Changelog](https://github.com/Kong/charts/blob/master/charts/kong/CHANGELOG.md)
- [Seeking help](#seeking-help)

## Prerequisites

- Kubernetes 1.12+
- PV provisioner support in the underlying infrastructure if persistence
  is needed for Kong datastore.

## Important: Helm 2 vs Helm 3

Custom Resource Definitions (CRDs) are handled differently in Helm 2 vs Helm 3. In short:

#### Helm 2
If you want CRDs to be installed, make sure `ingressController.installCRDs` is set to `true` (the default value)

#### Helm 3
Make sure `ingressController.installCRDs` is set to `false` - note that the default is `false`.
You can do so either by passing in a custom `values.yaml` (`-f` when running helm)
or passing `--set ingressController.installCRDs=false` at the command line.
**If you do not set this value to `false`, the helm chart will not install correctly.**

Use `--skip-crds` with `helm install` if you want to skip CRD creation. 

## Install

To install the chart with the release name `my-release`:

```bash
$ helm repo add kong https://charts.konghq.com
$ helm repo update
$ helm install kong/kong
```

## Uninstall

To uninstall/delete the `my-release` deployment:

```bash
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the
chart and deletes the release.

> **Tip**: List all releases using `helm list`

## FAQs

Please read the
[FAQs](https://github.com/Kong/charts/blob/master/charts/kong/FAQs.md)
document.

## Kong Enterprise

If using Kong Enterprise, several additional steps are necessary before
installing the chart:

- set `enterprise.enabled` to `true` in `values.yaml` file
- Update values.yaml to use a Kong Enterprise image
- Satisfy the two  prerequsisites below for
  [Enterprise License](#kong-enterprise-license) and
  [Enterprise Docker Registry](#kong-enterprise-docker-registry-access)

Once you have these set, it is possible to install Kong Enterprise

Please read through
[Kong Enterprise considerations](#kong-enterprise-parameters)
to understand all settings that are enterprise specific.

## Deployment Options

Kong is a highly configurable piece of software that can be deployed
in a number of different ways, depending on your use-case.

All combinations of various runtimes, databases and configuration methods are
supported by this Helm chart.
The recommended approach is to use the Ingress Controller based configuration
along-with DB-less mode.

Following sections detail on various high-level architecture options available:

### Database

Kong can run with or without a database (DB-less).
By default, this chart installs Kong without a database.

Although Kong can run with Postgres and Cassandra, the recommended database,
if you would like to use one, is Postgres for Kubernetes installations.
If your use-case warrants Cassandra, you should run the Cassandra cluster
outside of Kubernetes.

The database to use for Kong can be controlled via the `env.database` parameter.
For more details, please read the [env](#the-env-section) section.

Furthermore, this chart allows you to bring your own database that you manage
or spin up a new Postgres instance using the `postgres.enabled` parameter.

> Cassandra deployment via a sub-chart was previously supported but
the support has now been dropped due to stability issues.
You can still deploy Cassandra on your own and configure Kong to use
that via the `env.database` parameter.

#### DB-less  deployment

When deploying Kong in DB-less mode(`env.database: "off"`)
and without the Ingress Controller(`ingressController.enabled: false`),
you have to provide a declarative configuration for Kong to run.
The configuration can be provided using an existing ConfigMap
(`dblessConfig.configMap`) or or the whole configuration can be put into the
`values.yaml` file for deployment itself, under the `dblessConfig.config`
parameter. See the example configuration in the default values.yaml
for more details.

### Runtime package

There are three different packages of Kong that are available:

- **Kong Gateway**\
  This is the [Open-Source](https://github.com/kong/kong) offering. It is a
  full-blown API Gateway and Ingress solution with a wide-array of functionality.
  When Kong Gateway is combined with the Ingress based configuration method,
  you get Kong for Kubernetes. This is the default deployment for this Helm
  Chart.
- **Kong Enterprise K8S**\
  This package builds up on top of the Open-Source Gateway and bundles in all
  the Enterprise-only plugins as well.
  When Kong Enterprise K8S is combined with the Ingress based
  configuration method, you get Kong for Kubernetes Enterprise.
  This package also comes with 24x7 support from Kong Inc.
- **Kong Enterprise**\
  This is the full-blown Enterprise package which packs with itself all the
  Enterprise functionality like Manager, Portal, Vitals, etc.
  This package can't be run in DB-less mode.

The package to run can be changed via `image.repository` and `image.tag`
parameters. If you would like to run the Enterprise package, please read
the [Kong Enterprise Parameters](#kong-enterprise-parameters) section.

### Configuration method

Kong can be configured via two methods:
- **Ingress and CRDs**\
  The configuration for Kong is done via `kubectl` and Kubernetes-native APIs.
  This is also known as Kong Ingress Controller or Kong for Kubernetes and is
  the default deployment pattern for this Helm Chart. The configuration
  for Kong is managed via Ingress and a few
  [Custom Resources](https://github.com/Kong/kubernetes-ingress-controller/blob/master/docs/concepts/custom-resources.md).
  For more details, please read the
  [documentation](https://github.com/Kong/kubernetes-ingress-controller/tree/master/docs)
  on Kong Ingress Controller.
  To configure and fine-tune the controller, please read the
  [Ingress Controller Parameters](#ingress-controller-parameters) section.
- **Admin API**\
  This is the traditional method of running and configuring Kong.
  By default, the Admin API of Kong is not exposed as a Service. This
  can be controlled via `admin.enabled` and `env.admin_listen` parameters.

## Configuration

### Kong parameters

| Parameter                          | Description                                                                           | Default             |
| ---------------------------------- | ------------------------------------------------------------------------------------- | ------------------- |
| image.repository                   | Kong image                                                                            | `kong`              |
| image.tag                          | Kong image version                                                                    | `1.3`               |
| image.pullPolicy                   | Image pull policy                                                                     | `IfNotPresent`      |
| image.pullSecrets                  | Image pull secrets                                                                    | `null`              |
| replicaCount                       | Kong instance count                                                                   | `1`                 |
| admin.enabled                      | Create Admin Service                                                                  | `false`             |
| admin.useTLS                       | Secure Admin traffic                                                                  | `true`              |
| admin.servicePort                  | TCP port on which the Kong admin service is exposed                                   | `8444`              |
| admin.containerPort                | TCP port on which Kong app listens for admin traffic                                  | `8444`              |
| admin.nodePort                     | Node port when service type is `NodePort`                                             |                     |
| admin.hostPort                     | Host port to use for admin traffic                                                    |                     |
| admin.type                         | k8s service type, Options: NodePort, ClusterIP, LoadBalancer                          | `NodePort`          |
| admin.loadBalancerIP               | Will reuse an existing ingress static IP for the admin service                        | `null`              |
| admin.loadBalancerSourceRanges     | Limit admin access to CIDRs if set and service type is `LoadBalancer`                 | `[]`                |
| admin.ingress.enabled              | Enable ingress resource creation (works with proxy.type=ClusterIP)                    | `false`             |
| admin.ingress.tls                  | Name of secret resource, containing TLS secret                                        |                     |
| admin.ingress.hosts                | List of ingress hosts.                                                                | `[]`                |
| admin.ingress.path                 | Ingress path.                                                                         | `/`                 |
| admin.ingress.annotations          | Ingress annotations. See documentation for your ingress controller for details        | `{}`                |
| proxy.http.enabled                 | Enables http on the proxy                                                             | true                |
| proxy.http.servicePort             | Service port to use for http                                                          | 80                  |
| proxy.http.containerPort           | Container port to use for http                                                        | 8000                |
| proxy.http.nodePort                | Node port to use for http                                                             | 32080               |
| proxy.http.hostPort                | Host port to use for http                                                             |                     |
| proxy.tls.enabled                  | Enables TLS on the proxy                                                              | true                |
| proxy.tls.containerPort            | Container port to use for TLS                                                         | 8443                |
| proxy.tls.servicePort              | Service port to use for TLS                                                           | 8443                |
| proxy.tls.nodePort                 | Node port to use for TLS                                                              | 32443               |
| proxy.tls.hostPort                 | Host port to use for TLS                                                              |                     |
| proxy.tls.overrideServiceTargetPort| Override service port to use for TLS without touching Kong containerPort              |                     |
| proxy.type                         | k8s service type. Options: NodePort, ClusterIP, LoadBalancer                          | `LoadBalancer`      |
| proxy.clusterIP                    | k8s service clusterIP                                                                 |                     |
| proxy.loadBalancerSourceRanges     | Limit proxy access to CIDRs if set and service type is `LoadBalancer`                 | `[]`                |
| proxy.loadBalancerIP               | To reuse an existing ingress static IP for the admin service                          |                     |
| proxy.externalIPs                  | IPs for which nodes in the cluster will also accept traffic for the proxy             | `[]`                |
| proxy.externalTrafficPolicy        | k8s service's externalTrafficPolicy. Options: Cluster, Local                          |                     |
| proxy.ingress.enabled              | Enable ingress resource creation (works with proxy.type=ClusterIP)                    | `false`             |
| proxy.ingress.tls                  | Name of secret resource, containing TLS secret                                        |                     |
| proxy.ingress.hosts                | List of ingress hosts.                                                                | `[]`                |
| proxy.ingress.path                 | Ingress path.                                                                         | `/`                 |
| proxy.ingress.annotations          | Ingress annotations. See documentation for your ingress controller for details        | `{}`                |
| proxy.annotations                  | Service annotations                                                                   | `{}`                |
| plugins                            | Install custom plugins into Kong via ConfigMaps or Secrets                            | `{}`                |
| env                                | Additional [Kong configurations](https://getkong.org/docs/latest/configuration/)      |                     |
| runMigrations                      | Run Kong migrations job                                                               | `true`              |
| waitImage.repository               | Image used to wait for database to become ready                                       | `busybox`           |
| waitImage.tag                      | Tag for image used to wait for database to become ready                               | `latest`            |
| waitImage.pullPolicy               | Wait image pull policy                                                                | `IfNotPresent`      |
| postgresql.enabled                 | Spin up a new postgres instance for Kong                                              | `false`             |
| dblessConfig.configMap             | Name of an existing ConfigMap containing the `kong.yml` file. This must have the key `kong.yml`.| `` |
| dblessConfig.config                | Yaml configuration file for the dbless (declarative) configuration of Kong | see in `values.yaml`    |

### Ingress Controller Parameters

All of the following properties are nested under the `ingressController`
section of `values.yaml` file:

| Parameter                          | Description                                                                           | Default                                                                      |
| ---------------------------------- | ------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| enabled                            | Deploy the ingress controller, rbac and crd                                           | true                                                                         |
| replicaCount                       | Number of desired ingress controllers                                                 | 1                                                                            |
| image.repository                   | Docker image with the ingress controller                                              | kong-docker-kubernetes-ingress-controller.bintray.io/kong-ingress-controller |
| image.tag                          | Version of the ingress controller                                                     | 0.7.0                                                                        |
| readinessProbe                     | Kong ingress controllers readiness probe                                              |                                                                              |
| livenessProbe                      | Kong ingress controllers liveness probe                                               |                                                                              |
| installCRDs                        | Create CRDs. **FOR HELM3, MAKE SURE THIS VALUE IS SET TO `false`.**                   | true                                                                         |
| serviceAccount.create              | Create Service Account for ingress controller                                         | true
| serviceAccount.name                | Use existing Service Account, specifiy its name                                       | ""
| installCRDs                        | Create CRDs. Regardless of value of this, Helm v3+ will install the CRDs if those are not present already. Use `--skip-crds` with `helm install` if you want to skip CRD creation. | true |
| env                                | Specify Kong Ingress Controller configuration via environment variables               |                                                                              |
| ingressClass                       | The ingress-class value for controller                                                | kong                                                                         |
| admissionWebhook.enabled           | Whether to enable the validating admission webhook                                    | false                                                                        |
| admissionWebhook.failurePolicy     | How unrecognized errors from the admission endpoint are handled (Ignore or Fail)      | Fail                                                                         |
| admissionWebhook.port              | The port the ingress controller will listen on for admission webhooks                 | 8080                                                                         |

For a complete list of all configuration values you can set in the
`env` section, please read the Kong Ingress Controller's
[configuration document](https://github.com/Kong/kubernetes-ingress-controller/blob/master/docs/references/cli-arguments.md).

### General Parameters

| Parameter                          | Description                                                                           | Default             |
| ---------------------------------- | ------------------------------------------------------------------------------------- | ------------------- |
| autoscaling.enabled                | Set this to `true` to enable autoscaling                                              | `false`             |
| autoscaling.minReplicas            | Set minimum number of replicas                                                        | `2`                 |
| autoscaling.maxReplicas            | Set maximum number of replicas                                                        | `5`                 |
| autoscaling.targetCPUUtilizationPercentage | Target Percentage for when autoscaling takes affect. Only used if cluster doesnt support `autoscaling/v2beta2` | `80`  |
| autoscaling.metrics                | metrics used for autoscaling for clusters that support autoscaling/v2beta2`           | See [values.yaml](values.yaml) |
| updateStrategy                     | update strategy for deployment                                                        | `{}`                |
| readinessProbe                     | Kong readiness probe                                                                  |                     |
| livenessProbe                      | Kong liveness probe                                                                   |                     |
| affinity                           | Node/pod affinities                                                                   |                     |
| nodeSelector                       | Node labels for pod assignment                                                        | `{}`                |
| podAnnotations                     | Annotations to add to each pod                                                        | `{}`                |
| resources                          | Pod resource requests & limits                                                        | `{}`                |
| tolerations                        | List of node taints to tolerate                                                       | `[]`                |
| podDisruptionBudget.enabled        | Enable PodDisruptionBudget for Kong                                                   | `false`             |
| podDisruptionBudget.maxUnavailable | Represents the minimum number of Pods that can be unavailable (integer or percentage) | `50%`               |
| podDisruptionBudget.minAvailable   | Represents the number of Pods that must be available (integer or percentage)          |                     |
| podSecurityPolicy.enabled          | Enable podSecurityPolicy for Kong                                                     | `false`             |
| priorityClassName                  | Set pod scheduling priority class for Kong pods                                       | ""                  |
| serviceMonitor.enabled             | Create ServiceMonitor for Prometheus Operator                                         | false               |
| serviceMonitor.interval            | Scrapping interval                                                                    | 10s                 |
| serviceMonitor.namespace           | Where to create ServiceMonitor                                                        |                     |
| secretVolumes                      | Mount given secrets as a volume in Kong container to override default certs and keys. | `[]`                |
| serviceMonitor.labels              | ServiceMonito Labels                                                                  | {}                  |

#### The `env` section

The `env` section can be used to configured all properties of Kong.
Any key value put under this section translates to environment variables
used to control Kong's configuration. Every key is prefixed with `KONG_`
and upper-cased before setting the environment variable.

Furthermore, all `kong.env` parameters can also accept a mapping instead of a
value to ensure the parameters can be set through configmaps and secrets.

An example :

```yaml
kong:
  env:                       # load PG password from a secret dynamically
     pg_user: kong
     pg_password:
       valueFrom:
         secretKeyRef:
            key: kong
            name: postgres
  nginx_worker_processes: "2"
```

For complete list of Kong configurations please check the
[Kong configuration docs](https://docs.konghq.com/latest/configuration).

> **Tip**: You can use the default [values.yaml](values.yaml)

##### Admin/Proxy listener override

If you specify `env.admin_listen` or `env.proxy_listen`, this chart will use
the value provided by you as opposed to constructing a listen variable
from fields like `proxy.http.containerPort` and `proxy.http.enabled`.
This allows you to be more prescriptive when defining listen directives.

**Note:** Overriding `env.proxy_listen` and `env.admin_listen` will
potentially cause `admin.containerPort`, `proxy.http.containerPort` and
`proxy.tls.containerPort` to become out of sync,
and therefore must be updated accordingly.

For example, updating to `env.proxy_listen: 0.0.0.0:4444, 0.0.0.0:4443 ssl`
will need `proxy.http.containerPort: 4444` and `proxy.tls.containerPort: 4443`
to be set in order for the service definition to work properly.

## Kong Enterprise Parameters

### Overview

Kong Enterprise requires some additional configuration not needed when using
Kong Open-Source. To use Kong Enterprise, at the minimum,
you need to do the following:

- set `enterprise.enabled` to `true` in `values.yaml` file
- Update values.yaml to use a Kong Enterprise image
- Satisfy the two  prerequsisites below for Enterprise License and
  Enterprise Docker Registry

Once you have these set, it is possible to install Kong Enterprise,
but please make sure to review the below sections for other settings that
you should consider configuring before installing Kong.

Some of the more important configuration is grouped in sections
under the `.enterprise` key in values.yaml, though most enterprise-specific
configuration can be placed under the `.env` key.

### Prerequisites

#### Kong Enterprise License

All Kong Enterprise deployments require a license. If you do not have a copy
of yours, please contact Kong Support. Once you have it, you will need to
store it in a Secret. Save your secret in a file named `license` (no extension)
and then create and inspect your secret:

```bash
$ kubectl create secret generic kong-enterprise-license --from-file=./license
```

Set the secret name in `values.yaml`, in the `.enterprise.license_secret` key.
Please ensure the above secret is created in the same namespace in which
Kong is going to be deployed.

#### Kong Enterprise Docker registry access

Next, we need to setup Docker credentials in order to allow Kubernetes
nodes to pull down Kong Enterprise Docker images, which are hosted in a private
registry.

You should received credentials to log into https://bintray.com/kong after
purchasing Kong Enterprise. After logging in, you can retrieve your API key
from \<your username\> \> Edit Profile \> API Key. Use this to create registry
secrets:

```bash
$ kubectl create secret docker-registry kong-enterprise-k8s-docker \
    --docker-server=kong-docker-kong-enterprise-k8s.bintray.io \
    --docker-username=<your-bintray-username@kong> \
    --docker-password=<your-bintray-api-key>
secret/kong-enterprise-k8s-docker created

$ kubectl create secret docker-registry kong-enterprise-edition-docker \
    --docker-server=kong-docker-kong-enterprise-edition-docker.bintray.io \
    --docker-username=<your-bintray-username@kong> \
    --docker-password=<your-bintray-api-key>
secret/kong-enterprise-edition-docker created
```

Set the secret names in `values.yaml` in the `image.pullSecrets` section.
Again, please ensure the above secret is created in the same namespace in which
Kong is going to be deployed.

### Service location hints

Kong Enterprise add two GUIs, Kong Manager and the Kong Developer Portal, that
must know where other Kong services (namely the admin and files APIs) can be
accessed in order to function properly. Kong's default behavior for attempting
to locate these absent configuration is unlikely to work in common Kubernetes
environments. Because of this, you should set each of `admin_gui_url`,
`admin_api_uri`, `proxy_url`, `portal_api_url`, `portal_gui_host`, and
`portal_gui_protocol` under the `.env` key in values.yaml to locations where
each of their respective services can be accessed to ensure that Kong services
can locate one another and properly set CORS headers. See the
[Property Reference documentation](https://docs.konghq.com/enterprise/latest/property-reference/)
for more details on these settings.

### RBAC

You can create a default RBAC superuser when initially setting up an
environment, by setting the `KONG_PASSWORD` environment variable on the initial
migration Job's Pod. This will create a `kong_admin` admin whose token and
basic-auth password match the value of `KONG_PASSWORD`.
You can create a secret holding the initial password value and then
mount the secret as an environment variable using the `env` section.

Note that RBAC is **NOT** currently enabled on the admin API container for the
controller Pod when the ingress controller is enabled. This admin API container
is not exposed outside the Pod, so only the controller can interact with it. We
intend to add RBAC to this container in the future after updating the controller
to add support for storing its RBAC token in a Secret, as currently it would
need to be stored in plaintext. RBAC is still enforced on the admin API of the
main deployment when using the ingress controller, as that admin API *is*
accessible outside the Pod.

### Sessions

Login sessions for Kong Manager and the Developer Portal make use of
[the Kong Sessions plugin](https://docs.konghq.com/enterprise/latest/kong-manager/authentication/sessions).
When configured via values.yaml, their configuration must be stored in Secrets,
as it contains an HMAC key.

Kong Manager's session configuration must be configured via values.yaml,
whereas this is optional for the Developer Portal on versions 0.36+. Providing
Portal session configuration in values.yaml provides the default session
configuration, which can be overriden on a per-workspace basis.

```
$ cat admin_gui_session_conf
{"cookie_name":"admin_session","cookie_samesite":"off","secret":"admin-secret-CHANGEME","cookie_secure":true,"storage":"kong"}
$ cat portal_session_conf
{"cookie_name":"portal_session","cookie_samesite":"off","secret":"portal-secret-CHANGEME","cookie_secure":true,"storage":"kong"}
$ kubectl create secret generic kong-session-config --from-file=admin_gui_session_conf --from-file=portal_session_conf
secret/kong-session-config created
```
The exact plugin settings may vary in your environment. The `secret` should
always be changed for both configurations.

After creating your secret, set its name in values.yaml in
`.enterprise.rbac.session_conf_secret`. If you create a Portal configuration,
add it at `env.portal_session_conf` using a secretKeyRef.

### Email/SMTP

Email is used to send invitations for
[Kong Admins](https://docs.konghq.com/enterprise/latest/kong-manager/networking/email)
and [Developers](https://docs.konghq.com/enterprise/latest/developer-portal/configuration/smtp).

Email invitations rely on setting a number of SMTP settings at once. For
convenience, these are grouped under the `.enterprise.smtp` key in values.yaml.
Setting `.enterprise.smtp.disabled: true` will set `KONG_SMTP_MOCK=on` and
allow Admin/Developer invites to proceed without sending email. Note, however,
that these have limited functionality without sending email.

If your SMTP server requires authentication, you should the `username` and
`smtp_password_secret` keys under `.enterprise.smtp.auth`.
`smtp_password_secret` must be a Secret containing an `smtp_password` key whose
value is your SMTP password.

## Seeking help

If you run into an issue, bug or have a question, please reach out to the Kong
community via [Kong Nation](https://discuss.konghq.com).
Please do not open issues in [this](https://github.com/helm/charts) repository
as the maintainers will not be notified and won't respond.
