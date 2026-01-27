{{- define "peertube.chartVersion" -}}
  {{- .Chart.Version | replace "+" "_" -}}
{{- end -}}

{{/* Helper function to sort imagePullSecrets by name to ensure consistent ordering */}}
{{- define "peertube.sortedImagePullSecrets" -}}
{{- if . -}}
{{- $secrets := list -}}
{{- range . -}}
{{- $secrets = append $secrets .name -}}
{{- end -}}
{{- $sortedSecrets := list -}}
{{- if $secrets -}}
{{- $sortedSecrets = sortAlpha $secrets -}}
{{- end -}}
{{- $sortedRefs := list -}}
{{- range $sortedSecrets -}}
{{- $sortedRefs = append $sortedRefs (dict "name" .) -}}
{{- end -}}
{{- toYaml $sortedRefs -}}
{{- end -}}
{{- end -}}