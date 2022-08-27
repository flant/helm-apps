{{- define "apps-adopt-utils.adopt-specs"}}
{{-     $RelatedScope := index . 0 -}}
{{-     $specsMapping := index . 1 }}
{{-     range  $specLibName, $specOldName := $specsMapping }}
{{-         with index $RelatedScope $specOldName }}
{{-             set $RelatedScope $specLibName . }}
{{-         end }}
{{-     end }}
{{- end }}