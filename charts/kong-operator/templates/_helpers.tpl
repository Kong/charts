{{/* vim: set filetype=mustache: */}}
{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}

{{- define "kong.namespace" -}}
{{- default .Release.Namespace .Values.namespace -}}
{{- end -}}

{{- define "kong.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kong.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- default (printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-") .Values.fullnameOverride -}}
{{- end -}}

# kong.webhookServiceName is used in different subcharts and name has to match
# hence only variadic part of this name is .Release.Name.
{{- define "kong.webhookServiceName" -}}
{{- default (printf "%s-kong-operator-webhook" .Release.Name | trunc 63 | trimSuffix "-") -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "kong.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "kong.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "kong.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kong.renderTpl" -}}
    {{- if typeIs "string" .value }}
{{- tpl .value .context }}
    {{- else }}
{{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}

{{- define "kong.metaLabels" -}}
app.kubernetes.io/name: {{ template "kong.name" . }}
helm.sh/chart: {{ template "kong.chart" . }}
app.kubernetes.io/instance: "{{ .Release.Name }}"
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- range $key, $value := .Values.extraLabels }}
{{ $key }}: {{ include "kong.renderTpl" (dict "value" $value "context" $) | quote }}
{{- end }}
{{- end -}}

{{- define "kong.selectorLabels" -}}
app.kubernetes.io/name: {{ template "kong.name" . }}
app.kubernetes.io/component: ko
app.kubernetes.io/instance: "{{ .Release.Name }}"
{{- end -}}

{{/*
Create a list of env vars based on the values of the `env` and `customEnv` maps.
*/}}
{{- define "kong.env" -}}

{{- $defaultEnv := dict -}}
{{- if not .Values.global.conversionWebhook.enabled }}
{{- $_ := set $defaultEnv "KONG_OPERATOR_ENABLE_CONVERSION_WEBHOOK" "false" -}}
{{- end }}
{{- $_ := set $defaultEnv "KONG_OPERATOR_HEALTH_PROBE_BIND_ADDRESS" ":8081" -}}
{{- $_ := set $defaultEnv "KONG_OPERATOR_METRICS_BIND_ADDRESS" "0.0.0.0:8080" -}}

{{/*
List of envs that are configured by other variables.
The template fails if you try to configure the envs controlled by other variables.
The dict maps raw env variable key to the suggested variable path.
*/}}
{{- $envsSetByVars := dict -}}
{{- $_ := set $envsSetByVars "KONG_OPERATOR_ENABLE_CONTROLPLANE_CONFIG_DUMP" "Values.enableControlplaneConfigDump" -}}
{{- $_ := set $envsSetByVars "KONG_OPERATOR_CONTROLPLANE_CONFIG_DUMP_BIND_ADDRESS" "Values.controlplaneConfigDumpPort" -}}

{{- if .Values.enableControlplaneConfigDump -}}
{{- $_ := set $defaultEnv "KONG_OPERATOR_ENABLE_CONTROLPLANE_CONFIG_DUMP" "true" -}}
{{- $_ := set $defaultEnv "KONG_OPERATOR_CONTROLPLANE_CONFIG_DUMP_BIND_ADDRESS" (print ":" .Values.controlplaneConfigDumpPort) -}}
{{- end -}}

{{- range $key, $val := .Values.env -}}
  {{- $var := printf "KONG_OPERATOR_%s" ( upper $key ) -}}
  {{- if hasKey $envsSetByVars $var -}}
  {{- fail (printf "Do not configure %s in Values.env. Use %s instead." $key (get $envsSetByVars $var)) -}}
  {{- end -}}
  {{- if hasKey $defaultEnv $var -}}
  {{- $defaultEnv = unset $defaultEnv $var -}}
  {{- end }}
- name: {{ $var }}
  value: {{ $val | quote }}
{{- end -}}

{{ range $key, $val := .Values.customEnv }}
  {{- $var := upper $key -}}
  {{- if hasKey $envsSetByVars $var -}}
  {{- fail (printf "Do not configure %s in Values.customEnv. Use %s instead." $key (get $envsSetByVars $var)) -}}
  {{- end -}}
  {{- if hasKey $defaultEnv $var -}}
  {{- $defaultEnv = unset $defaultEnv $var -}}
  {{- end }}
- name: {{ $var }}
  value: {{ $val | quote }}
{{- end -}}

{{ range $key, $val := $defaultEnv }}
- name: {{ $key }}
  value: {{ $val | quote }}
{{- end -}}

{{- end -}}

{{- define "kong.volumes" -}}
{{ if .Values.global.conversionWebhook.enabled }}
- name: {{ template "kong.fullname" . }}-webhook-certs
  secret:
    defaultMode: 420
    secretName: {{ template "kong.webhookServiceName" . }}-server-cert
{{ end }}
- name: {{ template "kong.fullname" . }}-pod-labels
  downwardAPI:
    items:
    - path: labels
      fieldRef:
        fieldPath: metadata.labels
{{- end }}

{{- define "kong.volumeMounts" -}}
{{ if .Values.global.conversionWebhook.enabled }}
- name: {{ template "kong.fullname" . }}-webhook-certs
  mountPath: /tmp/k8s-webhook-server/serving-certs
{{ end }}
- name: {{ template "kong.fullname" . }}-pod-labels
  mountPath: /etc/podinfo
{{- end }}

{{/* effectiveVersion takes the image dict from values.yaml. */}}
{{/* if .effectiveSemver is set, it returns that, else it returns .tag */}}
{{- define "kong.effectiveVersion" -}}
{{- $effectiveSemver := .Values.image.effectiveSemver -}}
{{- if $effectiveSemver -}}
  {{- if regexMatch "^[0-9]+.[0-9]+(\\.[0-9]+)?" $effectiveSemver -}}
  {{- regexFind "^[0-9]+.[0-9]+(\\.[0-9]+)?" $effectiveSemver -}}
  {{- else -}}
  {{- $effectiveSemver -}}
  {{- end -}}
{{- else -}}
  {{- $tag := (trimSuffix "-redhat" .Values.image.tag) -}}
  {{- if regexMatch "^[0-9]+.[0-9]+(\\.[0-9]+)?" $tag -}}
  {{- regexFind "^[0-9]+.[0-9]+(\\.[0-9]+)?" $tag -}}
  {{- else -}}
  {{- .Chart.AppVersion -}}
  {{- end -}}
{{- end -}}
{{- end -}}
