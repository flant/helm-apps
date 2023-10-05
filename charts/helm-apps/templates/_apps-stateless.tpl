{{- define "apps-stateless" }}
  {{- $ := index . 0 }}
  {{- $RelatedScope := index . 1 }}
    {{- if not (kindIs "invalid" $RelatedScope) }}
  {{- $_ := set $RelatedScope "__GroupVars__" (dict "type" "apps-stateless" "name" "apps-stateless") }}
  {{- include "apps-utils.renderApps" (list $ $RelatedScope) }}
{{- end -}}
{{- end -}}

{{- define "apps-stateless.render" }}
{{- $ := . }}
{{- with $.CurrentApp }}
{{- if kindIs "invalid" .containers }}
{{- fail (printf "Установлено значение enabled для не настроенного '%s' в %s приложения!" $.CurrentApp.name "apps-stateless") }}
{{- end }}
{{/* Defaults values */}}
{{- if .service }}
{{- if include "fl.isTrue" (list $ . .service.enabled) }}
{{- if not .service.name }}
{{- $_ := set .service "name" .name }}
{{- end }}
{{- end }}
{{- end }}
{{/* Defaults values end */}}
{{- $serviceAccount := include "apps-system.serviceAccount" $ }}
apiVersion: apps/v1
kind: Deployment
{{ $_ := set . "__annotations__" dict }}
{{- if .reloader }}
{{- $_ := set .__annotations__ "pod-reloader.deckhouse.io/auto" "true" }}
{{- else }}
{{- $_ := set . "__annotations__" (include "apps-components.generate-config-checksum" (list $ .) | fromYaml) }}
{{-  end }}
{{- include "apps-helpers.metadataGenerator" (list $ .) }}
spec:
  {{- $specs := dict }}
  {{- $_ = set $specs "Numbers" (list "minReadySeconds" "progressDeadlineSeconds" "revisionHistoryLimit" "replicas") }}
  {{- $_ = set $specs "Maps" (list "securityContext" "strategy" "apps-helpers.podTemplate" "apps-specs.selector") }}
  {{- include "apps-utils.generateSpecs" (list $ . $specs) | indent 2 }}

{{- $_ = unset . "__annotations__" }}
{{- include "apps-components.generateConfigMapsAndSecrets" $ -}}

{{- include "apps-components.service" (list $ . .service) -}}

{{- include "apps-components.podDisruptionBudget" (list $ . .podDisruptionBudget) -}}

{{- include "apps-components.verticalPodAutoscaler" (list $ . .verticalPodAutoscaler "Deployment") }}

{{- include "apps-components.horizontalPodAutoscaler" (list $ . "Deployment") -}}

{{- include "apps-deckhouse.metrics" $ -}}

{{ $serviceAccount -}}

{{- end }}
{{- end }}
