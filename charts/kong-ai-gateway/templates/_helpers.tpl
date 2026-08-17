{{/* vim: set filetype=mustache: */}}
{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}

{{- define "kong.namespace" -}}
{{- default .Release.Namespace .Values.namespace -}}
{{- end -}}

{{- define "kong.release" -}}
{{- default .Release.Name -}}
{{- end -}}

{{- define "kong.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kong.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- default (printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-") .Values.fullnameOverride -}}
{{- end -}}

{{- define "kong.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kong.metaLabels" -}}
app.kubernetes.io/name: {{ template "kong.name" . }}
helm.sh/chart: {{ template "kong.chart" . }}
app.kubernetes.io/instance: "{{ .Release.Name }}"
app.kubernetes.io/managed-by: "{{ .Release.Service }}"
{{ $version := semver (include "kong.effectiveVersion" .Values.image) }}
app.kubernetes.io/version: {{ printf "%d.%d" $version.Major $version.Minor | quote }}
{{- range $key, $value := .Values.extraLabels }}
{{ $key }}: {{ include "kong.renderTpl" (dict "value" $value "context" $) | quote }}
{{- end }}
{{- end -}}

{{- define "kong.selectorLabels" -}}
app.kubernetes.io/name: {{ template "kong.name" . }}
app.kubernetes.io/component: app
app.kubernetes.io/instance: "{{ .Release.Name }}"
{{- end -}}

{{- define "kong.serviceAccountName" -}}
{{- if .Values.deployment.serviceAccount.create -}}
    {{ default (include "kong.fullname" .) .Values.deployment.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.deployment.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the secret for service account token to use
*/}}
{{- define "kong.serviceAccountTokenName" -}}
{{ include "kong.serviceAccountName" . }}-token
{{- end -}}

{{/*
Create Ingress resource for a Kong service
*/}}
{{- define "kong.ingress" -}}
{{- $servicePort := include "kong.ingress.servicePort" . }}
{{- $path := .ingress.path -}}
{{- $hostname := .ingress.hostname -}}
{{- $pathType := .ingress.pathType -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .fullName }}-{{ .serviceName }}
  namespace: {{ .namespace }}
  labels:
  {{- .metaLabels | nindent 4 }}
  {{- range $key, $value := .ingress.labels }}
    {{- $key | nindent 4 }}: {{ $value | quote }}
  {{- end }}
  {{- if .ingress.annotations }}
  annotations:
    {{- range $key, $value := .ingress.annotations }}
    {{ $key }}: {{ $value | quote }}
    {{- end }}
  {{- end }}
