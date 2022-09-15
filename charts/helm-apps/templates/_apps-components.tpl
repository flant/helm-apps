{{- define "apps-components.verticalPodAutoscaler" }}
{{-   $ := index . 0 }}
{{-   $RelatedScope := index . 1 }}
{{-   $verticalPodAutoscaler := index . 2 }}
{{-   $kind := index . 3 }}
{{-   include "apps-utils.enterScope" (list $ "verticalPodAutoscaler") }}
{{-   if $verticalPodAutoscaler }}
{{-     if include "fl.isTrue" (list $ . $verticalPodAutoscaler.enabled) }}
---
{{- include "apps-utils.printPath" $ }}
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
{{- include "apps-helpers.metadataGenerator" (list $ $verticalPodAutoscaler ) }}
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: {{ $kind }}
    name: {{ $.CurrentApp.name | quote }}
  updatePolicy:
    updateMode: {{ include "fl.valueQuoted" (list $ . $verticalPodAutoscaler.updateMode) | default (print "Off" | quote )}}
{{-       if include "fl.value" (list $ . $verticalPodAutoscaler.resourcePolicy) }}
  resourcePolicy: {{- include "fl.value" (list $ . $verticalPodAutoscaler.resourcePolicy) | trim | nindent 4 }}
{{-       else }}
  resourcePolicy: {}
{{-       end }}
{{-     end }}
{{-   end }}
{{-   include "apps-utils.leaveScope" $ }}
{{- end }}

{{- define "apps-components.cerificate" }}
{{-   $ := index . 0 }}
{{-   $RelatedScope := index . 1 }}
{{- with $RelatedScope }}
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: {{ include "fl.value" (list $ . .name) }}
spec:
  secretName: {{ include "fl.value" (list $ . .name) }}
  issuerRef:
    kind: ClusterIssuer
    name: {{ include "fl.valueQuoted" (list $ . .clusterIssuer) | default "letsencrypt" }}
  dnsNames:
  {{- with .host }}
  - {{ include "fl.valueQuoted" (list $ $RelatedScope .) }}
  {{- end }}
  {{- with .hosts }}
  {{- include "fl.value" (list $ $RelatedScope .) | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "apps-components.podDisruptionBudget" }}
{{-   $ := index . 0 }}
{{-   $RelatedScope := index . 1 }}
{{-   $podDisruptionBudget := index . 2 }}
{{-   include "apps-utils.enterScope" (list $ "podDisruptionBudget") }}

{{-   with $podDisruptionBudget }}
{{-     if include "fl.isTrue" (list $ . .enabled) }}
---
{{- include "apps-utils.printPath" $ }}
{{-       if semverCompare ">=1.21.0-0" $.Capabilities.KubeVersion.GitVersion }}
apiVersion: policy/v1
{{-       else }}
apiVersion: policy/v1beta1
{{-       end }}
kind: PodDisruptionBudget
{{- include "apps-helpers.metadataGenerator" (list $ $podDisruptionBudget) }}
spec:
  selector:
    matchLabels:
{{-       include "fl.generateSelectorLabels" (list $ . $.CurrentApp.name) | trim | nindent 6 }}
  maxUnavailable: {{ include "fl.value" (list $ . .maxUnavailable) }}
{{-     end }}
{{-   end }}
{{-   include "apps-utils.leaveScope" $ }}
{{- end }}

{{- define "apps-components.service" }}
{{-   $ := index . 0 }}
{{-   $RelatedScope := index . 1 }}
{{-   $service := index . 2 }}
{{-   include "apps-utils.enterScope" (list $ "service") }}
{{-   if $service }}
{{-     if include "fl.isTrue" (list $ . $service.enabled) }}
{{-       if include "fl.value" (list $ . $service.ports) }}
---
{{- include "apps-utils.printPath" $ }}
apiVersion: v1
kind: Service
{{- include "apps-helpers.metadataGenerator" (list $ $service) }}
spec:
  {{- /* https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/#service-v1-core */ -}}
  {{- $specs := dict }}
  {{- $_ := set $specs "Bools" (list "publishNotReadyAddresses" "allocateLoadBalancerNodePorts") }}
  {{- $_ = set $specs "Lists" (list "clusterIPs" "externalIPs" "ipFamilies" "loadBalancerSourceRanges" "ports") }}
  {{- $_ = set $specs "Strings" (list "externalName" "externalTrafficPolicy" "internalTrafficPolicy" "ipFamilyPolicy" "loadBalancerClass" "loadBalancerIP" "sessionAffinity" "type") }}
  {{- $_ = set $specs "Numbers" (list "healthCheckNodePort") }}
  {{- $_ = set $specs "Maps" (list "sessionAffinityConfig") }}
  {{- include "apps-utils.generateSpecs" (list $ $service $specs) | nindent 2 }}
  selector: {{- include "fl.generateSelectorLabels" (list $ . $.CurrentApp.name) | trim | nindent 4 }}
{{-         if include "fl.isTrue" (list $ . $service.headless) }}
  clusterIP: None
{{-         end }}
{{-       end }}
{{-     end }}
{{-   end }}
{{-   include "apps-utils.leaveScope" $ }}
{{- end }}

