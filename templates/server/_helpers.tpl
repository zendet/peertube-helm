{{- define "peertube.server.name" -}}
{{ template "peertube.name" . }}-server
{{- end -}}

{{- define "peertube.server.configMapName" -}}
{{- if .Values.server.config.createConfigMap -}}
    {{ default (printf "%s-config" (include "peertube.server.name" .)) .Values.server.config.configMapName }}
{{- else -}}
    {{ required "A configmap name is required when `server.config.createConfigMap` is set to `false`" .Values.server.config.configMapName }}
{{- end -}}
{{- end -}}

{{- define "peertube.grafana.metrics.configMapName" -}}
{{- if .Values.server.grafana.dashboards.metrics.createConfigMap -}}
    {{ tpl (default (printf "%s-grafana-metrics" (include "peertube.fullname" .)) .Values.server.grafana.dashboards.metrics.configMapName) . }}
{{- else -}}
    {{ required "A configmap name is required when `server.grafana.dashboards.metrics.configMapName` is set to `false`" .Values.server.grafana.dashboards.metrics.configMapName }}
{{- end -}}
{{- end -}}

{{- define "peertube.server.serviceAccountName" -}}
{{- if .Values.server.serviceAccount.create -}}
    {{ default (include "peertube.server.name" .) .Values.server.serviceAccount.name }}
{{- else -}}
    {{- default "default" .Values.server.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "peertube.server.labels" -}}
{{- template "peertube.labels.merge" (list
  (include "peertube.labels.common" .)
  (include "peertube.server.matchLabels" .)
) -}}
{{- end -}}

{{- define "peertube.server.matchLabels" -}}
{{- template "peertube.labels.merge" (list
  (include "peertube.matchLabels.common" .)
  (include "peertube.labels.component" "server")
) -}}
{{- end -}}

{{/*
Generate configmap data
*/}}
{{- define "peertube.server.configData" -}}
{{- $config := (fromYaml (tpl (default "" .Values.server.config.raw) .)) | default (dict) -}}


{{- $base := omit $config "database" "redis" "object_storage" "secrets" -}}

production.yaml: |
{{- if $base }}
{{- tpl (toYaml $base) . | nindent 2 }}
{{- end }}

  database:
    hostname: {{ .Values.server.externalPostgres.hostname | quote }}
    port: {{ .Values.server.externalPostgres.port }}
    ssl: {{ .Values.server.externalPostgres.ssl | default false }}
    suffix: {{ .Values.server.externalPostgres.suffix | default "" | quote }}
    name: {{ .Values.server.externalPostgres.db | default "peertube" | quote }}
    username: $(PEERTUBE_DB_USERNAME)
    pool:
      max: {{ .Values.server.externalPostgres.pool.max | default 5 }}

  redis:
    hostname: {{ .Values.server.externalRedis.hostname | quote }}
    port: {{ .Values.server.externalRedis.port }}
    db: {{ .Values.server.externalRedis.db | default 0 }}
    auth: $(PEERTUBE_REDIS_AUTH)
    sentinel:
      enabled: {{ .Values.server.externalRedis.sentinel.enabled | default false }}
      enable_tls: {{ .Values.server.externalRedis.sentinel.enableTls | default false }}
      {{- if .Values.server.externalRedis.sentinel.enabled }}
      master_name: {{ .Values.server.externalRedis.sentinel.masterName | quote }}
      hostname: {{ .Values.server.externalRedis.sentinel.hostname | quote }}
      port: {{ .Values.server.externalRedis.sentinel.port | default 26379 }}
      {{- end }}
      
{{- if .Values.server.objectStorage.enabled }}
  object_storage:
    force_path_style: true
{{- include "peertube.server.objectStorageConfigData" . | nindent 4 }}
{{- end }}
{{- end }}

{{- define "peertube.server.objectStorageConfigData" -}}
{{- $_ := required "server.objectStorage.existingSecret is required when `server.objectStorage.enabled` is set to `true`" .Values.server.objectStorage.existingSecret -}}

{{- $config := default (dict) .Values.server.objectStorage.config -}}

{{- $base := omit $config "enabled" "credentials" -}}

{{- toYaml (merge 
  (dict
    "enabled" true
    "credentials" (dict
      "access_key_id" "$(PEERTUBE_OBJECT_STORAGE_CREDENTIALS_ACCESS_KEY_ID)"
      "secret_access_key" "$(PEERTUBE_OBJECT_STORAGE_CREDENTIALS_SECRET_ACCESS_KEY)"
    )
 )
  $base
) -}}
{{- end -}}

{{- define "peertube.server.admin.passwordSecretRef" -}}
name: {{ default (printf "%s-admin" (include "peertube.server.name" .)) .Values.server.config.admin.existingSecret | quote }}
key: admin-password
optional: {{ ternary false true (or
  (not (empty .Values.server.config.admin.existingSecret))
  (not (empty .Values.server.config.admin.password))
) }}
{{- end }}

{{- define "peertube.server.redis.passwordSecretRef" -}}
name: {{ default (printf "%s-redis" (include "peertube.server.name" .)) .Values.server.externalRedis.existingSecret | quote }}
key: redis-password
optional: {{ ternary false true (or
  (not (empty .Values.server.externalRedis.existingSecret))
  (not (empty .Values.server.externalRedis.password))
) }}
{{- end -}}

{{- define "peertube.server.postgres.usernameSecretRef" -}}
name: {{ default (printf "%s-postgres" (include "peertube.server.name" .)) .Values.server.externalPostgres.existingSecret | quote }}
key: postgres-username
optional: false
{{- end -}}

{{- define "peertube.server.postgres.passwordSecretRef" -}}
name: {{ default (printf "%s-postgres" (include "peertube.server.name" .)) .Values.server.externalPostgres.existingSecret | quote }}
key: postgres-password
optional: {{ ternary false true (or
  (not (empty .Values.server.externalPostgres.existingSecret))
  (not (empty .Values.server.externalPostgres.password))
) }}
{{- end -}}

{{- define "peertube.server.peertubeSecretRef" -}}
name: {{ default (printf "%s-peertube-secret" (include "peertube.server.name" .)) .Values.server.config.secrets.existingSecret | quote }}
key: peertube-secret
optional: {{ ternary false true (or
  (not (empty .Values.server.config.secrets.existingSecret))
  (not (empty .Values.server.config.secrets.peertube))
) }}
{{- end }}