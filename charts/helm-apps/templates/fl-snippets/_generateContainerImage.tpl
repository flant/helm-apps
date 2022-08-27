{{- define "fl.generateContainerImageQuoted" }}
  {{- $ := index . 0 }}
  {{- $relativeScope := index . 1 }}
  {{- $imageConfig := index . 2 }}

  {{- $imageName := include "fl.value" (list $ . $imageConfig.name) }}
  {{- if include "fl.value" (list $ . $imageConfig.staticTag) }}
    {{- $imageName }}:{{ include "fl.value" (list $ . $imageConfig.staticTag) }}
  {{- else -}}
    {{- index $.Values.werf.image $imageName }}
  {{- end }}
{{- end }}
