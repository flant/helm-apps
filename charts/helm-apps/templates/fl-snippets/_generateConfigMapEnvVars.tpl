{{- define "fl.generateConfigMapEnvVars" }}
  {{- $ := index . 0 }}
  {{- $relativeScope := index . 1 }}
  {{- $envs := index . 2 }}

  {{- range $envVarName, $envVarVal := $envs }}
    {{- if $.Values.global.configFlantLibVariableUppercaseEnvs }}
       {{- $envVarName = upper $envVarName }}
    {{- end }}
    {{- $envVarVal = include "apps.value" (list $ $relativeScope $envVarVal $envVarName) }}
    {{- if eq $envVarVal "___FL_THIS_ENV_VAR_WILL_BE_DEFINED_BUT_EMPTY___" }}
{{ $envVarName | quote }}: ""
    {{- else if ne $envVarVal "" }}
{{ $envVarName | quote }}: {{ $envVarVal | quote }}
    {{- end }}
  {{- end }}
{{- end }}
