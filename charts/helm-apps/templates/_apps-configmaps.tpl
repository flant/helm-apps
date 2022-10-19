{{- define "apps-configmaps" }}
  {{- $ := index . 0 }}
  {{- $RelatedScope := index . 1 }}
    {{- if not (kindIs "invalid" $RelatedScope) }}
  {{- $_ := set $RelatedScope "__GroupVars__" (dict "type" "apps-configmaps" "name" "apps-configmaps") }}
  {{- include "apps-utils.renderApps" (list $ $RelatedScope) }}
    {{- end -}}
{{- end -}}

{{- define "apps-configmaps.render" }}
{{- $ := . }}
{{- $_ := set $ "CurrentConfigMap" $.CurrentApp }}
{{- with $.CurrentApp }}
apiVersion: v1
kind: ConfigMap
{{- include "apps-helpers.metadataGenerator" (list $ .) }}
{{- $data :=  "" }}
{{- with include "apps.generateConfigMapEnvVars" (list $ . .envVars "envVars") }}
{{- $data = printf "%s\n%s" $data . | trim }}
{{- end }}
{{- with include "fl.value" (list $ . .data) }}
{{- $data = printf "%s\n%s" $data . | trim }}
{{- end }}
{{ with $data }}
data:
{{- . | nindent 2 }}
{{- end }}
{{ with include "fl.value" (list $ . .binaryData) }}
binaryData:
{{- . | nindent 2 }}
{{- end }}
{{- end }}
{{- end }}
