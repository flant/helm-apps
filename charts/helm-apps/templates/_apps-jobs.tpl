{{- define "apps-jobs" }}
  {{- $ := index . 0 }}
  {{- $RelatedScope := index . 1 }}
    {{- if not (kindIs "invalid" $RelatedScope) }}

  {{- $_ := set $RelatedScope "__GroupVars__" (dict "type" "apps-jobs" "name" "apps-jobs") }}
  {{- include "apps-utils.renderApps" (list $ $RelatedScope) }}
{{- end -}}
{{- end -}}

{{- define "apps-jobs.render" }}
{{- $ := . }}
{{- $_ := set $ "CurrentJob" $.CurrentApp }}
{{- with $.CurrentApp }}

{{- if not .containers }}
{{- fail (printf "Установлено значение enabled для не настроенной '%s' в %s джобы!" $.CurrentApp.name "apps-jobs") }}
{{- end }}
apiVersion: batch/v1
kind: Job
{{- include "apps-helpers.metadataGenerator" (list $ .) -}}

{{- include "apps-helpers.jobTemplate" (list $ .) -}}

{{- include "apps-components.generateConfigMapsAndSecrets" $ -}}

{{- include "apps-components.verticalPodAutoscaler" (list $ . .verticalPodAutoscaler "Job") -}}

{{- end }}
{{- end }}