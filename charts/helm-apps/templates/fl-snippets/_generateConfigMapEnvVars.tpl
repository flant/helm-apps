{{- define "fl.generateConfigMapEnvVars" }}
{{- $ := index . 0 }}
{{-  if $.Values.global.configFlantLibVariableUppercaseEnvs }}
{{- include "fl.generateConfigMapData" (append . true) }}
{{- else }}
{{- include "fl.generateConfigMapData" . }}
{{- end }}
{{- end }}
