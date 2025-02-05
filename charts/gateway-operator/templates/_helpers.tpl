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
app.kubernetes.io/component: kgo
app.kubernetes.io/instance: "{{ .Release.Name }}"
{{- end -}}

{{/*
Create a list of env vars based on the values of the `env` and `customEnv` maps.
*/}}
{{- define "kong.env" -}}

{{- $defaultEnv := dict -}}
{{- $_ := set $defaultEnv "GATEWAY_OPERATOR_HEALTH_PROBE_BIND_ADDRESS" ":8081" -}}
{{- $_ := set $defaultEnv "GATEWAY_OPERATOR_METRICS_BIND_ADDRESS" "0.0.0.0:8080" -}}

{{- range $key, $val := .Values.env -}}
  {{- $var := printf "GATEWAY_OPERATOR_%s" ( upper $key ) -}}
  {{- if hasKey $defaultEnv $var -}}
  {{- $defaultEnv = unset $defaultEnv $var -}}
  {{- end }}
- name: {{ $var }}
  value: {{ $val | quote }}
{{- end -}}

{{ range $key, $val := .Values.customEnv }}
  {{- $var := upper $key -}}
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
- name: {{ template "kong.fullname" . }}-certs-dir
  emptyDir:
    sizeLimit: {{ .Values.certsDir.sizeLimit }}
{{- end }}

{{- define "kong.volumeMounts" -}}
- name: {{ template "kong.fullname" . }}-certs-dir
  mountPath: /tmp/k8s-webhook-server/serving-certs
{{- end }}

{{/* effectiveVersion takes the image dict from values.yaml. */}}
{{/* if .effectiveSemver is set, it returns that, else it returns .tag */}}
{{- define "kong.effectiveVersion" -}}
{{- $effectiveSemver := .Values.image.effectiveSemver -}}
{{- if $effectiveSemver -}}
  {{- if regexMatch "^[0-9]+.[0-9]+.[0-9]+" $effectiveSemver -}}
  {{- regexFind "^[0-9]+.[0-9]+.[0-9]+" $effectiveSemver -}}
  {{- else -}}
  {{- $effectiveSemver -}}
  {{- end -}}
{{- else -}}
  {{- $tag := (trimSuffix "-redhat" .Values.image.tag) -}}
  {{- if regexMatch "^[0-9]+.[0-9]+.[0-9]+" $tag -}}
  {{- regexFind "^[0-9]+.[0-9]+.[0-9]+" $tag -}}
  {{- else -}}
  {{- .Chart.AppVersion -}}
  {{- end -}}
{{- end -}}
{{- end -}}
