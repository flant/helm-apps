{{- define "apps-certificates" }}
  {{- $ := index . 0 }}
  {{- $RelatedScope := index . 1 }}
    {{- if not (kindIs "invalid" $RelatedScope) }}
  {{- $_ := set $RelatedScope "__GroupVars__" (dict "type" "apps-certificates" "name" "apps-certificates") }}
  {{- include "apps-utils.renderApps" (list $ $RelatedScope) }}
{{- end -}}
{{- end -}}

{{- define "apps-certificates.render" }}
{{- $ := . }}
{{- with $.CurrentApp }}
{{ include "apps-components.cerificate" (list $ .) }}
{{- end }}
{{- end }}
