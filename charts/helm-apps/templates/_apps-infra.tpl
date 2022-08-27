# TODO:
{{- define "apps-infra" }}
  {{- $ := index . 0 }}
  {{- $RelatedScope := index . 1 -}}
  {{- include "apps-utils.enterScope" (list $ "apps-infra") }}
  {{- if hasKey $RelatedScope "node-users"}}
  {{- include "apps-infra.node-users" (list $ (index $RelatedScope "node-users")) }}
  {{- end }}
  {{- if hasKey $RelatedScope "node-groups"}}
  {{- include "apps-infra.node-groups" (list $ (index $RelatedScope "node-groups")) }}
  {{- end }}
  {{- include "apps-utils.leaveScope" $ }}
{{- end }}

{{- define "apps-infra.node-users"}}
  {{- $ := index . 0 }}
  {{- $RelatedScope := index . 1 -}}
   {{- include "apps-utils.enterScope" (list $ "node-users") }}
   {{- range $_appName, $_app := omit $RelatedScope  "global" "enabled" "_include" "__GroupVars__" -}}
   {{- include "apps-utils.enterScope" (list $ $_appName) }}
   {{- $_ := set . "name" $_appName }}
   {{- $_ = set $ "CurrentApp" $_app }}
{{- include "apps-utils.preRenderHooks" $ }}
   {{- if include "fl.isTrue" (list $ . .enabled) }}
apiVersion: deckhouse.io/v1
kind: NodeUser
metadata:
  name: {{ .name | quote }}
  annotations:
    {{- include "fl.value" (list $ . .annotations) | nindent 4 }}
  labels:
    {{- include "fl.value" (list $ . .labels) | nindent 4 }}
spec:
   {{- $specs := dict }}
  {{- $_ := set $specs "Lists" (list "extraGroups" "nodeGroups" "sshPublicKeys") }}
  {{- $_ = set $specs "Maps" (list) }}
  {{- $_ = set $specs "Strings" (list "sshPublicKey" "passwordHash") }}
  {{- $_ = set $specs "Numbers" (list "uid") }}
  {{- $_ = set $specs "Bools" (list "isSudoer") }}
  {{- $_ = set $specs "Required" (list "uid") }}
  {{- include "apps-utils.generateSpecs" (list $ . $specs) | indent 2 }}
  {{- end }}
  {{- include "apps-utils.leaveScope" $ }}
  {{- end }}
  {{- include "apps-utils.leaveScope" $ }}
{{- end }}

{{- define "apps-infra.node-groups"}}
  {{- $ := index . 0 }}
  {{- $RelatedScope := index . 1 -}}
   {{- include "apps-utils.enterScope" (list $ "node-groups") }}
   {{- range $_appName, $_app := omit $RelatedScope  "global" "enabled" "_include" "__GroupVars__" -}}
   {{- include "apps-utils.enterScope" (list $ $_appName) }}
   {{- $_ := set . "name" $_appName }}
   {{- $_ = set $ "CurrentApp" $_app }}
   {{- if ._preRenderHook }}
    {{- $_ := include "fl.value" (list $ . ._preRenderHook) }}
   {{- end }}
   {{- if include "fl.isTrue" (list $ . .enabled) }}
---
#{{ print "#" $.CurrentPath }}
apiVersion: deckhouse.io/v1
kind: NodeGroup
metadata:
  name: {{ .name | quote }}
  annotations:
    {{- include "fl.value" (list $ . .annotations) | nindent 4 }}
  labels:
    {{- include "fl.value" (list $ . .labels) | nindent 4 }}
spec:
   {{- $specs := dict }}
  {{- $_ := set $specs "Lists" (list ) }}
  {{- $_ = set $specs "Maps" (list) }}
  {{- $_ = set $specs "Strings" (list ) }}
  {{- $_ = set $specs "Numbers" (list ) }}
  {{- $_ = set $specs "Bools" (list ) }}
  {{- $_ = set $specs "Required" (list ) }}
  {{- include "apps-utils.generateSpecs" (list $ . $specs) | indent 2 }}
  {{- end }}
  {{- include "apps-utils.leaveScope" $ }}
  {{- end }}
  {{- include "apps-utils.leaveScope" $ }}
{{- end }}