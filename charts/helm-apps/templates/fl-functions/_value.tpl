{{- define "fl.value" }}
  {{- $ := index . 0 }}
  {{- $relativeScope := index . 1 }}
  {{- $val := index . 2 }}
  {{- $prefix := "" }}  {{- /* Optional */ -}}
  {{- $suffix := "" }}  {{- /* Optional */ -}}
  {{- if gt (len .) 3 }}
    {{- $optionalArgs := index . 3 }}
    {{- if hasKey $optionalArgs "prefix" }}
      {{- $prefix = $optionalArgs.prefix }}
    {{- end }}
    {{- if hasKey $optionalArgs "suffix" }}
      {{- $suffix = $optionalArgs.suffix }}
    {{- end }}
  {{- end }}

  {{- if kindIs "map" $val }}
    {{- $currentEnvVal := "" }}
    {{- if hasKey $val $.Values.global.env }}
      {{- $currentEnvVal = index $val $.Values.global.env }}
    {{- else if eq (include "_fl.getValueRegex" .) "" }}
      {{- $currentEnvVal = $._CurrentFuncResult }}
    {{- else if hasKey $val "_default" }}
      {{- $currentEnvVal = index $val "_default" }}
    {{- end }}
    {{- include "fl._renderValue" (list $ $relativeScope $currentEnvVal $prefix $suffix) }}
  {{- else }}
    {{- include "fl._renderValue" (list $ $relativeScope $val $prefix $suffix) }}
  {{- end }}
{{- end }}

{{- define "fl._renderValue" }}
  {{- $ := index . 0 }}
  {{- $relativeScope := index . 1 }}
  {{- $val := index . 2 }}
  {{- $prefix := index . 3 }}
  {{- $suffix := index . 4 }}

  {{- if and (not (kindIs "map" $val)) (not (kindIs "slice" $val)) }}
    {{- $valAsString := toString $val }}
    {{- if not (regexMatch "^<(nil|no value)>$" $valAsString) }}
      {{- $result := "" }}
      {{- if contains "{{" $valAsString }}
        {{- if empty $relativeScope }}
          {{- $relativeScope = $ }}  {{- /* tpl fails if $relativeScope is empty */ -}}
        {{- end }}
        {{- $result = tpl (printf "%s{{ with $.RelativeScope }}%s{{ end }}%s" $prefix $valAsString $suffix) (merge (dict "RelativeScope" $relativeScope) $) }}
      {{- else }}
        {{- $result = printf "%s%s%s" $prefix $valAsString $suffix }}
      {{- end }}
      {{- if ne $result "" }}{{ $result }}{{ end }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "_fl.getValueRegex" }}
{{-     $ := index . 0 }}
{{-     $val := index . 2 }}
{{-     $_ := set $ "_CurrentFuncError" "" }}
{{-     $regexList := list }}
{{-     range $env, $value := omit $val "_default" $.Values.global.env }}
{{-         $env = trimPrefix "^" $env }}
{{-         $env = trimSuffix "$" $env }}
{{-         $env = printf "^%s$" $env }}
{{-         if regexMatch $env $.Values.global.env }}
{{-             $_ := set $ "_CurrentFuncResult" $value }}
{{-             $regexList = append $regexList $env }}
{{-         end }}
{{-     end }}
{{-     if gt (len $regexList) 1 }}
{{-         fail (printf "В переменной %s используется неоднозначное определение окружения %s" ($.CurrentPath | join ".") $regexList) }}
{{-     end }}
{{-     if eq (len $regexList) 0 }}
{{-         print "not found" }}
{{-     end }}
{{- end -}}

{{- define "fl.Result" }}
{{- $ := index . 0 }}
{{- $_ := set $ "_CurrentFuncResult" (index . 1) }}
{{- $_ = set $ "_CurrentFuncError" (index . 2) }}
{{- end }}
