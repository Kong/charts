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
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- range $key, $value := .Values.extraLabels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}

{{- define "kong.selectorLabels" -}}
app.kubernetes.io/name: {{ template "kong.name" . }}
app.kubernetes.io/component: app
app.kubernetes.io/instance: "{{ .Release.Name }}"
{{- end -}}

{{- define "kong.postgresql.fullname" -}}
{{- $name := default "postgresql" .Values.postgresql.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kong.dblessConfig.fullname" -}}
{{- $name := default "kong-custom-dbless-config" .Values.dblessConfig.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
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
apiVersion: {{ .ingressVersion }}
kind: Ingress
metadata:
  name: {{ .fullName }}-{{ .serviceName }}
  namespace: {{ .namespace }}
  labels:
  {{- .metaLabels | nindent 4 }}
  {{- if .ingress.annotations }}
  annotations:
    {{- range $key, $value := .ingress.annotations }}
    {{ $key }}: {{ $value | quote }}
    {{- end }}
  {{- end }}
spec:
{{- if (and (not (eq .ingressVersion "extensions/v1beta1")) .ingress.ingressClassName) }}
  ingressClassName: {{ .ingress.ingressClassName }}
{{- end }}
  rules:
  - host: {{ $hostname | quote }}
    http:
      paths:
        - backend:
          {{- if (not (eq .ingressVersion "networking.k8s.io/v1")) }}
            serviceName: {{ .fullName }}-{{ .serviceName }}
            servicePort: {{ $servicePort }}
          {{- else }}
            service:
              name: {{ .fullName }}-{{ .serviceName }}
              port:
                number: {{ $servicePort }}
            {{- end }}
          path: {{ $path }}
          {{- if (not (eq .ingressVersion "extensions/v1beta1")) }}
          pathType: {{ $pathType }}
          {{- end }}
  {{- if (hasKey .ingress "tls") }}
  tls:
  - hosts:
    - {{ $hostname | quote }}
    secretName: {{ .ingress.tls }}
  {{- end -}}
{{- end -}}

{{/*
Create Service resource for a Kong service
*/}}
{{- define "kong.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .fullName }}-{{ .serviceName }}
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
  {{- end }}
  {{- if .externalIPs }}
  externalIPs:
  {{- range $ip := .externalIPs }}
  - {{ $ip }}
  {{- end -}}
  {{- end }}
  ports:
  {{- if .http }}
  {{- if .http.enabled }}
  - name: kong-{{ .serviceName }}
    port: {{ .http.servicePort }}
    targetPort: {{ .http.containerPort }}
    appProtocol: http
  {{- if (and (or (eq .type "LoadBalancer") (eq .type "NodePort")) (not (empty .http.nodePort))) }}
    nodePort: {{ .http.nodePort }}
  {{- end }}
    protocol: TCP
  {{- end }}
  {{- end }}
  {{- if .tls.enabled }}
  - name: kong-{{ .serviceName }}-tls
    port: {{ .tls.servicePort }}
    targetPort: {{ .tls.overrideServiceTargetPort | default .tls.containerPort }}
    appProtocol: https
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
  {{- if .clusterIP }}
  clusterIP: {{ .clusterIP }}
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

  {{/* Some services do not support these blocks at all, so these checks are a
       two-stage "is it safe to evaluate this?" and then "should we evaluate
       this?"
  */}}
  {{- if .http -}}
    {{- if .http.enabled -}}
      {{- $listenConfig := dict -}}
      {{- $listenConfig := merge $listenConfig .http -}}
      {{- $_ := set $listenConfig "address" (default "0.0.0.0" .address) -}}
      {{- $httpListen := (include "kong.singleListen" $listenConfig) -}}
      {{- $unifiedListen = append $unifiedListen $httpListen -}}
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
      {{- $_ := set $listenConfig "address" (default "0.0.0.0" .address) -}}
      {{- $tlsListen := (include "kong.singleListen" $listenConfig) -}}
      {{- $unifiedListen = append $unifiedListen $tlsListen -}}
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
        {{- $portMaps = append $portMaps (printf "%d:%d" (int64 .http.servicePort) (int64 .http.containerPort)) -}}
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
  {{- range .stream -}}
    {{- $listenConfig := dict -}}
    {{- $listenConfig := merge $listenConfig . -}}
    {{- $_ := set $listenConfig "address" "0.0.0.0" -}}
    {{/* You set NGINX stream listens to UDP using a parameter due to historical reasons.
         Our configuration is dual-purpose, for both the Service and listen string, so we
         forcibly inject this parameter if that's the Service protocol. The default handles
         configs that predate the addition of the protocol field, where we only supported TCP. */}}
    {{- if (eq (default "TCP" .protocol) "UDP") -}}
      {{- $_ := set $listenConfig "parameters" (append (default (list) .parameters) "udp") -}}
    {{- end -}}
    {{- $unifiedListen = append $unifiedListen (include "kong.singleListen" $listenConfig ) -}}
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
Return the local admin API URL, preferring HTTPS if available
*/}}
{{- define "kong.adminLocalURL" -}}
  {{- if .Values.admin.tls.enabled -}}
https://localhost:{{ .Values.admin.tls.containerPort }}
  {{- else if .Values.admin.http.enabled -}}
http://localhost:{{ .Values.admin.http.containerPort }}
  {{- else -}}
http://localhost:9999 # You have no admin listens! The controller will not work unless you set .Values.admin.http.enabled=true or .Values.admin.tls.enabled=true!
  {{- end -}}
{{- end -}}

{{/*
Create the ingress servicePort value string
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

{{- define "kong.service.validationWebhook" -}}
{{ include "kong.fullname" . }}-validation-webhook
{{- end -}}

{{- define "kong.ingressController.env" -}}
{{/*
    ====== AUTO-GENERATED ENVIRONMENT VARIABLES ======
*/}}

{{- $autoEnv := dict -}}
{{- $_ := set $autoEnv "CONTROLLER_KONG_ADMIN_TLS_SKIP_VERIFY" true -}}
{{- $_ := set $autoEnv "CONTROLLER_PUBLISH_SERVICE" (printf "%s/%s-proxy" ( include "kong.namespace" . ) (include "kong.fullname" .)) -}}
{{- $_ := set $autoEnv "CONTROLLER_INGRESS_CLASS" .Values.ingressController.ingressClass -}}
{{- $_ := set $autoEnv "CONTROLLER_ELECTION_ID" (printf "kong-ingress-controller-leader-%s" .Values.ingressController.ingressClass) -}}
{{- $_ := set $autoEnv "CONTROLLER_KONG_ADMIN_URL" (include "kong.adminLocalURL" .) -}}
{{- if .Values.ingressController.admissionWebhook.enabled }}
  {{- $_ := set $autoEnv "CONTROLLER_ADMISSION_WEBHOOK_LISTEN" (printf "0.0.0.0:%d" (int64 .Values.ingressController.admissionWebhook.port)) -}}
{{- end }}
{{- if (not (eq (len .Values.ingressController.watchNamespaces) 0)) }}
  {{- $_ := set $autoEnv "CONTROLLER_WATCH_NAMESPACE" (.Values.ingressController.watchNamespaces | join ",") -}}
{{- end }}

{{/*
    ====== USER-SET ENVIRONMENT VARIABLES ======
*/}}

{{- $userEnv := dict -}}
{{- range $key, $val := .Values.ingressController.env }}
  {{- $upper := upper $key -}}
  {{- $var := printf "CONTROLLER_%s" $upper -}}
  {{- $_ := set $userEnv $var $val -}}
{{- end -}}

{{/*
    ====== CUSTOM-SET INGRESS CONTROLLER ENVIRONMENT VARIABLES ======
*/}}

{{- $customIngressEnv := dict -}}
{{- range $key, $val := .Values.ingressController.customEnv }}
  {{- $upper := upper $key -}}
  {{- $_ := set $customIngressEnv $upper $val -}}
{{- end -}}

{{/*
      ====== MERGE AND RENDER ENV BLOCK ======
*/}}

{{- $completeEnv := mergeOverwrite $autoEnv $userEnv $customIngressEnv -}}
{{- template "kong.renderEnv" $completeEnv -}}

{{- end -}}

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
{{- if .Values.certificates.portal.enabled }}
- name: {{ include "kong.fullname" . }}-portal-cert
  secret:
    secretName: {{ include "kong.fullname" . }}-portal-cert
{{- end }}
{{- end }}
{{- end }}
{{- if (and (.Values.postgresql.enabled) .Values.waitImage.enabled) }}
- name: {{ template "kong.fullname" . }}-bash-wait-for-postgres
  configMap:
    name: {{ template "kong.fullname" . }}-bash-wait-for-postgres
    defaultMode: 0755
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
{{- if (and (not .Values.ingressController.enabled) (eq .Values.env.database "off")) }}
- name: kong-custom-dbless-config-volume
  configMap:
    {{- if .Values.dblessConfig.configMap }}
    name: {{ .Values.dblessConfig.configMap }}
    {{- else }}
    name: {{ template "kong.dblessConfig.fullname" . }}
    {{- end }}
{{- end }}
{{- if .Values.ingressController.admissionWebhook.enabled }}
- name: webhook-cert
  secret:
    {{- if .Values.ingressController.admissionWebhook.certificate.provided }}
    secretName: {{ .Values.ingressController.admissionWebhook.certificate.secretName }}
    {{- else }}
    secretName: {{ template "kong.fullname" . }}-validation-webhook-keypair
    {{- end }}
{{- end }}
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
{{- if .Values.certificates.portal.enabled }}
- name: {{ include "kong.fullname" . }}-portal-cert
  mountPath: /etc/cert-manager/portal/
{{- end }}
{{- end }}
{{- end }}
{{- if (and (not .Values.ingressController.enabled) (eq .Values.env.database "off")) }}
- name: kong-custom-dbless-config-volume
  mountPath: /kong_dbless/
{{- end }}
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
{{- $myList | join "," -}}
{{- end -}}

{{- define "kong.wait-for-db" -}}
- name: wait-for-db
  image: {{ include "kong.getRepoTag" .Values.image }}
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  securityContext:
  {{ toYaml .Values.containerSecurityContext | nindent 4 }}
  env:
  {{- include "kong.env" . | nindent 2 }}
{{/* TODO the prefix override is to work around https://github.com/Kong/charts/issues/295
     Note that we use args instead of command here to /not/ override the standard image entrypoint. */}}
  args: [ "/bin/bash", "-c", "export KONG_NGINX_DAEMON=on KONG_PREFIX=`mktemp -d` KONG_KEYRING_ENABLED=off; until kong start; do echo 'waiting for db'; sleep 1; done; kong stop"]
  volumeMounts:
  {{- include "kong.volumeMounts" . | nindent 4 }}
  {{- include "kong.userDefinedVolumeMounts" .Values.deployment | nindent 4 }}
  resources:
  {{- toYaml .Values.resources | nindent 4 }}
{{- end -}}

{{/* effectiveVersion takes an image dict from values.yaml. if .effectiveSemver is set, it returns that, else it returns .tag */}}
{{- define "kong.effectiveVersion" -}}
{{- if .effectiveSemver -}}
{{- .effectiveSemver -}}
{{- else -}}
{{- .tag -}}
{{- end -}}
{{- end -}}

{{- define "kong.controller-container" -}}
- name: ingress-controller
  securityContext:
{{ toYaml .Values.containerSecurityContext | nindent 4 }}
  args:
  {{ if .Values.ingressController.args}}
  {{- range $val := .Values.ingressController.args }}
  - {{ $val }}
  {{- end }}
  {{- end }}
  ports:
  {{- if .Values.ingressController.admissionWebhook.enabled }}
  - name: webhook
    containerPort: {{ .Values.ingressController.admissionWebhook.port }}
    protocol: TCP
  {{- end }}
  {{ if (semverCompare ">= 2.0.0" (include "kong.effectiveVersion" .Values.ingressController.image)) -}}
  - name: cmetrics
    containerPort: 10255
    protocol: TCP
  {{- end }}
  env:
  - name: POD_NAME
    valueFrom:
      fieldRef:
        apiVersion: v1
        fieldPath: metadata.name
  - name: POD_NAMESPACE
    valueFrom:
      fieldRef:
        apiVersion: v1
        fieldPath: metadata.namespace
{{- include "kong.ingressController.env" .  | indent 2 }}
  image: {{ include "kong.getRepoTag" .Values.ingressController.image }}
  imagePullPolicy: {{ .Values.image.pullPolicy }}
{{/* disableReadiness is a hidden setting to drop this block entirely for use with a debugger
     Helm value interpretation doesn't let you replace the default HTTP checks with any other
     check type, and all HTTP checks freeze when a debugger pauses operation.
     Setting disableReadiness to ANY value disables the probes.
*/}}
{{- if (not (hasKey .Values.ingressController "disableProbes")) }}
  readinessProbe:
{{ toYaml .Values.ingressController.readinessProbe | indent 4 }}
  livenessProbe:
{{ toYaml .Values.ingressController.livenessProbe | indent 4 }}
{{- end }}
  resources:
{{ toYaml .Values.ingressController.resources | indent 4 }}
  volumeMounts:
{{- if .Values.ingressController.admissionWebhook.enabled }}
  - name: webhook-cert
    mountPath: /admission-webhook
    readOnly: true
{{- end }}
{{- if (and (not .Values.deployment.serviceAccount.automountServiceAccountToken) (or .Values.deployment.serviceAccount.create .Values.deployment.serviceAccount.name)) }}
  - name: {{ template "kong.serviceAccountTokenName" . }}
    mountPath: /var/run/secrets/kubernetes.io/serviceaccount
    readOnly: true
{{- end }}
  {{- include "kong.userDefinedVolumeMounts" .Values.ingressController | nindent 2 }}
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

{{- if .Values.ingressController.enabled -}}
  {{- $_ := set $autoEnv "KONG_KIC" "on" -}}
{{- end -}}

{{- with .Values.admin -}}
  {{- $address := "0.0.0.0" -}}
  {{- if (not .enabled) -}}
    {{- $address = "127.0.0.1" -}}
  {{- end -}}
  {{- $listenConfig := dict -}}
  {{- $listenConfig := merge $listenConfig . -}}
  {{- $_ := set $listenConfig "address" $address -}}
  {{- $_ := set $autoEnv "KONG_ADMIN_LISTEN" (include "kong.listen" $listenConfig) -}}
{{- end -}}

{{- if and ( .Capabilities.APIVersions.Has "cert-manager.io/v1" ) .Values.certificates.enabled -}}
  {{- if (and .Values.certificates.cluster.enabled .Values.cluster.enabled) -}}
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
    {{- if .Values.enterprise.enabled }}
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

  {{- $_ := set $autoEnv "KONG_ADMIN_GUI_LISTEN" (include "kong.listen" .Values.manager) -}}
  {{- if .Values.manager.ingress.enabled }}
    {{- $_ := set $autoEnv "KONG_ADMIN_GUI_URL" (include "kong.ingress.serviceUrl" .Values.manager.ingress) -}}
  {{- end -}}

  {{- if not .Values.enterprise.vitals.enabled }}
    {{- $_ := set $autoEnv "KONG_VITALS" "off" -}}
  {{- end }}
  {{- $_ := set $autoEnv "KONG_CLUSTER_TELEMETRY_LISTEN" (include "kong.listen" .Values.clustertelemetry) -}}

  {{- if .Values.enterprise.portal.enabled }}
    {{- $_ := set $autoEnv "KONG_PORTAL" "on" -}}
      {{- $_ := set $autoEnv "KONG_PORTAL_GUI_LISTEN" (include "kong.listen" .Values.portal) -}}
    {{- $_ := set $autoEnv "KONG_PORTAL_API_LISTEN" (include "kong.listen" .Values.portalapi) -}}

    {{- if .Values.portal.ingress.enabled }}
      {{- $_ := set $autoEnv "KONG_PORTAL_GUI_HOST" .Values.portal.ingress.hostname -}}
      {{- if .Values.portal.ingress.tls }}
        {{- $_ := set $autoEnv "KONG_PORTAL_GUI_PROTOCOL" "https" -}}
      {{- else }}
        {{- $_ := set $autoEnv "KONG_PORTAL_GUI_PROTOCOL" "http" -}}
      {{- end }}
    {{- end }}

    {{- if .Values.portalapi.ingress.enabled }}
      {{- $_ := set $autoEnv "KONG_PORTAL_API_URL" (include "kong.ingress.serviceUrl" .Values.portalapi.ingress) -}}
    {{- end }}
  {{- end }}

  {{- if .Values.enterprise.rbac.enabled }}
    {{- $_ := set $autoEnv "KONG_ENFORCE_RBAC" "on" -}}
    {{- $_ := set $autoEnv "KONG_ADMIN_GUI_AUTH" .Values.enterprise.rbac.admin_gui_auth | default "basic-auth" -}}

    {{- if not (eq .Values.enterprise.rbac.admin_gui_auth "basic-auth") }}
      {{- $guiAuthConf := include "secretkeyref" (dict "name" .Values.enterprise.rbac.admin_gui_auth_conf_secret "key" "admin_gui_auth_conf") -}}
      {{- $_ := set $autoEnv "KONG_ADMIN_GUI_AUTH_CONF" $guiAuthConf -}}
    {{- end }}

    {{- $guiSessionConf := include "secretkeyref" (dict "name" .Values.enterprise.rbac.session_conf_secret "key" "admin_gui_session_conf") -}}
    {{- $_ := set $autoEnv "KONG_ADMIN_GUI_SESSION_CONF" $guiSessionConf -}}
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

{{- if .Values.postgresql.enabled }}
  {{- $_ := set $autoEnv "KONG_PG_HOST" (include "kong.postgresql.fullname" .) -}}
  {{- $_ := set $autoEnv "KONG_PG_PORT" .Values.postgresql.service.ports.postgresql -}}
  {{- $pgPassword := include "secretkeyref" (dict "name" (include "kong.postgresql.fullname" .) "key" "password") -}}

  {{- $_ := set $autoEnv "KONG_PG_PASSWORD" $pgPassword -}}
{{- else if eq .Values.env.database "postgres" }}
  {{- $_ := set $autoEnv "KONG_PG_PORT" "5432" }}
{{- end }}

{{- if (and (not .Values.ingressController.enabled) (eq .Values.env.database "off")) }}
  {{- $_ := set $autoEnv "KONG_DECLARATIVE_CONFIG" "/kong_dbless/kong.yml" -}}
{{- end }}

{{- $_ := set $autoEnv "KONG_PLUGINS" (include "kong.plugins" .) -}}

{{/*
    ====== USER-SET ENVIRONMENT VARIABLES ======
*/}}

{{- $userEnv := dict -}}
{{- range $key, $val := .Values.env }}
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

{{- define "kong.wait-for-postgres" -}}
- name: wait-for-postgres
{{- if (or .Values.waitImage.unifiedRepoTag .Values.waitImage.repository) }}
  image: {{ include "kong.getRepoTag" .Values.waitImage }}
{{- else }} {{/* default to the Kong image */}}
  image: {{ include "kong.getRepoTag" .Values.image }}
{{- end }}
  imagePullPolicy: {{ .Values.waitImage.pullPolicy }}
  env:
  {{- include "kong.no_daemon_env" . | nindent 2 }}
  command: [ "bash", "/wait_postgres/wait.sh" ]
  volumeMounts:
  - name: {{ template "kong.fullname" . }}-bash-wait-for-postgres
    mountPath: /wait_postgres
  resources:
  {{- toYaml .Values.migrations.resources | nindent 4 }}
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

{{/*
kong.kubernetesRBACRoles outputs a static list of RBAC rules (the "rules" block
of a Role or ClusterRole) that provide the ingress controller access to the
Kubernetes namespace-scoped resources it uses to build Kong configuration.

Collectively, these are built from:
kubectl kustomize github.com/kong/kubernetes-ingress-controller/config/rbac?ref=main
kubectl kustomize github.com/kong/kubernetes-ingress-controller/config/rbac/knative?ref=main
kubectl kustomize github.com/kong/kubernetes-ingress-controller/config/rbac/gateway?ref=main

However, there is no way to generate the split between cluster and namespaced
role sets used in the charts. Updating these requires separating out cluster
resource roles into their separate templates.
*/}}
{{- define "kong.kubernetesRBACRules" -}}
- apiGroups:
  - ""
  resources:
  - endpoints
  verbs:
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - endpoints/status
  verbs:
  - get
  - patch
  - update
- apiGroups:
  - ""
  resources:
  - events
  verbs:
  - create
  - patch
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - secrets/status
  verbs:
  - get
  - patch
  - update
- apiGroups:
  - ""
  resources:
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - services/status
  verbs:
  - get
  - patch
  - update
- apiGroups:
  - configuration.konghq.com
  resources:
  - ingressclassparameterses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - configuration.konghq.com
  resources:
  - kongconsumers
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - configuration.konghq.com
  resources:
  - kongconsumers/status
  verbs:
  - get
  - patch
  - update
- apiGroups:
  - configuration.konghq.com
  resources:
  - kongingresses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - configuration.konghq.com
  resources:
  - kongingresses/status
  verbs:
  - get
  - patch
  - update
- apiGroups:
  - configuration.konghq.com
  resources:
  - kongplugins
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - configuration.konghq.com
  resources:
  - kongplugins/status
  verbs:
  - get
  - patch
  - update
- apiGroups:
  - configuration.konghq.com
  resources:
  - tcpingresses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - configuration.konghq.com
  resources:
  - tcpingresses/status
  verbs:
  - get
  - patch
  - update
- apiGroups:
  - configuration.konghq.com
  resources:
  - udpingresses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - configuration.konghq.com
  resources:
  - udpingresses/status
  verbs:
  - get
  - patch
  - update
- apiGroups:
  - extensions
  resources:
  - ingresses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - ingresses/status
  verbs:
  - get
  - patch
  - update
{{- if (.Capabilities.APIVersions.Has "gateway.networking.k8s.io/v1alpha2") }}
- apiGroups:
  - gateway.networking.k8s.io
  resources:
  - gateways
  verbs:
  - get
  - list
  - update
  - watch
- apiGroups:
  - gateway.networking.k8s.io
  resources:
  - gateways/status
  verbs:
  - get
  - update
- apiGroups:
  - gateway.networking.k8s.io
  resources:
  - httproutes
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - gateway.networking.k8s.io
  resources:
  - httproutes/status
  verbs:
  - get
  - update
- apiGroups:
  - gateway.networking.k8s.io
  resources:
  - referencegrants
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - gateway.networking.k8s.io
  resources:
  - referencegrants/status
  verbs:
  - get
- apiGroups:
  - gateway.networking.k8s.io
  resources:
  - tcproutes
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - gateway.networking.k8s.io
  resources:
  - tcproutes/status
  verbs:
  - get
  - update
- apiGroups:
  - gateway.networking.k8s.io
  resources:
  - tlsroutes
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - gateway.networking.k8s.io
  resources:
  - tlsroutes/status
  verbs:
  - get
  - update
- apiGroups:
  - gateway.networking.k8s.io
  resources:
  - udproutes
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - gateway.networking.k8s.io
  resources:
  - udproutes/status
  verbs:
  - get
  - update
{{- end }}
{{- if (.Capabilities.APIVersions.Has "networking.internal.knative.dev/v1alpha1") }}
- apiGroups:
  - networking.internal.knative.dev
  resources:
  - ingresses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - networking.internal.knative.dev
  resources:
  - ingresses/status
  verbs:
  - get
  - patch
  - update
{{- end }}
- apiGroups:
  - networking.k8s.io
  resources:
  - ingresses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - networking.k8s.io
  resources:
  - ingresses/status
  verbs:
  - get
  - patch
  - update
{{- end -}}

{{/*
kong.kubernetesRBACClusterRoles outputs a static list of RBAC rules (the "rules" block
of a Role or ClusterRole) that provide the ingress controller access to the
Kubernetes Cluster-scoped resources it uses to build Kong configuration.
*/}}
{{- define "kong.kubernetesRBACClusterRules" -}}
- apiGroups:
  - configuration.konghq.com
  resources:
  - kongclusterplugins
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - configuration.konghq.com
  resources:
  - kongclusterplugins/status
  verbs:
  - get
  - patch
  - update
{{- if (.Capabilities.APIVersions.Has "gateway.networking.k8s.io/v1alpha2") }}
- apiGroups:
  - gateway.networking.k8s.io
  resources:
  - gatewayclasses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - gateway.networking.k8s.io
  resources:
  - gatewayclasses/status
  verbs:
  - get
  - update
{{- end }}
- apiGroups:
  - networking.k8s.io
  resources:
  - ingressclasses
  verbs:
  - get
  - list
  - watch
{{- end -}}

{{- define "kong.ingressVersion" -}}
{{- if (.Capabilities.APIVersions.Has "networking.k8s.io/v1/Ingress") -}}
networking.k8s.io/v1
{{- else if (.Capabilities.APIVersions.Has "networking.k8s.io/v1beta1/Ingress") -}}
networking.k8s.io/v1beta1
{{- else -}}
extensions/v1beta1
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
