{{- define "peertube.image" -}}
{{- $tag := default .defaultTag .image.tag -}}
{{- if not (typeIs "string" $tag) -}}
  {{- fail "`image.tag` must be a string" -}}
{{- end -}}

{{- $registry := default .globalRegistry .image.registry -}}
{{- $repo := required "image.repository is required" .image.repository -}}

{{- if $registry -}}
  {{- printf "%s/%s:%s" $registry $repo $tag -}}
{{- else -}}
  {{- printf "%s:%s" $repo $tag -}}
{{- end -}}
{{- end -}}