spec:
{{- if .ingress.ingressClassName }}
  ingressClassName: {{ .ingress.ingressClassName }}
{{- end }}
  rules:
  {{- if ( not (or $hostname .ingress.hosts)) }}
  - http:
      paths:
        - backend:
            service:
              name: {{ .fullName }}-{{ .serviceName }}
              port:
                number: {{ $servicePort }}
          path: {{ $path }}
          pathType: {{ $pathType }}
  {{- else if $hostname }}
  - host: {{ $hostname | quote }}
    http:
      paths:
        - backend:
            service:
              name: {{ .fullName }}-{{ .serviceName }}
              port:
                number: {{ $servicePort }}
          path: {{ $path }}
          pathType: {{ $pathType }}
  {{- end }}
  {{- range .ingress.hosts }}
  - host: {{ .host | quote }}
    http:
      paths:
        {{- range .paths }}
        - backend:
          {{- if .backend -}}
            {{ .backend | toYaml | nindent 12 }}
          {{- else }}
            service:
              name: {{ $.fullName }}-{{ $.serviceName }}
              port:
                number: {{ $servicePort }}
          {{- end }}
          {{- if (and $hostname (and (eq $path .path))) }}
          {{- fail "duplication of specified ingress path" }}
          {{- end }}
          path: {{ .path }}
          pathType: {{ .pathType }}
        {{- end }}
  {{- end }}
  {{- if (hasKey .ingress "tls") }}
  tls:
  {{- if (kindIs "string" .ingress.tls) }}
    - hosts:
      {{- range .ingress.hosts }}
        - {{ .host | quote }}
      {{- end }}
      {{- if $hostname }}
        - {{ $hostname | quote }}
      {{- end }}
      secretName: {{ .ingress.tls }}
  {{- else if (kindIs "slice" .ingress.tls) }}
    {{- range .ingress.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
  {{- end }}
{{- end -}}

{{/*
Create Service resource for a Kong service
*/}}
{{- define "kong.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .nameOverride | default (printf "%s-%s" .fullName .serviceName) }}
  namespace: {{ .namespace }}
  {{- if .annotations }}
  annotations:
  {{- range $key, $value := .annotations }}
    {{ $key }}: {{ $value | quote }}
  {{- end }}
  {{- end }}
  labels:
    {{- .metaLabels | nindent 4 }}
  {{- range $key, $value := .labels }}
    {{ $key }}: {{ $value | quote }}
  {{- end }}
spec:
  type: {{ .type }}
  {{- if eq .type "LoadBalancer" }}
  {{- if .loadBalancerIP }}
  loadBalancerIP: {{ .loadBalancerIP }}
  {{- end }}
  {{- if .loadBalancerSourceRanges }}
  loadBalancerSourceRanges:
  {{- range $cidr := .loadBalancerSourceRanges }}
  - {{ $cidr }}
  {{- end }}
  {{- end }}
  {{- if .loadBalancerClass }}
  loadBalancerClass: {{ .loadBalancerClass }}
  {{- end }}
  {{- end }}
  {{- if .externalIPs }}
  externalIPs:
  {{- range $ip := .externalIPs }}
  - {{ $ip }}
  {{- end -}}
  {{- end }}
  {{- if .ipFamilyPolicy }}
  ipFamilyPolicy: {{ .ipFamilyPolicy }}
  {{- end }}
  {{- if .ipFamilies }}
  ipFamilies:
  {{- range $family := .ipFamilies }}
  - {{ $family }}
  {{- end }}
  {{- end }}
  ports:
  {{- if .http }}
  {{- if .http.enabled }}
  {{- if ne ( .http.servicePort | toString ) "0" }}
  - name: kong-{{ .serviceName }}
    port: {{ .http.servicePort }}
    targetPort: {{ .http.containerPort }}
  {{- if .http.appProtocol }}
    appProtocol: {{ .http.appProtocol }}
  {{- end }}
  {{- if (and (or (eq .type "LoadBalancer") (eq .type "NodePort")) (not (empty .http.nodePort))) }}
    nodePort: {{ .http.nodePort }}
  {{- end }}
    protocol: TCP
  {{- end }}
  {{- end }}
  {{- end }}
  {{- if .tls.enabled }}
  - name: kong-{{ .serviceName }}-tls
    port: {{ .tls.servicePort }}
    targetPort: {{ .tls.overrideServiceTargetPort | default .tls.containerPort }}
  {{- if .tls.appProtocol }}
    appProtocol: {{ .tls.appProtocol }}
  {{- end }}
  {{- if (and (or (eq .type "LoadBalancer") (eq .type "NodePort")) (not (empty .tls.nodePort))) }}
    nodePort: {{ .tls.nodePort }}
  {{- end }}
    protocol: TCP
  {{- end }}
  {{- if (hasKey . "stream") }}
    {{- $defaultProtocol := "TCP" }}
    {{- if (hasSuffix "udp-proxy" .serviceName) }}
      {{- $defaultProtocol = "UDP" }}
    {{- end }}
    {{- range $index, $streamEntry := .stream }}
      {{- if (not (hasKey $streamEntry "protocol")) }}
        {{- $_ := set $streamEntry "protocol" $defaultProtocol }}
      {{- end }}
    {{- end }}
  {{- range .stream }}
  - name: stream{{ if (eq (default "TCP" .protocol) "UDP") }}udp{{ end }}-{{ .containerPort }}
    port: {{ .servicePort }}
    targetPort: {{ .containerPort }}
    {{- if (and (or (eq $.type "LoadBalancer") (eq $.type "NodePort")) (not (empty .nodePort))) }}
    nodePort: {{ .nodePort }}
    {{- end }}
    protocol: {{ .protocol | default "TCP" }}
  {{- end }}
  {{- end }}
  {{- if .externalTrafficPolicy }}
  externalTrafficPolicy: {{ .externalTrafficPolicy }}
  {{- end }}
  {{- if .trafficDistribution }}
  trafficDistribution: {{ .trafficDistribution }}
  {{- end }}
  {{- if .clusterIP }}
  {{- if (or (not (eq .clusterIP "None")) (and (eq .type "ClusterIP") (eq .clusterIP "None"))) }}
  clusterIP: {{ .clusterIP }}
  {{- end }}
  {{- end }}
  selector:
    {{- .selectorLabels | nindent 4 }}
{{- end -}}


{{/*
Create KONG_SERVICE_LISTEN strings
Generic tool for creating KONG_PROXY_LISTEN, KONG_ADMIN_LISTEN, etc.
*/}}
{{- define "kong.listen" -}}
  {{- $unifiedListen := list -}}
  {{- $defaultAddrs := (list "0.0.0.0" "[::]") -}}

  {{/* Some services do not support these blocks at all, so these checks are a
       two-stage "is it safe to evaluate this?" and then "should we evaluate
       this?"
  */}}
  {{- if .http -}}
    {{- if .http.enabled -}}
      {{- $listenConfig := dict -}}
      {{- $listenConfig := merge $listenConfig .http -}}
      {{- $addresses := (default $defaultAddrs .addresses) -}}
      {{- range $addresses -}}
        {{- $_ := set $listenConfig "address" . -}}
        {{- $httpListen := (include "kong.singleListen" $listenConfig) -}}
        {{- $unifiedListen = append $unifiedListen $httpListen -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- if .tls -}}
    {{- if .tls.enabled -}}
      {{/*
      This is a bit of a hack to support always including "ssl" in the parameter
      list for TLS listens. It's not possible to set a variable to an object from
      .Values and then modify one of the objects values locally, although
      https://github.com/helm/helm/issues/4987 indicates it should be. Instead,
      this creates a new object and new parameters list built from the original.
      */}}
      {{- $listenConfig := dict -}}
      {{- $listenConfig := merge $listenConfig .tls -}}
      {{- $parameters := append .tls.parameters "ssl" -}}
      {{- $_ := set $listenConfig "parameters" $parameters -}}
      {{- $addresses := (default $defaultAddrs .addresses) -}}
      {{- range $addresses -}}
        {{- $_ := set $listenConfig "address" . -}}
        {{- $tlsListen := (include "kong.singleListen" $listenConfig) -}}
        {{- $unifiedListen = append $unifiedListen $tlsListen -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- $listenString := ($unifiedListen | join ", ") -}}
  {{- if eq (len $listenString) 0 -}}
    {{- $listenString = "off" -}}
  {{- end -}}
  {{- $listenString -}}
{{- end -}}

{{/*
Create KONG_PORT_MAPS string
Parameters: takes a service (e.g. .Values.proxy) as its argument and returns KONG_PORT_MAPS for that service.
*/}}
{{- define "kong.port_maps" -}}
  {{- $portMaps := list -}}

  {{- if .http.enabled -}}
  {{- if ne (.http.servicePort | toString ) "0" -}}
        {{- $portMaps = append $portMaps (printf "%d:%d" (int64 .http.servicePort) (int64 .http.containerPort)) -}}
  {{- end -}}
  {{- end -}}

  {{- if .tls.enabled -}}
        {{- $portMaps = append $portMaps (printf "%d:%d" (int64 .tls.servicePort) (int64 .tls.containerPort)) -}}
  {{- end -}}

  {{- $portMapsString := ($portMaps | join ", ") -}}
  {{- $portMapsString -}}
{{- end -}}

{{/*
Create KONG_STREAM_LISTEN string
*/}}
{{- define "kong.streamListen" -}}
  {{- $unifiedListen := list -}}
  {{- $defaultAddrs := (list "0.0.0.0" "[::]") -}}
  {{- range .stream -}}
    {{- $listenConfig := dict -}}
    {{- $listenConfig := merge $listenConfig . -}}
    {{- $addresses := (default $defaultAddrs .addresses) -}}
    {{- range $addresses -}}
      {{- $_ := set $listenConfig "address" . -}}
      {{/* You set NGINX stream listens to UDP using a parameter due to historical reasons.
           Our configuration is dual-purpose, for both the Service and listen string, so we
           forcibly inject this parameter if that's the Service protocol. The default handles
           configs that predate the addition of the protocol field, where we only supported TCP. */}}
      {{- if (eq (default "TCP" $listenConfig.protocol) "UDP") -}}
        {{- $_ := set $listenConfig "parameters" (append (default (list) $listenConfig.parameters) "udp") -}}
      {{- end -}}
      {{- $unifiedListen = append $unifiedListen (include "kong.singleListen" $listenConfig ) -}}
    {{- end -}}
  {{- end -}}

  {{- $listenString := ($unifiedListen | join ", ") -}}
  {{- if eq (len $listenString) 0 -}}
    {{- $listenString = "" -}}
  {{- end -}}
  {{- $listenString -}}
{{- end -}}

{{/*
Create a single listen (IP+port+parameter combo)
*/}}
{{- define "kong.singleListen" -}}
  {{- $listen := list -}}
  {{- $listen = append $listen (printf "%s:%d" .address (int64 .containerPort)) -}}
  {{- range $param := .parameters | default (list) | uniq }}
    {{- $listen = append $listen $param -}}
  {{- end -}}
  {{- $listen | join " " -}}
{{- end -}}

{{/*
Return the admin API service name for service discovery
*/}}
{{- define "kong.ingress.servicePort" -}}
{{- if .tls.enabled -}}
   {{ .tls.servicePort }}
{{- else -}}
   {{ .http.servicePort }}
{{- end -}}
{{- end -}}

{{/*
Generate an appropriate external URL from a Kong service's ingress configuration
Strips trailing slashes from the path. Manager at least does not handle these
intelligently and will append its own slash regardless, and the admin API cannot handle
the extra slash.
*/}}

{{- define "kong.ingress.serviceUrl" -}}
{{- if .tls -}}
    https://{{ .hostname }}{{ .path | trimSuffix "/" }}
{{- else -}}
    http://{{ .hostname }}{{ .path | trimSuffix "/" }}
{{- end -}}
{{- end -}}

{{/*
The name of the service used for the ingress controller's validation webhook
*/}}

{{- define "kong.userDefinedVolumes" -}}
{{- if .Values.deployment.userDefinedVolumes }}
{{- toYaml .Values.deployment.userDefinedVolumes }}
{{- end }}
{{- end -}}

{{- define "kong.volumes" -}}
- name: {{ template "kong.fullname" . }}-prefix-dir
  emptyDir:
    sizeLimit: {{ .Values.deployment.prefixDir.sizeLimit }}
- name: {{ template "kong.fullname" . }}-tmp
  emptyDir:
    sizeLimit: {{ .Values.deployment.tmpDir.sizeLimit }}
{{- if (and (not .Values.deployment.serviceAccount.automountServiceAccountToken) (or .Values.deployment.serviceAccount.create .Values.deployment.serviceAccount.name)) }}
- name: {{ template "kong.serviceAccountTokenName" . }}
  {{- /* Due to GKE versions (e.g. v1.23.15-gke.1900) we need to handle pre-release part of the version as well.
  See the related documentation of semver module that Helm depends on for semverCompare:
  https://github.com/Masterminds/semver#working-with-prerelease-versions
  Related Helm issue: https://github.com/helm/helm/issues/3810 */}}
  {{- if semverCompare ">=1.20.0-0" .Capabilities.KubeVersion.Version }}
  projected:
    sources:
    - serviceAccountToken:
        expirationSeconds: 3607
        path: token
    - configMap:
        items:
        - key: ca.crt
          path: ca.crt
        name: kube-root-ca.crt
    - downwardAPI:
        items:
        - fieldRef:
            apiVersion: v1
            fieldPath: metadata.namespace
          path: namespace
  {{- else }}
  secret:
    secretName: {{ template "kong.serviceAccountTokenName" . }}
    items:
    - key: token
      path: token
    - key: ca.crt
      path: ca.crt
    - key: namespace
      path: namespace
  {{- end }}
{{- end }}
{{- if and ( .Capabilities.APIVersions.Has "cert-manager.io/v1" ) .Values.certificates.enabled -}}
{{- if .Values.certificates.cluster.enabled }}
- name: {{ include "kong.fullname" . }}-cluster-cert
  secret:
    secretName: {{ include "kong.fullname" . }}-cluster-cert
{{- end }}
{{- if .Values.certificates.proxy.enabled }}
- name: {{ include "kong.fullname" . }}-proxy-cert
  secret:
    secretName: {{ include "kong.fullname" . }}-proxy-cert
{{- end }}
{{- if .Values.certificates.admin.enabled }}
- name: {{ include "kong.fullname" . }}-admin-cert
  secret:
    secretName: {{ include "kong.fullname" . }}-admin-cert
{{- end }}
{{- if .Values.enterprise.enabled }}
{{- if .Values.certificates.manager.enabled }}
- name: {{ include "kong.fullname" . }}-manager-cert
  secret:
    secretName: {{ include "kong.fullname" . }}-manager-cert
{{- end }}
{{- if .Values.certificates.portal.enabled }}
- name: {{ include "kong.fullname" . }}-portal-cert
  secret:
    secretName: {{ include "kong.fullname" . }}-portal-cert
{{- end }}
{{- end }}
{{- end }}
{{- range .Values.plugins.configMaps }}
- name: kong-plugin-{{ .pluginName }}
  configMap:
    name: {{ .name }}
{{- range .subdirectories }}
- name: {{ .name }}
  configMap:
    name: {{ .name }}
{{- end }}
{{- end }}
{{- range .Values.plugins.secrets }}
- name: kong-plugin-{{ .pluginName }}
  secret:
    secretName: {{ .name }}
{{- range .subdirectories }}
- name: {{ .name }}
  secret:
    secretName: {{ .name }}
{{- end }}
{{- end }}

{{- if or $.Values.admin.tls.client.secretName $.Values.admin.tls.client.caBundle }}
- name: admin-client-ca
  configMap:
    name: {{ template "kong.fullname" . }}-admin-client-ca
{{- end -}}
{{- range $secretVolume := .Values.secretVolumes }}
- name: {{ . }}
  secret:
    secretName: {{ . }}
{{- end }}
{{- range .Values.extraConfigMaps }}
- name: {{ .name }}
  configMap:
    name: {{ .name }}
{{- end }}
{{- range .Values.extraSecrets }}
- name: {{ .name }}
  secret:
    secretName: {{ .name }}
{{- end }}
{{- end -}}

{{- define "kong.userDefinedVolumeMounts" -}}
{{- if .userDefinedVolumeMounts }}
{{- toYaml .userDefinedVolumeMounts }}
{{- end }}
{{- end -}}

{{- define "kong.volumeMounts" -}}
- name: {{ template "kong.fullname" . }}-prefix-dir
  mountPath: /kong_prefix/
- name: {{ template "kong.fullname" . }}-tmp
  mountPath: /tmp
{{- if and ( .Capabilities.APIVersions.Has "cert-manager.io/v1" ) .Values.certificates.enabled -}}
{{- if .Values.certificates.cluster.enabled }}
- name: {{ include "kong.fullname" . }}-cluster-cert
  mountPath: /etc/cert-manager/cluster/
{{- end }}
{{- if .Values.certificates.proxy.enabled }}
- name: {{ include "kong.fullname" . }}-proxy-cert
  mountPath: /etc/cert-manager/proxy/
{{- end }}
{{- if .Values.certificates.admin.enabled }}
- name: {{ include "kong.fullname" . }}-admin-cert
  mountPath: /etc/cert-manager/admin/
{{- end }}
{{- if .Values.enterprise.enabled }}
{{- if .Values.certificates.manager.enabled }}
- name: {{ include "kong.fullname" . }}-manager-cert
  mountPath: /etc/cert-manager/manager/
{{- end }}
{{- if .Values.certificates.portal.enabled }}
- name: {{ include "kong.fullname" . }}-portal-cert
  mountPath: /etc/cert-manager/portal/
{{- end }}
{{- end }}
{{- end }}
{{- if or $.Values.admin.tls.client.caBundle $.Values.admin.tls.client.secretName }}
- name: admin-client-ca
  mountPath: /etc/admin-client-ca/
  readOnly: true
{{- end -}}
{{- range .Values.secretVolumes }}
- name:  {{ . }}
  mountPath: /etc/secrets/{{ . }}
{{- end }}
{{- range .Values.plugins.configMaps }}
{{- $mountPath := printf "/opt/kong/plugins/%s" .pluginName }}
- name:  kong-plugin-{{ .pluginName }}
  mountPath: {{ $mountPath }}
  readOnly: true
{{- range .subdirectories }}
- name: {{ .name  }}
  mountPath: {{ printf "%s/%s" $mountPath ( .path | default .name ) }}
  readOnly: true
{{- end }}
{{- end }}
{{- range .Values.plugins.secrets }}
{{- $mountPath := printf "/opt/kong/plugins/%s" .pluginName }}
- name:  kong-plugin-{{ .pluginName }}
  mountPath: {{ $mountPath }}
  readOnly: true
{{- range .subdirectories }}
- name: {{ .name }}
  mountPath: {{ printf "%s/%s" $mountPath .path }}
  readOnly: true
{{- end }}
{{- end }}

{{- range .Values.extraConfigMaps }}
- name:  {{ .name }}
  mountPath: {{ .mountPath }}

  {{- if .subPath }}
  subPath: {{ .subPath }}
  {{- end }}
{{- end }}
{{- range .Values.extraSecrets }}
- name:  {{ .name }}
  mountPath: {{ .mountPath }}

  {{- if .subPath }}
  subPath: {{ .subPath }}
  {{- end }}
{{- end }}

{{- end -}}

{{- define "kong.plugins" -}}
{{ $myList := list "bundled" }}
{{- range .Values.plugins.configMaps -}}
{{- $myList = append $myList .pluginName -}}
{{- end -}}
{{- range .Values.plugins.secrets -}}
  {{ $myList = append $myList .pluginName -}}
{{- end }}
{{- if .Values.plugins.preInstalled -}}
  {{- $preInstalledPlugins := split "," .Values.plugins.preInstalled -}}
  {{- range $preInstalledPlugins -}}
    {{- $myList = append $myList . -}}
  {{- end -}}
{{- end }}
{{- $myList | uniq | join "," -}}
{{- end -}}

{{- define "kong.effectiveVersion" -}}
{{- /* Because Kong Gateway enterprise uses versions with 4 segments and not 3 */ -}}
{{- /* as semver does, we need to account for that here by extracting */ -}}
{{- /* first 3 segments for comparison */ -}}
{{- if .effectiveSemver -}}
  {{- if regexMatch "^[0-9]+.[0-9]+.[0-9]+" .effectiveSemver -}}
  {{- regexFind "^[0-9]+.[0-9]+.[0-9]+" .effectiveSemver -}}
  {{- else -}}
  {{- .effectiveSemver -}}
  {{- end -}}
{{- else -}}
  {{- $tag := (trimSuffix "-redhat" .tag) -}}
  {{- if regexMatch "^[0-9]+.[0-9]+.[0-9]+" .tag -}}
  {{- regexFind "^[0-9]+.[0-9]+.[0-9]+" .tag -}}
  {{- else -}}
  {{- .tag -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "secretkeyref" -}}
valueFrom:
  secretKeyRef:
    name: {{ .name }}
    key: {{ .key }}
{{- end -}}

{{/*
Use the Pod security context defined in Values or set the UID by default
*/}}
{{- define "kong.podsecuritycontext" -}}
{{ .Values.securityContext | toYaml }}
{{- end -}}

{{- define "kong.no_daemon_env" -}}
{{- template "kong.env" . }}
- name: KONG_NGINX_DAEMON
  value: "off"
{{- end -}}

{{/*
The environment values passed to Kong; this should come after all
the template that it itself is using form the above sections.
*/}}
{{- define "kong.env" -}}
{{/*
    ====== AUTO-GENERATED ENVIRONMENT VARIABLES ======
*/}}
{{- $autoEnv := dict -}}

{{- $_ := set $autoEnv "KONG_LUA_PACKAGE_PATH" "/opt/?.lua;/opt/?/init.lua;;" -}}

{{- $_ := set $autoEnv "KONG_PROXY_ACCESS_LOG" "/dev/stdout" -}}
{{- $_ := set $autoEnv "KONG_PROXY_STREAM_ACCESS_LOG" "/dev/stdout basic" -}}
{{- $_ := set $autoEnv "KONG_ADMIN_ACCESS_LOG" "/dev/stdout" -}}
{{- $_ := set $autoEnv "KONG_STATUS_ACCESS_LOG" "off" -}}
{{- $_ := set $autoEnv "KONG_PROXY_ERROR_LOG" "/dev/stderr" -}}
{{- $_ := set $autoEnv "KONG_PROXY_STREAM_ERROR_LOG" "/dev/stderr" -}}
{{- $_ := set $autoEnv "KONG_ADMIN_ERROR_LOG" "/dev/stderr" -}}
{{- $_ := set $autoEnv "KONG_STATUS_ERROR_LOG" "/dev/stderr" -}}

{{- with .Values.admin -}}
  {{- $listenConfig := dict -}}
  {{- $listenConfig := merge $listenConfig . -}}
  {{- if (and (not (hasKey . "addresses")) (not .enabled)) -}}
    {{- $_ := set $listenConfig "addresses" (list "127.0.0.1" "[::1]") -}}
  {{- end -}}
  {{- $_ := set $autoEnv "KONG_ADMIN_LISTEN" (include "kong.listen" $listenConfig) -}}

  {{- if or .tls.client.secretName .tls.client.caBundle -}}
    {{- $_ := set $autoEnv "KONG_NGINX_ADMIN_SSL_VERIFY_CLIENT" "on" -}}
    {{- $_ := set $autoEnv "KONG_NGINX_ADMIN_SSL_CLIENT_CERTIFICATE" "/etc/admin-client-ca/tls.crt" -}}
  {{- end -}}

{{- end -}}

{{- if and ( .Capabilities.APIVersions.Has "cert-manager.io/v1" ) .Values.certificates.enabled -}}
  {{- if (and .Values.certificates.cluster.enabled .Values.cluster.enabled) -}}
    {{- $_ := set $autoEnv "KONG_CLUSTER_MTLS" "pki" -}}
    {{- $_ := set $autoEnv "KONG_CLUSTER_SERVER_NAME" .Values.certificates.cluster.commonName -}}
    {{- $_ := set $autoEnv "KONG_CLUSTER_CA_CERT" "/etc/cert-manager/cluster/ca.crt" -}}
    {{- $_ := set $autoEnv "KONG_CLUSTER_CERT" "/etc/cert-manager/cluster/tls.crt" -}}
    {{- $_ := set $autoEnv "KONG_CLUSTER_CERT_KEY" "/etc/cert-manager/cluster/tls.key" -}}
  {{- end -}}

  {{- if .Values.certificates.proxy.enabled -}}
    {{- $_ := set $autoEnv "KONG_SSL_CERT" "/etc/cert-manager/proxy/tls.crt" -}}
    {{- $_ := set $autoEnv "KONG_SSL_CERT_KEY" "/etc/cert-manager/proxy/tls.key" -}}
  {{- end -}}

  {{- if .Values.certificates.admin.enabled -}}
    {{- $_ := set $autoEnv "KONG_ADMIN_SSL_CERT" "/etc/cert-manager/admin/tls.crt" -}}
    {{- $_ := set $autoEnv "KONG_ADMIN_SSL_CERT_KEY" "/etc/cert-manager/admin/tls.key" -}}
  {{- end -}}

  {{- if .Values.enterprise.enabled -}}
    {{- if .Values.certificates.manager.enabled -}}
      {{- $_ := set $autoEnv "KONG_ADMIN_GUI_SSL_CERT" "/etc/cert-manager/manager/tls.crt" -}}
      {{- $_ := set $autoEnv "KONG_ADMIN_GUI_SSL_CERT_KEY" "/etc/cert-manager/manager/tls.key" -}}
    {{- else if .Values.certificates.admin.enabled -}}
      {{- $_ := set $autoEnv "KONG_ADMIN_GUI_SSL_CERT" "/etc/cert-manager/admin/tls.crt" -}}
      {{- $_ := set $autoEnv "KONG_ADMIN_GUI_SSL_CERT_KEY" "/etc/cert-manager/admin/tls.key" -}}
    {{- end -}}
  {{- end -}}

  {{- if .Values.enterprise.enabled }}
    {{- if .Values.certificates.portal.enabled -}}
      {{- $_ := set $autoEnv "KONG_PORTAL_API_SSL_CERT" "/etc/cert-manager/portal/tls.crt" -}}
      {{- $_ := set $autoEnv "KONG_PORTAL_API_SSL_CERT_KEY" "/etc/cert-manager/portal/tls.key" -}}
      {{- $_ := set $autoEnv "KONG_PORTAL_GUI_SSL_CERT" "/etc/cert-manager/portal/tls.crt" -}}
      {{- $_ := set $autoEnv "KONG_PORTAL_GUI_SSL_CERT_KEY" "/etc/cert-manager/portal/tls.key" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- if .Values.admin.ingress.enabled }}
  {{- $_ := set $autoEnv "KONG_ADMIN_GUI_API_URL" (include "kong.ingress.serviceUrl" .Values.admin.ingress) -}}
  {{- $_ := set $autoEnv "KONG_ADMIN_API_URI" (include "kong.ingress.serviceUrl" .Values.admin.ingress) -}}
{{- end -}}

{{- $_ := set $autoEnv "KONG_PROXY_LISTEN" (include "kong.listen" .Values.proxy) -}}

{{- $streamStrings := list -}}
{{- if .Values.proxy.enabled -}}
  {{- $tcpStreamString := (include "kong.streamListen" .Values.proxy) -}}
  {{- if (not (eq $tcpStreamString "")) -}}
    {{- $streamStrings = (append $streamStrings $tcpStreamString) -}}
  {{- end -}}
{{- end -}}
{{- if .Values.udpProxy.enabled -}}
  {{- $udpStreamString := (include "kong.streamListen" .Values.udpProxy) -}}
  {{- if (not (eq $udpStreamString "")) -}}
    {{- $streamStrings = (append $streamStrings $udpStreamString) -}}
  {{- end -}}
{{- end -}}
{{- $streamString := $streamStrings | join ", " -}}
{{- if (eq (len $streamString) 0)  -}}
  {{- $streamString = "off" -}}
{{- end -}}
{{- $_ := set $autoEnv "KONG_STREAM_LISTEN" $streamString -}}

{{- $_ := set $autoEnv "KONG_STATUS_LISTEN" (include "kong.listen" .Values.status) -}}

{{- if .Values.proxy.enabled -}}
  {{- $_ := set $autoEnv "KONG_PORT_MAPS" (include "kong.port_maps" .Values.proxy) -}}
{{- end -}}

{{- $_ := set $autoEnv "KONG_CLUSTER_LISTEN" (include "kong.listen" .Values.cluster) -}}

{{- if .Values.enterprise.enabled }}
  {{- $_ := set $autoEnv "KONG_PORTAL_API_ACCESS_LOG" "/dev/stdout" -}}
  {{- $_ := set $autoEnv "KONG_PORTAL_GUI_ACCESS_LOG" "/dev/stdout" -}}
  {{- $_ := set $autoEnv "KONG_ADMIN_GUI_ACCESS_LOG" "/dev/stdout" -}}
  {{- $_ := set $autoEnv "KONG_PORTAL_API_ERROR_LOG" "/dev/stderr" -}}
  {{- $_ := set $autoEnv "KONG_PORTAL_GUI_ERROR_LOG" "/dev/stderr" -}}
  {{- $_ := set $autoEnv "KONG_ADMIN_GUI_ERROR_LOG" "/dev/stderr" -}}

  {{- if not .Values.enterprise.vitals.enabled }}
    {{- $_ := set $autoEnv "KONG_VITALS" "off" -}}
  {{- end }}

  {{- if .Values.enterprise.rbac.enabled }}
    {{- $_ := set $autoEnv "KONG_ENFORCE_RBAC" "on" -}}
    {{- $_ := set $autoEnv "KONG_ADMIN_GUI_AUTH" .Values.enterprise.rbac.admin_gui_auth | default "basic-auth" -}}

    {{- if not (eq .Values.enterprise.rbac.admin_gui_auth "basic-auth") }}
      {{- $guiAuthConf := include "secretkeyref" (dict "name" .Values.enterprise.rbac.admin_gui_auth_conf_secret "key" "admin_gui_auth_conf") -}}
      {{- $_ := set $autoEnv "KONG_ADMIN_GUI_AUTH_CONF" $guiAuthConf -}}
    {{- end }}

    {{/*
    KONG_ADMIN_GUI_SESSION_CONF is required for Kong versions <3.6.0.
    For >=3.6.0, when openid-connect is used as the admin_gui_auth, the session_conf_secret is not required.
    https://docs.konghq.com/gateway/3.6.x/kong-manager/auth/oidc/migrate/
    */}}
    {{- if or (not (eq .Values.enterprise.rbac.admin_gui_auth "openid-connect"))
              (semverCompare "< 3.6.0" (include "kong.effectiveVersion" .Values.image))
    -}}
      {{- $guiSessionConf := include "secretkeyref" (dict "name" .Values.enterprise.rbac.session_conf_secret "key" "admin_gui_session_conf") -}}
      {{- $_ := set $autoEnv "KONG_ADMIN_GUI_SESSION_CONF" $guiSessionConf -}}
    {{- end }}
  {{- end }}

  {{- if .Values.enterprise.smtp.enabled }}
    {{- $_ := set $autoEnv "KONG_SMTP_MOCK" "off" -}}
    {{- $_ := set $autoEnv "KONG_PORTAL_EMAILS_FROM" .Values.enterprise.smtp.portal_emails_from -}}
    {{- $_ := set $autoEnv "KONG_PORTAL_EMAILS_REPLY_TO" .Values.enterprise.smtp.portal_emails_reply_to -}}
    {{- $_ := set $autoEnv "KONG_ADMIN_EMAILS_FROM" .Values.enterprise.smtp.admin_emails_from -}}
    {{- $_ := set $autoEnv "KONG_ADMIN_EMAILS_REPLY_TO" .Values.enterprise.smtp.admin_emails_reply_to -}}
    {{- $_ := set $autoEnv "KONG_SMTP_ADMIN_EMAILS" .Values.enterprise.smtp.smtp_admin_emails -}}
    {{- $_ := set $autoEnv "KONG_SMTP_HOST" .Values.enterprise.smtp.smtp_host -}}
    {{- $_ := set $autoEnv "KONG_SMTP_AUTH_TYPE" .Values.enterprise.smtp.smtp_auth_type -}}
    {{- $_ := set $autoEnv "KONG_SMTP_SSL" .Values.enterprise.smtp.smtp_ssl -}}
    {{- $_ := set $autoEnv "KONG_SMTP_PORT" .Values.enterprise.smtp.smtp_port -}}
    {{- $_ := set $autoEnv "KONG_SMTP_STARTTLS" (quote .Values.enterprise.smtp.smtp_starttls) -}}
    {{- if .Values.enterprise.smtp.auth.smtp_username }}
      {{- $_ := set $autoEnv "KONG_SMTP_USERNAME" .Values.enterprise.smtp.auth.smtp_username -}}
      {{- $smtpPassword := include "secretkeyref" (dict "name" .Values.enterprise.smtp.auth.smtp_password_secret "key" "smtp_password") -}}
      {{- $_ := set $autoEnv "KONG_SMTP_PASSWORD" $smtpPassword -}}
    {{- end }}
  {{- else }}
    {{- $_ := set $autoEnv "KONG_SMTP_MOCK" "on" -}}
  {{- end }}

  {{- if .Values.enterprise.license_secret -}}
    {{- $lic := include "secretkeyref" (dict "name" .Values.enterprise.license_secret "key" "license") -}}
    {{- $_ := set $autoEnv "KONG_LICENSE_DATA" $lic -}}
  {{- end }}

{{- end }} {{/* End of the Enterprise settings block */}}


{{- if (.Values.plugins) }}
{{- $_ := set $autoEnv "KONG_PLUGINS" (include "kong.plugins" .) -}}
{{- end }}

{{/*
    ====== USER-SET ENVIRONMENT VARIABLES ======
*/}}

{{- $userEnv := dict -}}
{{- range $key, $val := .Values.env }}
  {{- if (contains "_log" $key) -}}
    {{- if (eq (typeOf $val) "bool") -}}
      {{- fail (printf "env.%s must use string 'off' to disable. Without quotes, YAML will coerce the value to a boolean and Kong will reject it" $key) -}}
	{{- end -}}
  {{- end -}}
  {{- $upper := upper $key -}}
  {{- $var := printf "KONG_%s" $upper -}}
  {{- $_ := set $userEnv $var $val -}}
{{- end -}}

{{/*
    ====== CUSTOM-SET ENVIRONMENT VARIABLES ======
*/}}

{{- $customEnv := dict -}}
{{- range $key, $val := .Values.customEnv }}
  {{- $upper := upper $key -}}
  {{- $_ := set $customEnv $upper $val -}}
{{- end -}}

{{/*
      ====== MERGE AND RENDER ENV BLOCK ======
*/}}

{{- $completeEnv := mergeOverwrite $autoEnv $userEnv $customEnv -}}
{{- template "kong.renderEnv" $completeEnv -}}

{{- end -}}

{{/*
Given a dictionary of variable=value pairs, render a container env block.
Environment variables are sorted alphabetically
*/}}
{{- define "kong.renderEnv" -}}

{{- $dict := . -}}

{{- range keys . | sortAlpha }}
{{- $val := pluck . $dict | first -}}
{{- $valueType := printf "%T" $val -}}
{{ if eq $valueType "map[string]interface {}" }}
- name: {{ . }}
{{ toYaml $val | indent 2 -}}
{{- else if eq $valueType "string" }}
{{- if regexMatch "valueFrom" $val }}
- name: {{ . }}
{{ $val | indent 2 }}
{{- else }}
- name: {{ . }}
  value: {{ $val | quote }}
{{- end }}
{{- else }}
- name: {{ . }}
  value: {{ $val | quote }}
{{- end }}
{{- end -}}

{{- end -}}

{{- define "kong.deprecation-warnings" -}}
  {{- $warnings := list -}}
  {{- range $warning := . }}
    {{- $warnings = append $warnings (wrap 80 (printf "WARNING: %s" $warning)) -}}
    {{- $warnings = append $warnings "\n\n" -}}
  {{- end -}}
  {{- $warningString := ($warnings | join "") -}}
  {{- $warningString -}}
{{- end -}}

{{- define "kong.getRepoTag" -}}
{{- if .unifiedRepoTag }}
{{- .unifiedRepoTag }}
{{- else if .repository }}
{{- .repository }}:{{ .tag }}
{{- end -}}
{{- end -}}

{{- define "kong.autoscalingVersion" -}}
{{- if (.Capabilities.APIVersions.Has "autoscaling/v2") -}}
autoscaling/v2
{{- else if (.Capabilities.APIVersions.Has "autoscaling/v2beta2") -}}
autoscaling/v2beta2
{{- else -}}
autoscaling/v1
{{- end -}}
{{- end -}}

{{- define "kong.policyVersion" -}}
{{- if (.Capabilities.APIVersions.Has "policy/v1beta1" ) -}}
policy/v1beta1
{{- else -}}
{{- fail (printf "Cluster doesn't have policy/v1beta1 API." ) }}
{{- end -}}
{{- end -}}

{{- define "kong.renderTpl" -}}
    {{- if typeIs "string" .value }}
{{- tpl .value .context }}
    {{- else }}
{{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}

{{- define "kong.ingressVersion" -}}
{{- if (.Capabilities.APIVersions.Has "networking.k8s.io/v1") -}}
networking.k8s.io/v1
{{- else if (.Capabilities.APIVersions.Has "networking.k8s.io/v1beta1") -}}
networking.k8s.io/v1beta1
{{- else -}}
extensions/v1beta1
{{- end -}}
{{- end -}}

{{- define "kong.proxy.compatibleReadiness" -}}
{{- $proxyReadiness := .Values.readinessProbe -}}
{{- if (semverCompare "< 3.3.0" (include "kong.effectiveVersion" .Values.image)) -}}
    {{- if (eq $proxyReadiness.httpGet.path "/status/ready") -}}
        {{- $_ := set $proxyReadiness.httpGet "path" "/status" -}}
    {{- end -}}
{{- end -}}
{{- (toYaml $proxyReadiness) -}}
{{- end -}}

{{- define "kong.envFrom" -}}
  {{- if (gt (len .) 0) -}}
envFrom:
{{- toYaml . | nindent 2 -}}
  {{- else -}}
  {{- end -}}
{{- end -}}

