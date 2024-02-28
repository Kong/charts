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