{{- define "apps-components.horizontalPodAutoscaler" }}
{{-   $ := index . 0 }}
{{-   $RelatedScope := index . 1 }}
{{-   include "apps-utils.enterScope" (list $ "horizontalPodAutoscaler") }}
{{-   $kind := index . 2 }}
{{-   with $RelatedScope }}
{{-     if $.CurrentApp.horizontalPodAutoscaler }}
{{-       if include "fl.isTrue" (list $ . $.CurrentApp.horizontalPodAutoscaler.enabled) }}
---
{{- include "apps-utils.printPath" $ }}
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
{{- include "apps-helpers.metadataGenerator" (list $ $.CurrentApp.horizontalPodAutoscaler ) }}
spec:
  minReplicas: {{ include "fl.value" (list $ . $.CurrentApp.horizontalPodAutoscaler.minReplicas) }}
  maxReplicas: {{ include "fl.value" (list $ . $.CurrentApp.horizontalPodAutoscaler.maxReplicas) }}
  behavior: {{- include "fl.value" (list $ . $.CurrentApp.horizontalPodAutoscaler.behavior) | trim | nindent 4 }}
  scaleTargetRef:
    apiVersion: apps/v1
    kind: {{ $kind }}
    name: {{ $.CurrentApp.name | quote }}
  metrics:
{{-         with required (printf "You need a valid entry in horizontalPodAutoscaler.metric on %s app" $.CurrentApp.name) (include "fl.value" (list $ . $.CurrentApp.horizontalPodAutoscaler.metrics)) }}
{{-           if kindIs "string" . }}
{{-             print . | nindent 2 }}
{{-           else if kindOf "map" . }}
{{-             include "apps-helpers.generateHPAMetrics" (list $ $RelatedScope) | trim | nindent 2 }}
{{-           end }}
{{-         end }}

{{-         range $_customMetricResourceName, $_customMetricResource := $.CurrentApp.horizontalPodAutoscaler.customMetricResources }}
{{-           include "apps-utils.enterScope" (list $ $_customMetricResourceName) }}
{{-           if include "fl.isTrue" (list $ . .enabled) }}
{{-             $_ := set . "name" $_customMetricResourceName }}
{{-             $_ = set $ "CurrentTargetCustomMetric" $_customMetricResource }}
---
{{- include "apps-utils.printPath" $ }}
apiVersion: deckhouse.io/v1alpha1
kind: {{ include "fl.valueQuoted" (list $ . .kind) }}
{{- include "apps-helpers.metadataGenerator" (list $ . ) }}
spec:
  query: {{ include "fl.valueQuoted" (list $ . .query) }}
{{-           end }}
{{-           include "apps-utils.leaveScope" $ }}
{{-         end }}
{{-       end }}
{{-     end }}
{{-   end }}
{{-   include "apps-utils.leaveScope" $ }}
{{- end }}

