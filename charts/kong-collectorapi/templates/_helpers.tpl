{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "kong-collectorapi.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kong-collectorapi.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "kong-collectorapi.postgresql.fullname" -}}
{{- $name := default "postgresql" .Values.postgresql.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kong-collectorapi.redis.fullname" -}}
{{- $name := default "redis" .Values.redis.nameOverride -}}
{{- printf "%s-%s-master" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kong-collectorapi.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kong-collectorapi.metaLabels" -}}
apps.kubernetes.io/app: {{ template "kong-collectorapi.name" . }}
helm.sh/chart: {{ template "kong-collectorapi.chart" . }}
app.kubernetes.io/instance: "{{ .Release.Name }}"
app.kubernetes.io/managed-by: "{{ .Release.Service }}"
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "kong-collectorapi.labels" -}}
helm.sh/chart: {{ include "kong-collectorapi.chart" . }}
{{ include "kong-collectorapi.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "kong-collectorapi.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kong-collectorapi.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "kong-collectorapi.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "kong-collectorapi.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "kong-collectorapi.wait-for-db" -}}
- name: wait-for-db
  image: "{{ .Values.waitImage.repository }}:{{ .Values.waitImage.tag }}"
  imagePullPolicy: {{ .Values.waitImage.pullPolicy }}
  env:
  - name: COLLECTOR_PG_HOST
    value: {{ template "kong-collectorapi.postgresql.fullname" . }}
  - name: COLLECTOR_PG_PORT
    value: "{{ .Values.postgresql.service.port }}"
  command: [ "/bin/sh", "-c", "until nc -zv $COLLECTOR_PG_HOST $COLLECTOR_PG_PORT -w1; do echo 'waiting for db'; sleep 1; done" ]
{{- end -}}

{{- define "kong-collectorapi.wait-for-kong" -}}
- name: wait-for-kong
  image: "{{ .Values.waitImage.repository }}:{{ .Values.waitImage.tag }}"
  imagePullPolicy: {{ .Values.waitImage.pullPolicy }}
  env:
  - name: KONG_ADMIN_HOST
    value: "{{ .Values.kongAdminHost }}"
  command: [ "/bin/sh", "-c", "until nslookup $KONG_ADMIN_HOST; do echo waiting for $KONG_ADMIN_HOST; sleep 2; done;" ]
{{- end -}}
