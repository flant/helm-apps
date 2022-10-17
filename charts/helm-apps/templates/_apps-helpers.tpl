{{- define "apps-helpers.generateVolumes" }}
    {{- $ := index . 0 }}
    {{- $RelatedScope := index . 1 }}
      {{- /* Loop through containers to generate Pod volumes */ -}}
      {{- range $_, $containersType := list "initContainers" "containers" }}
      {{- range $_containerName, $_container := index $.CurrentApp $containersType }}
      {{- if include "fl.isTrue" (list $ . .enabled) }}
      {{- $_ := set . "name" $_containerName }}
      {{- $_ = set $ "CurrentContainer" $_container }}
      {{- /* Mount ConfigMaps created by "configFiles:" option as volumes */ -}}
      {{- range $configFileName, $_ := .configFiles }}
      {{- if include "fl.value" (list $ . .content) }}
      {{- $_ := set . "name" (print "config-" $containersType "-" $.CurrentApp.name "-" $.CurrentContainer.name "-" $configFileName | include "fl.formatStringAsDNSLabel") }}
      {{- else }}
      {{- if not ( include "fl.value" (list $ . .name)) }}
      {{- fail (printf "Для app '%s' %s '%s' в configFiles '%s' нет content и забыли указать .name" $.CurrentApp.name $containersType $.CurrentContainer.name $configFileName) }}
      {{- end }}
      {{- end }}
- name: {{ print "config-" $containersType "-" $.CurrentApp.name "-" $.CurrentContainer.name "-" $configFileName | include "fl.formatStringAsDNSLabel" | quote }}
  configMap:
    name: {{ .name | quote }}
      {{- with include "fl.value" (list $ . .defaultMode) }}
    defaultMode: {{ . }}
      {{- end }}
      {{- end }}
      {{- range $configFileName, $_ := .configFilesYAML }}
      {{- if kindIs "map" .content }}
      {{- $_ := set . "name" (print "config-yaml-" $containersType "-" $.CurrentApp.name "-" $.CurrentContainer.name "-" $configFileName | include "fl.formatStringAsDNSLabel") }}
      {{- else }}
      {{- if not ( include "fl.value" (list $ . .name)) }}
      {{- fail (printf "Для app '%s' %s '%s' в configFiles '%s' нет content и забыли указать .name" $.CurrentApp.name $containersType $.CurrentContainer.name $configFileName) }}
      {{- end }}
      {{- end }}
- name: {{ print "config-yaml-" $containersType "-" $.CurrentApp.name "-" $.CurrentContainer.name "-" $configFileName | include "fl.formatStringAsDNSLabel" | quote }}
  configMap:
    name: {{ .name | quote }}
      {{- with include "fl.value" (list $ . .defaultMode) }}
    defaultMode: {{ . }}
      {{- end }}
      {{- end }}
      {{- /* Mount Secrets created by "secretConfigFiles:" option as volumes */ -}}
      {{- range $secretConfigFileName, $_ := .secretConfigFiles }}
      {{- if include "fl.value" (list $ . .content) }}
      {{- $_ := set . "name" (print "config-" $containersType "-" $.CurrentApp.name "-" $.CurrentContainer.name "-" $secretConfigFileName | include "fl.formatStringAsDNSLabel") }}
      {{- end }}
      {{- if or (include "fl.value" (list $ . .content)) (include "fl.value" (list $ . .name)) }}
- name: {{ print "config-" $containersType "-" $.CurrentApp.name "-" $.CurrentContainer.name "-" $secretConfigFileName | include "fl.formatStringAsDNSLabel" | quote }}
  secret:
    secretName: {{ .name | quote }}
    {{- with include "fl.value" (list $ . .defaultMode) }}
    defaultMode: {{ . }}
    {{- end }}
      {{- end }}
      {{- end }}
      {{- end }}
      {{- end }}
      {{- end }}
{{- end -}}

{{- /* Mount config files from ConfigMaps created by "configFiles:" option */ -}}
{{- define "apps-helpers.generateVolumeMounts" }}
    {{- $ := index . 0 }}
    {{- $RelatedScope := index . 1 }}
    {{- range $configFileName, $configFile := $.CurrentContainer.configFiles }}
    {{- if or (include "fl.value" (list $ . .content)) (include "fl.value" (list $ . .name)) }}
