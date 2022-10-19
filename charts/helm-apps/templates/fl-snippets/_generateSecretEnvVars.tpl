{{- define "fl.generateSecretEnvVars" }}
{{- $ := index . 0 }}
{{-  if $.Values.global.configFlantLibVariableUppercaseEnvs }}
{{- include "fl.generateSecretData" (append . true) }}
{{- else }}
{{- include "fl.generateSecretData" . }}
{{- end }}
{{- end }}
