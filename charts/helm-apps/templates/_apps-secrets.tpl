{{- define "apps-secrets" }}
  {{- $ := index . 0 }}
  {{- $RelatedScope := index . 1 }}
    {{- if not (kindIs "invalid" $RelatedScope) }}
  {{- $_ := set $RelatedScope "__GroupVars__" (dict "type" "apps-secrets" "name" "apps-secrets") }}
  {{- include "apps-utils.renderApps" (list $ $RelatedScope) }}
{{- end -}}
{{- end -}}

{{- define "apps-secrets.render" }}
{{- $ := . }}
{{- $_ := set $ "CurrentSecret" $.CurrentApp }}
{{- with $.CurrentApp }}
apiVersion: v1
kind: Secret
{{- include "apps-helpers.metadataGenerator" (list $ .) }}
type: {{- include "fl.value" (list $ . .type) | default "Opaque" | nindent 2 }}
data:
{{- if (include "fl.value" (list $ . .data)) }}
{{- include "fl.value" (list $ . .data) | nindent 2}}
{{- else }}
{{- include "fl.generateSecretEnvVars" (list $ . .envVars) | nindent 2 }}
{{- include "fl.generateSecretData" (list $ . .data) | nindent 2 }}
{{- end }}

{{- end }}
{{- end }}
