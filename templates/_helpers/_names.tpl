{{- define "peertube.name" -}}
{{- default .Chart.Name .Values.global.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "peertube.fullname" -}}
{{- if .Values.global.fullnameOverride -}}
  {{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
  {{- $name := default .Chart.Name .Values.global.nameOverride -}}
  {{- if contains $name .Release.Name -}}
    {{- .Release.Name | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "peertube.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "peertube.namespace" -}}
{{ default .Release.Namespace .Values.global.namespaceOverride }}
{{- end -}}
