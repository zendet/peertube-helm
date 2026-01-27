{{- define "peertube.runner.name" -}}
{{ template "peertube.name" . }}-runner
{{- end -}}

{{- define "peertube.runner.configMapName" -}}
{{- $root := .root -}}
{{- $g := .group -}}

{{- if $g.config.createConfigMap -}}
{{- printf "%s-%s-config" (include "peertube.runner.name" $root) $g.id | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- required "`runnerGroups[].config.configMapName` is required when `createConfigMap: false`" $g.config.configMapName -}}
{{- end -}}
{{- end -}}

{{- define "peertube.runner.labels" -}}
{{- template "peertube.labels.merge" (list
  (include "peertube.labels.common" .)
  (include "peertube.runner.matchLabels" .)
) -}}
{{- end -}}

{{- define "peertube.runner.matchLabels" -}}
{{- template "peertube.labels.merge" (list
  (include "peertube.matchLabels.common" .)
  (include "peertube.labels.component" "runner")
) -}}
{{- end -}}

{{- define "peertube.runner.configData" -}}
{{- $root := .root -}}
{{- $g := .group -}}

{{- $config := (fromYaml (tpl (default "" $g.config.raw) $root)) | default (dict) -}}
{{- $base := omit $config "registeredInstances" -}}

config.toml: |
{{- toToml $base | nindent 2 }}
{{- end -}}

{{- define "peertube.runner.serviceAccountName" -}}
{{- if .Values.runner.serviceAccount.create -}}
    {{ default (include "peertube.runner.name" .) .Values.runner.serviceAccount.name }}
{{- else -}}
    {{- default "default" .Values.runner.serviceAccount.name -}}
{{- end -}}
{{- end -}}