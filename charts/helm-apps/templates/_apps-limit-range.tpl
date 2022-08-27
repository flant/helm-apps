{{- define "apps-limit-range" }}
  {{- $ := index . 0 }}
  {{- $RelatedScope := index . 1 }}
    {{- if not (kindIs "invalid" $RelatedScope) }}
  {{- $_ := set $RelatedScope "__GroupVars__" (dict "type" "apps-limit-range" "name" "apps-limit-range") }}
  {{- include "apps-utils.renderApps" (list $ $RelatedScope) }}
{{- end -}}
{{- end -}}

{{- define "apps-limit-range.render" }}
{{- $ := . }}
{{- with $.CurrentApp }}
apiVersion: v1
kind: LimitRange
{{- include "apps-helpers.metadataGenerator" (list $ .) }}
spec:
  limits: {{- include "fl.value" (list $ . .limits) | nindent 4 }}
{{- end }}
{{- end }}
