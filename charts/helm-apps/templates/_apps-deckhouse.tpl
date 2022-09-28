{{- define "apps-deckhouse.metrics" }}
{{- $ := . }}
{{- range $metricName, $metric := $.CurrentApp.deckhouseMetrics }}
{{- if include "fl.isTrue" (list $ . .enabled) }}
---
apiVersion: deckhouse.io/v1beta1
kind: {{ .kind }}
{{- if not (hasKey . "name")}}
{{- $_ := set . "name" (printf "%s-%s" $.CurrentApp.name (lower $metricName)) }}
{{- end }}
{{- include "apps-helpers.metadataGenerator" (list $ .)}}
spec:
  query: {{ include "fl.valueQuoted" (list $ . .query) }}
{{- end }}
{{- end }}
{{- end }}

{{- define "apps-deckhouse-metrics" }}
  {{- $ := index . 0 }}
  {{- $RelatedScope := index . 1 }}
    {{- if not (kindIs "invalid" $RelatedScope) }}

  {{- $_ := set $RelatedScope "__GroupVars__" (dict "type" "apps-deckhouse-metrics" "name" "apps-deckhouse-metrics") }}
  {{- include "apps-utils.renderApps" (list $ $RelatedScope) }}
{{- end -}}
{{- end -}}

{{- define "apps-deckhouse-metrics.render" }}
{{- $ := . }}
{{- with $.CurrentApp }}
apiVersion: deckhouse.io/v1beta1
kind: {{ include "fl.valueQuoted" (list $ . .kind) }}
{{- include "apps-helpers.metadataGenerator" (list $ .)}}
spec:
  query: {{ include "fl.valueQuoted" (list $ . .query) }}
{{- end }}
{{- end }}