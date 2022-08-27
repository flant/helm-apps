{{- define "apps-specs.containers.volumes" }}
{{- $ := index . 0 }}
{{- $relativeScope := index . 1 }}
{{- with $relativeScope }}
{{ include "fl.value" (list $ . .volumes) | trim | nindent 0 }}
{{ include "apps-helpers.generateVolumes" (list $ .) | trim | nindent 0 }}
{{- $_ := set . "__specName__" "volumes"}}
{{- end }}
{{- end }}

{{- define "apps-specs.selector" }}
{{- $ := index . 0 }}
{{- $relativeScope := index . 1 }}
{{- with $relativeScope }}
matchLabels: {{- include "fl.generateSelectorLabels" (list $ . .name) | nindent 2 }}
{{- $_ := set . "__specName__" "selector"}}
{{- end }}
{{- end }}

{{- define "apps-specs.serviceName" }}
{{- $ := index . 0 }}
{{- $relativeScope := index . 1 }}
{{- with $relativeScope }}
{{- include "fl.value" (list $ . .service.name) }}
{{- $_ := set . "__specName__" "serviceName"}}
{{- end }}
{{- end }}

{{- define "apps-specs.volumeClaimTemplates" }}
{{- $ := index . 0 }}
{{- $relativeScope := index . 1 }}
{{- with $relativeScope }}
{{- include "fl.value" (list $ . .volumeClaimTemplates) | nindent 0 }}
{{- /* Loop through containers to generate Pod volumes */ -}}
{{- range $_, $containersType := list "initContainers" "containers" }}
{{- range $_containerName, $_container := index $.CurrentApp $containersType }}
{{- if include "fl.isTrue" (list $ . .enabled) }}
{{- $_ := set . "name" $_containerName }}
{{- $_ = set $ "CurrentContainer" $_container }}
{{- range $persistantVolumeName, $persistantVolume := .persistantVolumes }}
{{- $pvcName := print $persistantVolumeName "-" $containersType "-" $.CurrentApp.name "-" $.CurrentContainer.name "-" $persistantVolume.mountPath | include "fl.formatStringAsDNSLabel" }}
- metadata:
    name: {{ $pvcName }}
  spec:
    accessModes: {{include "fl.value" (list $ . $persistantVolume.accessModes) | default "\n- ReadWriteOnce" | nindent 4 }}
    resources:
      requests:
        storage: {{ include "fl.value" (list $ . $persistantVolume.size) }}
    storageClassName: {{ include "fl.value" (list $ . $persistantVolume.storageClass) }}
    volumeMode: Filesystem
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- $_ := set . "__specName__" "volumeClaimTemplates"}}
{{- end }}
{{- end }}

