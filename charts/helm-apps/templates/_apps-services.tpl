{{- define "apps-services" }}
  {{- $ := index . 0 }}
  {{- $RelatedScope := index . 1 }}
    {{- if not (kindIs "invalid" $RelatedScope) }}
  {{- $_ := set $RelatedScope "__GroupVars__" (dict "type" "apps-services" "name" "apps-services") }}
  {{- include "apps-utils.renderApps" (list $ $RelatedScope) }}
{{- end -}}
{{- end -}}

{{- define "apps-services.render" }}
{{- $ := . }}
{{- with $.CurrentApp }}
{{- include "apps-components._service" (list $ .) }}
{{- end }}
{{- end }}
