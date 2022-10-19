{{- define "apps.generateContainerEnvVars" }}
{{- $ := index . 0 }}
{{- include "apps-utils.enterScope" (list $ "envVars") }}
{{- include "fl.generateContainerEnvVars" . }}
{{- include "apps-utils.leaveScope" $ }}
{{- end }}

{{- define "apps.generateSecretEnvVars" }}
{{- $ := index . 0 }}
{{- include "apps-utils.enterScope" (list $ "secretEnvVars") }}
{{- include "fl.generateSecretEnvVars" . }}
{{- include "apps-utils.leaveScope" $ }}
{{- end }}

{{- define "apps.generateConfigMapEnvVars" }}
{{- $ := index . 0 }}
{{- include "apps-utils.enterScope" (list $ "EnvVars") }}
{{- include "fl.generateConfigMapEnvVars" . }}
{{- include "apps-utils.leaveScope" $ }}
{{- end }}

{{- define "apps.generateConfigMapData" }}
{{- $ := index . 0 }}
{{- include "apps-utils.enterScope" (list $ "data") }}
{{- include "fl.generateConfigMapData" . }}
{{- include "apps-utils.leaveScope" $ }}
{{- end }}

{{- define "apps.value" }}
{{- $ := index . 0 }}
{{- include "apps-utils.enterScope" (list $ (last .)) }}
{{- include "fl.value" (initial .) }}
{{- include "apps-utils.leaveScope" $ }}
{{- end }}