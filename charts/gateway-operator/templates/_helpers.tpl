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

{{- define "kong.env" -}}

{{- $userEnv := dict -}}
{{- range $key, $val := .Values.env }}
  {{- $upper := upper $key -}}
  {{- $var := printf "GATEWAY_OPERATOR_%s" $upper -}}
  {{- $_ := set $userEnv $var $val -}}
{{- end -}}
{{- range $key, $val := $userEnv }}
- name: {{ $key }}
  value: {{ $val | quote }}
{{- end -}}

{{- $customEnv := dict -}}
{{- range $key, $val := .Values.customEnv }}
  {{- $upper := upper $key -}}
  {{- $_ := set $customEnv $upper $val -}}
{{- end -}}
{{- range $key, $val := $customEnv }}
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
