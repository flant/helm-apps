{{- define "apps-pvcs" }}
  {{- $ := index . 0 }}
  {{- $RelatedScope := index . 1 }}
    {{- if not (kindIs "invalid" $RelatedScope) }}
  {{- $_ := set $RelatedScope "__GroupVars__" (dict "type" "apps-pvcs" "name" "apps-pvcs") }}
  {{- include "apps-utils.renderApps" (list $ $RelatedScope) }}
{{- end -}}
{{- end -}}

{{- define "apps-pvcs.render" }}
{{- $ := . }}
{{- with $.CurrentApp }}
kind: PersistentVolumeClaim
apiVersion: v1
{{- include "apps-helpers.metadataGenerator" (list $ .) }}
spec:
  {{- $specsPVCs := dict }}
  {{- $_ := set $specsPVCs "Lists" ( list "accessModes" ) }}
  {{- $_ := set $specsPVCs "Maps" (list "resources" ) }}
  {{- $_ := set $specsPVCs "Strings" (list "storageClassName") }}
  {{- include "apps-utils.generateSpecs" (list $ . $specsPVCs) | indent 2 }}
{{- end }}
{{- end }}
