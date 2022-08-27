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
  query: {{ include "fl.value" (list $ . .query) }}
{{- end }}
{{- end }}
{{- end }}
