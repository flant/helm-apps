{{- define "apps-cronjobs" }}
  {{- $ := index . 0 }}
  {{- $RelatedScope := index . 1 }}
  {{- if not (kindIs "invalid" $RelatedScope) }}

  {{- $_ := set $RelatedScope "__GroupVars__" (dict "type" "apps-cronjobs" "name" "apps-cronjobs") }}
  {{- include "apps-utils.renderApps" (list $ $RelatedScope) }}
{{- end -}}
{{- end -}}

{{- define "apps-cronjobs.render" }}
{{- $ := . }}
{{- $_ := set $ "CurrentCronJob" $.CurrentApp }}
{{- with $.CurrentApp }}
{{- if not .containers }}
{{- fail (printf "Установлено значение enabled для не настроенной '%s' в %s джобы!" $.CurrentApp.name "apps-cronjobs") }}
{{- end }}
{{- if semverCompare ">=1.21-0" $.Capabilities.KubeVersion.GitVersion }}
apiVersion: batch/v1
{{- else }}
apiVersion: batch/v1beta1
{{- end }}
kind: CronJob
{{- include "apps-helpers.metadataGenerator" (list $ .) }}
spec:
  {{- $specs := dict }}
  {{- $_ = set $specs "Strings" (list "schedule" "concurrencyPolicy") }}
  {{- $_ = set $specs "Numbers" (list "failedJobsHistoryLimit" "startingDeadlineSeconds" "successfulJobsHistoryLimit") }}
  {{- $_ = set $specs "Bools" (list "suspend") }}
  {{- include "apps-utils.generateSpecs" (list $ . $specs) | indent 2 }}
  jobTemplate: {{ include "apps-helpers.jobTemplate" (list $ .) | nindent 4 -}}

{{- include "apps-components.generateConfigMapsAndSecrets" $ -}}

{{- include "apps-components.verticalPodAutoscaler" (list $ . .verticalPodAutoscaler "CronJob") -}}

{{- end }}
{{- end }}