- name: {{ print "config-" $.CurrentApp._currentContainersType "-" $.CurrentApp.name "-" $.CurrentContainer.name "-" $configFileName | include "fl.formatStringAsDNSLabel" | quote }}
  subPath: {{ $configFileName | quote }}
  mountPath: {{ include "fl.valueQuoted" (list $ . .mountPath) }}
    {{- end }}
    {{- end }}
    {{- range $configFileName, $configFile := $.CurrentContainer.configFilesYAML }}
    {{- if or (kindIs "map" .content) (include "fl.value" (list $ . .name)) }}
- name: {{ print "config-yaml-" $.CurrentApp._currentContainersType "-" $.CurrentApp.name "-" $.CurrentContainer.name "-" $configFileName | include "fl.formatStringAsDNSLabel" | quote }}
  subPath: {{ $configFileName | quote }}
  mountPath: {{ include "fl.valueQuoted" (list $ . .mountPath) }}
    {{- end }}
    {{- end }}
    {{- /* Mount secret files from ConfigMaps created by "secretConfigFiles:" option */ -}}
    {{- range $secretConfigFileName, $secretConfigFile := $.CurrentContainer.secretConfigFiles }}
- name: {{ print "config-" $.CurrentApp._currentContainersType "-" $.CurrentApp.name "-" $.CurrentContainer.name "-" $secretConfigFileName | include "fl.formatStringAsDNSLabel" | quote }}
  subPath: {{ $secretConfigFileName | quote }}
  mountPath: {{ include "fl.valueQuoted" (list $ . .mountPath) }}
    {{- end }}
    {{- /* Mount persistantVolumes */ -}}
    {{- range $persistantVolumeName, $persistantVolume := $.CurrentContainer.persistantVolumes }}
    {{- $pvcName := print $persistantVolumeName "-" $.CurrentApp._currentContainersType "-" $.CurrentApp.name "-" $.CurrentContainer.name "-" $persistantVolume.mountPath | include "fl.formatStringAsDNSLabel" }}
- name: {{ $pvcName | quote }}
  mountPath: {{ $persistantVolume.mountPath | quote }}
    {{- end }}
{{- end -}}

{{- define "apps-helpers.generateContainers" }}
    {{- $ := index . 0 }}
    {{- $RelatedScope := index . 1 }}
    {{- $containers := index . 2 }}
    {{- include "apps-utils.enterScope" (list $ "containers") -}}

    {{- range $_containerName, $_container := $containers }}
    {{- include "apps-utils.enterScope" (list $ $_containerName) -}}
    {{- if not (hasKey . "enabled") }}
    {{- $_ := set . "enabled" true }}
    {{- end }}
    {{- if include "fl.isTrue" (list $ . .enabled) }}
    {{- $_ := set . "name" $_containerName }}
    {{- $_ = set $ "CurrentContainer" $_container }}
- name: {{ include "fl.valueQuoted" (list $ . .name) }}
  image: {{ include "fl.generateContainerImageQuoted" (list $ . .image) }}
  {{- with (include "apps-helpers.genereteContainersEnv" (list $ .) | trim) }}
  env:
    {{- . | nindent 2 }}
  {{- end }}
  {{- with (include "apps-helpers.genereteContainersEnvFrom" (list $ .) | trim) }}
  envFrom:
    {{- . | nindent 2 }}
  {{- end }}
  {{- $resources := include "fl.generateContainerResources" (list $ . .resources) | trim }}
  {{ with $resources }}
  resources:
    {{- . | nindent 4 }}
  {{- end }}
  {{- $volumeMounts := include "fl.value" (list $ . .volumeMounts) | trim }}
  {{- $volumeMounts = list $volumeMounts (include "apps-helpers.generateVolumeMounts" (list $ .) | trim) | join "\n" | trim }}
  {{- with $volumeMounts }}
  volumeMounts: {{ print $volumeMounts | trim | nindent 2}}
  {{- end -}}

  {{- $specsContainers := dict }}
  {{- $_ = set $specsContainers "Lists" ( list "args" "command" "ports") }}
  {{- $_ = set $specsContainers "Maps" (list "lifecycle" "livenessProbe" "readinessProbe" "securityContext" "startupProbe") }}
  {{- $_ = set $specsContainers "Strings" (list "imagePullPolicy" "terminationMessagePath" "terminationMessagePolicy" "workingDir") }}
  {{- $_ = set $specsContainers "Bools" (list "stdin" "stdinOnce" "tty" "workingDir" ) }}
  {{- include "apps-utils.generateSpecs" (list $ . $specsContainers) | trim | nindent 2 }}
{{- end }}
{{- include "apps-utils.leaveScope" $ }}
{{- end }}
{{- include "apps-utils.leaveScope" $ }}
{{- end -}}

