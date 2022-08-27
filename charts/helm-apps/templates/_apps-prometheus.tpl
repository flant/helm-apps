{{- define "apps-custom-prometheus-rules" }}
  {{- $ := index . 0 }}
  {{- $RelatedScope := index . 1 }}
    {{- if not (kindIs "invalid" $RelatedScope) }}
  {{- $_ := set $RelatedScope "__GroupVars__" (dict "type" "apps-custom-prometheus-rules" "name" "apps-custom-prometheus-rules") }}
  {{- include "apps-utils.renderApps" (list $ $RelatedScope) }}
{{- end -}}
{{- end -}}

{{- define "apps-custom-prometheus-rules.render" }}
{{- $ := . }}
{{- with $.CurrentApp }}
apiVersion: deckhouse.io/v1
kind: CustomPrometheusRules
metadata:
  labels:
    component: rules
    prometheus: main
  name: {{ include "fl.value" (list $ . .name)}}
spec:
  groups:
    {{- range $_groupName, $_group := .groups }}
    - name: {{ include "fl.value" (list $ . $_groupName)}}
      rules:
        {{- range $_alertName, $alert := .alerts}}
        - alert: {{ include "fl.value" (list $ . $_alertName)}}
          {{- if  include "fl.isTrue" (list $ . .isTemplate) }}
          {{- include "fl.value" (list $ . .content) | nindent 10 }}
          {{- else }}
          {{- .content | nindent 10 }}
          {{- end }}
        {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "apps-grafana-dashboards" }}
  {{- $ := index . 0 }}
  {{- $RelatedScope := index . 1 }}
    {{- if not (kindIs "invalid" $RelatedScope) }}
  {{- $_ := set $RelatedScope "__GroupVars__" (dict "type" "apps-grafana-dashboards" "name" "apps-grafana-dashboards") }}
  {{- include "apps-utils.renderApps" (list $ $RelatedScope) }}
{{- end -}}
{{- end -}}

{{- define "apps-grafana-dashboards.render" }}
{{- $ := .  }}
{{- with $.CurrentApp }}
apiVersion: deckhouse.io/v1alpha1
kind: GrafanaDashboardDefinition
{{- include "apps-helpers.metadataGenerator" (list $ .) }}
spec:
  folder: {{ include "fl.value" (list $ . .folder) | default "Custom" }}
  definition: |
    {{ $.Files.Get (printf "dashboards/%s.json" .name) | nindent 4 }}
{{- end }}
{{- end }}
