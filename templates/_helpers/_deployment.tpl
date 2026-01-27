{{- define "peertube.deployment.replicas" -}}
  {{- if and (not (kindIs "invalid" .)) (not (kindIs "string" .)) -}}
  {{- if eq (int .) 0 -}}
    {{- fail "Peertube server does not support running with 0 replicas. Please provide a non-zero integer value." -}}
  {{- end -}}
  {{- end -}}
  {{- . -}}
{{- end -}}