{{- define "apps-helpers.podTemplate" }}
    {{- $ := index . 0 }}
    {{- $RelatedScope := index . 1 }}
{{- with $RelatedScope }}
{{- $_ := set . "__DO_NOT_ANNOTATE_WITH_LIB_VERSION__" true }}
{{- include "apps-helpers.metadataGenerator" (list $ .) }}
spec:
  {{- $_ := set $.CurrentApp "_currentContainersType" "initContainers" }}
  {{ with (include "apps-helpers.generateContainers" (list $ . .initContainers) | trim) }}
  initContainers:
  {{- . | nindent 2 }}
  {{- end }}
  {{- $_ = set $.CurrentApp "_currentContainersType" "containers" }}
  containers:
  {{- include "apps-helpers.generateContainers" (list $ . .containers) | trim | nindent 2 }}
  {{- $specsTemplate := dict }}
  {{- $_ = set $specsTemplate "Lists" ( list "tolerations" "imagePullSecrets" "hostAliases" "topologySpreadConstraints" "apps-specs.containers.volumes") }}
  {{- $_ = set $specsTemplate "Maps" (list "affinity" "dnsConfig" "nodeSelector" "overhead" "readinessGates" "securityContext") }}
  {{- $_ = set $specsTemplate "Strings" (list "dnsPolicy" "hostname" "nodeName" "preemptionPolicy" "priorityClassName" "restartPolicy" "runtimeClassName" "schedulerName" "serviceAccount" "serviceAccountName" "subdomain") }}
  {{- $_ = set $specsTemplate "Numbers" (list "activeDeadlineSeconds" "priority" "terminationGracePeriodSeconds") }}
  {{- $_ = set $specsTemplate "Bools" (list "automountServiceAccountToken" "enableServiceLinks" "hostIPC" "hostNetwork" "hostPID" "setHostnameAsFQDN" "shareProcessNamespace") }}
  {{- include "apps-utils.generateSpecs" (list $ . $specsTemplate) | trim | nindent 2 }}
{{- $_ := set . "__specName__" "template"}}
{{- end }}
{{- end -}}

{{- define "apps-helpers.activateContainerForDefault" }}
{{- $ := . }}
{{-   range $_, $containersType := list "initContainers" "containers" }}
{{-     range $_containerName, $_container := index $.CurrentApp $containersType }}
{{- if not (hasKey . "enabled") }}
{{- $_ := set . "enabled" true }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "apps-helpers.genereteContainersEnv" }}
    {{- $ := index . 0 }}
    {{- $RelatedScope := index . 1 }}
    {{- with $RelatedScope }}
    {{- if include "fl.isTrue" (list $ . $.CurrentApp.alwaysRestart) }}
    {{- $_ := set .envVars "FL_APP_ALWAYS_RESTART" (randAlphaNum 20) }}
    {{- end }}
    {{- if kindIs "map" .envYAML }}
    {{- include "apps-utils.enterScope" (list $ "envYAML") }}
    {{- $_ := set $ "CurrentEnvYAML" (dict "path" (list) "local" . "envs" .envYAML "startPathLength" (len $.CurrentPath)) }}
    {{- include "apps-helpers.generateEnvYAML" $ }}
    {{- include "apps-utils.leaveScope" $ }}
    {{- end }}
    {{- include "apps.generateContainerEnvVars" (list $ . .envVars) | trim | nindent 0 }}
    {{- with (include "fl.value" (list $ . .env) | trim) }}
    {{- . | nindent 0}}
    {{- end }}
    {{- with (include "fl.generateContainerFromSecretsEnvVars" (list $ . .fromSecretsEnvVars) | trim) }}
    {{- . | nindent 0 }}
    {{- end }}

    {{- end }}
{{- end }}
{{- define "apps-helpers.genereteContainersEnvFrom" }}
    {{- $ := index . 0 }}
    {{- $RelatedScope := index . 1 }}
    {{- with $RelatedScope }}
    {{- include "fl.value" (list $ . .envFrom) | trim | nindent 0 }}
    {{- /* Mount envs from Secret created by "secretEnvVars:" option */ -}}
    {{- if include "fl.generateSecretEnvVars" (list $ . .secretEnvVars) }}
