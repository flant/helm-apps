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
data:
{{- include "apps.generateConfigMapEnvVars" (list $ . .envVars "envVars") | nindent 2 }}
{{- include "fl.value" (list $ . .data) | nindent 2 }}
{{- end }}
{{- end }}
