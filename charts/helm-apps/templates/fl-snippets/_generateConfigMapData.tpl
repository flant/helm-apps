{{- define "fl.generateConfigMapData" }}
  {{- $ := index . 0 }}
  {{- $relativeScope := index . 1 }}
  {{- $data := index . 2 }}
  {{- $upper := false }}
  {{- if gt (len .) 3 }}
  {{- $upper = true }}
  {{- end -}}

  {{- range $key, $value := $data }}
    {{- if $upper }}
       {{- $key = upper $key }}
    {{- end }}
    {{- $value = include "apps.value" (list $ $relativeScope $value $key) }}
    {{- if eq $value "___FL_THIS_ENV_VAR_WILL_BE_DEFINED_BUT_EMPTY___" }}
{{ $key | quote }}: ""
    {{- else if ne $value "" }}
{{ $key | quote }}: {{ $value | quote }}
    {{- end }}
  {{- end }}
{{- end }}