- secretRef:
    name: {{ print "envs-" $.CurrentApp._currentContainersType "-" $.CurrentApp.name "-" .name | include "fl.formatStringAsDNSLabel" | quote }}
    {{- end }}
    {{- end }}
{{- end }}

{{- define "apps-helpers.jobTemplate" }}
    {{- $ := index . 0 }}
    {{- $RelatedScope := index . 1 }}
{{- with $RelatedScope }}
spec:
  {{- $specs := dict }}
  {{- $_ := set $specs "Maps" (list "selector") }}
  {{- $_ = set $specs "Strings" (list "completionMode") }}
  {{- $_ = set $specs "Numbers" (list "activeDeadlineSeconds" "backoffLimit" "completions" "parallelism" "ttlSecondsAfterFinished") }}
  {{- $_ = set $specs "Bools" (list "manualSelector" "suspend") }}
{{ include "apps-utils.generateSpecs" (list $ . $specs) | trim | indent 2 }}
  template: {{ include "apps-helpers.podTemplate" (list $ .) | trim | nindent 4 }}
{{- end }}
{{- end -}}

{{- define "apps-helpers.generateAnnotations" }}
    {{- $ := index . 0 }}
    {{- $RelatedScope := index . 1 }}
{{- with $RelatedScope }}
{{- $annotationsMap := dict }}
{{- $libAnnotations := dict }}
{{- if hasKey . "__annotations__" }}
{{- $annotationsMap = $.CurrentApp.__annotations__ | mustDeepCopy }}
{{- end }}
{{- if hasKey $.CurrentApp "werfWeight" }}
{{- $_ := set $libAnnotations "werf.io/weight" (include "fl.value" (list $ . $.CurrentApp.werfWeight)) }}
{{- end }}
{{- $libVersion := include "apps-version.getLibraryVersion" $ | trim }}
{{- with $libVersion }}
{{- if not (eq . "_FLANT_APPS_LIBRARY_VERSION_") }}
{{- if not $RelatedScope.__DO_NOT_ANNOTATE_WITH_LIB_VERSION__ }}
{{- $_ := set $libAnnotations  "helm-apps/version" . }}
{{- end }}
{{- end }}
{{- end }}
{{- $userAnnotations := fromYaml (include "fl.value" (list $ . $.CurrentApp.annotations)) }}
{{- $relatedScopeAnnotations := fromYaml (include "fl.value" (list $ . .annotations)) }}
{{- $annotationsMap = mergeOverwrite $annotationsMap $userAnnotations  $relatedScopeAnnotations $libAnnotations }}
  {{- if gt (len $annotationsMap) 0 }}
