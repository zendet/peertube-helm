{{- define "peertube.labels.merge" -}}
{{- $labels := dict -}}
{{- range . -}}
  {{- $labels = merge $labels (fromYaml .) -}}
{{- end -}}
{{- with $labels -}}
  {{- toYaml $labels -}}
{{- end -}}
{{- end -}}

{{- define "peertube.labels.helm" -}}
helm.sh/chart: {{ template "peertube.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "peertube.labels.version" -}}
app.kubernetes.io/version: {{ template "peertube.chartVersion" . }}
{{- end -}}

{{- define "peertube.matchLabels.common" -}}
app.kubernetes.io/part-of: {{ template "peertube.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "peertube.labels.common" -}}
{{- template "peertube.labels.merge" (list
  (include "peertube.labels.helm" .)
  (include "peertube.labels.version" .)
) -}}
{{- end -}}

{{- define "peertube.labels.component" -}}
app.kubernetes.io/component: {{ . }}
{{- end -}}