{{- define "apps-components.generateConfigMapsAndSecrets" }}
{{-   $ := . }}
{{- /* Loop through containers to generate ConfigMaps and Secrets */ -}}
{{-   range $_, $containersType := list "initContainers" "containers" }}
{{-   include "apps-utils.enterScope" (list $ $containersType) }}
{{-     range $_containerName, $_container := index $.CurrentApp $containersType }}
{{-   include "apps-utils.enterScope" (list $ $_containerName) }}
{{-       if include "fl.isTrue" (list $ . .enabled) }}
{{-         $_ := set . "name" $_containerName }}
{{-         $_ = set $ "CurrentContainer" $_container }}
{{- /* ConfigMaps created by "configFiles:" option */ -}}
{{-   include "apps-utils.enterScope" (list $ "configFiles") }}
{{-         range $configFileName, $configFile := .configFiles }}
{{-           if include "fl.value" (list $ . .content) }}
{{-           include "apps-utils.enterScope" (list $ $configFileName) }}
---
{{- include "apps-utils.printPath" $ }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ print "config-" $containersType "-" $.CurrentApp.name "-" $.CurrentContainer.name "-" $configFileName | include "fl.formatStringAsDNSLabel" | quote }}
  {{- with  include "apps-helpers.generateAnnotations" (list $ .) | trim }}
  {{- . | nindent 2 }}
  {{- end }}
  labels: {{ include "fl.generateLabels" (list $ . $.CurrentApp.name) | trim | nindent 4 }}
data:
  {{ $configFileName | quote }}: | {{ include "fl.value" (list $ . .content) | trim | nindent 4 }}
{{-           include "apps-utils.leaveScope" $ }}
{{-           end }}
{{-         end }}
{{-           include "apps-utils.leaveScope" $ }}
{{- /* Secrets created by "secretConfigFiles:" option */ -}}
{{-         range $secretConfigFileName, $secretConfigFile := .secretConfigFiles }}
{{-           if include "fl.value" (list $ . .content) }}
{{-           include "apps-utils.enterScope" (list $ $secretConfigFileName) }}
---
{{- include "apps-utils.printPath" $ }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ print "config-" $containersType "-" $.CurrentApp.name "-" $.CurrentContainer.name "-" $secretConfigFileName | include "fl.formatStringAsDNSLabel" | quote }}
  {{- with  include "apps-helpers.generateAnnotations" (list $ .) | trim }}
  {{- . | nindent 2 }}
  {{- end }}
  labels: {{ include "fl.generateLabels" (list $ . $.CurrentApp.name) | trim | nindent 4 }}
type: Opaque
data:
  {{ $secretConfigFileName | quote }}: {{ include "fl.value" (list $ . .content) | b64enc | quote }}
{{-           include "apps-utils.leaveScope" $ }}
{{-           end }}
{{-         end }}
{{- /* Secret created by "secretEnvVars:" option */ -}}
{{-         if include "fl.generateSecretEnvVars" (list $ . .secretEnvVars) }}
{{-           include "apps-utils.enterScope" (list $ "secretEnvVars") }}
---
{{- include "apps-utils.printPath" $ }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ print "envs-" $containersType "-" $.CurrentApp.name "-" .name | include "fl.formatStringAsDNSLabel" | quote }}
  {{- with  include "apps-helpers.generateAnnotations" (list $ .) | trim }}
  {{- . | nindent 2 }}
  {{- end }}
  labels: {{ include "fl.generateLabels" (list $ . $.CurrentApp.name) | trim | nindent 4 }}
type: Opaque
data: {{ include "fl.generateSecretEnvVars" (list $ . .secretEnvVars) | trim | nindent 2 }}
{{-   include "apps-utils.leaveScope" $ }}
{{-         end }}
{{-       end }}
{{-   include "apps-utils.leaveScope" $ }}
{{-     end }}
{{-   include "apps-utils.leaveScope" $ }}
{{-   end }}
{{- end }}

{{- define "apps-components.generate-config-checksum" }}
{{-   $ := index . 0 }}
{{-   $RelatedScope := index . 1 }}
  {{- /* Loop through containers to generate Pod volumes */ -}}
{{-   $allConfigMaps := "" }}
{{-   range $_, $containersType := list "initContainers" "containers" }}
{{-     range $_containerName, $_container := index $.CurrentApp $containersType }}
{{- if hasKey . "enabled" }}
{{-       if include "fl.isTrue" (list $ . .enabled) }}
{{-         range $configFileName, $configFile := .configFiles }}
{{-           $allConfigMaps = print $allConfigMaps (include "fl.value" (list $ $RelatedScope $configFile.content)) }}
{{-         end }}
{{-       end }}
{{- else }}
{{-         range $configFileName, $configFile := .configFiles }}
{{-           $allConfigMaps = print $allConfigMaps (include "fl.value" (list $ $RelatedScope $configFile.content)) }}
{{-         end }}
{{- end }}
{{-   end }}

{{-   end }}
{{-   printf "checksum/config: '%s'" ($allConfigMaps | sha256sum) }}
{{- end }}