annotations:
{{- range $a, $v := $annotationsMap }}
  {{ $a }}: {{ $v | quote }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "apps-helpers.metadataGenerator"}}
    {{- $ := index . 0 }}
    {{- $RelatedScope := index . 1 }}
{{- with $RelatedScope }}
metadata:
  {{- if hasKey . "name" }}
  name: {{ include "fl.value" (list $ . .name) | quote }}
  {{- else }}
  name: {{ $.CurrentApp.name | quote }}
  {{- end }}
  {{- include "apps-helpers.generateAnnotations" (list $ .) | nindent 2 }}
  labels:
  {{- include "fl.generateLabels" (list $ . $.CurrentApp.name) | nindent 4 }}
  {{- with include "fl.value" (list $ . .labels) }}
    {{- . | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "apps-helpers.generateHPAMetrics" }}
{{- $ := index . 0 }}
{{- $RelatedScope := index . 1 }}
{{- include "apps-utils.enterScope" (list $ "metrics") }}
{{- with $RelatedScope }}
{{- range $metricName, $metric := .horizontalPodAutoscaler.metrics }}
{{- if include "fl.isTrue" (list $ $RelatedScope .enabled) }}
{{- include "apps-utils.enterScope" (list $ $metricName) }}
{{- if has $metricName (list "cpu" "memory") }}
- type: Resource
  resource:
    name: {{ $metricName }}
    target:
      type: Utilization
      averageUtilization: {{ include "apps-utils.requiredValue" (list $ . "averageUtilization") }}
{{- else }}
{{ $type :=  include "apps-utils.requiredValue" (list $ . "type") }}
{{- if eq $type "Object"}}
- type: Object
  object:
    describedObject:
      apiVersion: v1
      kind: {{ include "apps-utils.requiredValue" (list $ . "kind") }}
      name: {{ $metricName }}
    metric:
      name: {{ include "apps-utils.requiredValue"  (list $ . "customMetricResourceName") }}
    target:
      type: Value
      value: {{ include "apps-utils.requiredValue" (list $ . "targetValue") }}
{{- end }}
{{- end }}
{{- include "apps-utils.leaveScope" $ }}
{{- end }}
{{- end }}
{{- end }}
{{- include "apps-utils.leaveScope" $ }}
{{- end -}}

{{- define "apps-helpers.generateEnvYAML" }}
    {{- $ := . }}
    {{- $envs := $.CurrentEnvYAML.envs }}
    {{- range $CurrentEnvKey, $CurrentEnvDict := $envs }}
    {{- include "apps-utils.enterScope" (list $ $CurrentEnvKey) }}
    {{- if kindIs "map" $CurrentEnvDict }}
    {{- if hasKey $CurrentEnvDict "_default" }}
    {{- if not (kindIs "map" $.CurrentContainer.envVars) }}
    {{- $_ := set $.CurrentContainer "envVars" dict }}
    {{- end }}
    {{- $envName := slice $.CurrentPath $.CurrentEnvYAML.startPathLength | join "_" | upper }}
    {{- if hasKey $CurrentEnvDict "name" }}
    {{- $envName = $CurrentEnvDict.name }}
    {{- end }}
    {{- if hasKey $.CurrentContainer.envVars $envName }}
    {{- $_ := set $.CurrentContainer.envVars $envName (mergeOverwrite $CurrentEnvDict (index $.CurrentContainer.envVars $envName)) }}
    {{- else }}
    {{- $_ := set $.CurrentContainer.envVars $envName $CurrentEnvDict }}
    {{- end }}
    {{- end }}
    {{- $_ := set $.CurrentEnvYAML "envs" $CurrentEnvDict }}
    {{- include "apps-helpers.generateEnvYAML" $ }}
    {{- else }}
    {{- end }}
    {{- include "apps-utils.leaveScope" $ }}
    {{- end }}
{{- end }}

{{- define "apps-helpers.generateConfigYAML" }}
    {{- $ := . }}
    {{- $content := $.CurrentConfigYAML.content }}
    {{- range $CurrentKey, $CurrentDict := $content }}
    {{- include "apps-utils.enterScope" (list $ $CurrentKey) }}
    {{- if kindIs "map" $CurrentDict }}
    {{- if hasKey $CurrentDict "_default" }}
    {{- $_ := set $content $CurrentKey (include "fl.value" (list $ . $CurrentDict))}}
    {{- else }}
    {{- $_ := set $.CurrentConfigYAML "content" $CurrentDict }}
    {{- include "apps-helpers.generateConfigYAML" $ }}
    {{- end }}
    {{- else }}
    {{- end }}
    {{- include "apps-utils.leaveScope" $ }}
    {{- end }}
{{- end }}