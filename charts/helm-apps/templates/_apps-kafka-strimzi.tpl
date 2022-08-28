{{- define "apps-kafka-strimzi" }}
  {{- $ := index . 0 }}
  {{- $RelatedScope := index . 1 }}
    {{- if not (kindIs "invalid" $RelatedScope) }}
  {{- $_ := set $RelatedScope "__GroupVars__" (dict "type" "apps-kafka-strimzi" "name" "apps-kafka-strimzi") }}
  {{- include "apps-utils.renderApps" (list $ $RelatedScope) }}
{{- end -}}
{{- end -}}

{{- define "apps-kafka-strimzi.render"}}
  {{- $ := index . }}
  {{- $_ := set $ "CurrentKafka" $.CurrentApp }}
  {{- with $.CurrentApp }}
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: {{ $.CurrentKafka.name }}-{{ $.Values.global.env }}
spec:
  kafkaExporter:
    groupRegex: ".*"
    topicRegex: ".*"
    resources:  {{- include "fl.generateContainerResources" (list $ . .exporter.resources) | nindent 6 }}
    template:
      pod:
        metadata:
          labels:
            prometheus.deckhouse.io/custom-target: kafka-exporter
          annotations:
            prometheus.deckhouse.io/port: "9404"
            prometheus.deckhouse.io/sample-limit: "{{ include "fl.value" (list $ . .prometheusSampleLimit) | default 10000 }}"
            {{- include "fl.value" (list $ . .annotations) | nindent 12 }}
        {{- with .exporter.tolerations }}
        tolerations: {{ include "fl.value" (list $ $.CurrentApp .) | nindent 8 }}
        {{- end }}
        {{- with .exporter.affinity }}
        affinity: {{ include "fl.value" (list $ . .) | nindent 10 }}
        {{- end }}
  kafka:
    version: {{ include "fl.value" (list $ . .version) }}
    replicas: {{ include "fl.value" (list $ . .replicas) }}
    resources: {{ include "fl.generateContainerResources" (list $ . .resources) | nindent 6 }}
    jvmOptions: {{ include "fl.value" (list $ . .jvmOptions ) | nindent 6 }}
    listeners:
    - name: plain
      port: 9092
      type: internal
      tls: false
    - name: tls
      port: 9093
      type: internal
      tls: true
    template:
      pod:
        metadata:
          labels:
            prometheus.deckhouse.io/custom-target: kafka
          annotations:
            prometheus.deckhouse.io/port: "9404"
            prometheus.deckhouse.io/sample-limit: "{{ include "fl.value" (list $ . .prometheusSampleLimit) | default 50000 }}"
        priorityClassName: {{ include "fl.valueQuoted" (list $ . .priorityClassName) }}
        {{- with .tolerations }}
        tolerations: {{ include "fl.value" (list $ $.CurrentApp .) | nindent 8 }}
        {{- end }}
        {{- with .affinity }}
        affinity: {{ include "fl.value" (list $ $.CurrentApp .) | nindent 10 }}
          podAntiAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
            - topologyKey: "kubernetes.io/hostname"
              labelSelector:
                matchLabels:
                  strimzi.io/name: {{ $.CurrentKafka.name }}-{{ $.Values.global.env }}-kafka
        {{- end }}
        terminationGracePeriodSeconds: 120
    metricsConfig:
      type: jmxPrometheusExporter
      valueFrom:
        configMapKeyRef:
          name: kafka-metrics
          key: kafka-metrics-config.yml
    config:
      auto.create.topics.enable: "false"
      offsets.topic.replication.factor: 1
      transaction.state.log.replication.factor: 1
      transaction.state.log.min.isr: 1
      log.message.format.version: "2.7"
      inter.broker.protocol.version: "2.7"
    storage:
      type: jbod
      volumes:
      - id: 0
        type: persistent-claim
        size: {{ include "fl.value" (list $ . .storage.size) }}
        class: {{ include "fl.value" (list $ . .storage.class) }}
        deleteClaim: false
  zookeeper:
    priorityClassName: {{ include "fl.valueQuoted" (list $ . .priorityClassName) }}
    replicas: {{ include "fl.value" (list $ . .zookeeper.replicas) }}
    resources: {{ include "fl.generateContainerResources" (list $ . .zookeeper.resources) | nindent 6 }}
    template:
      pod:
        metadata:
          labels:
            prometheus.deckhouse.io/custom-target: zookeeper
          annotations:
            prometheus.deckhouse.io/port: "9404"
            prometheus.deckhouse.io/sample-limit: "{{ include "fl.value" (list $ . .prometheusSampleLimit) | default 5000 }}"
        {{- with .zookeeper.tolerations }}
        tolerations: {{ include "fl.value" (list $ $.CurrentApp .) | nindent 8 }}
        {{- end }}
        priorityClassName: {{ include "fl.valueQuoted" (list $ . .priorityClassName) }}
        affinity:
          {{- include "fl.value" (list $ $.CurrentApp .zookeeper.affinity) | nindent 10 }}
          podAntiAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
            - topologyKey: "kubernetes.io/hostname"
              labelSelector:
                matchLabels:
                  strimzi.io/name: {{ $.CurrentKafka.name }}-{{ $.Values.global.env }}-zookeeper
        terminationGracePeriodSeconds: 120
    metricsConfig: {{ include "fl.value" (list $ . .zookeeper.metricsConfig) | nindent 6 }}
    jvmOptions: {{ include "fl.value" (list $ . .zookeeper.jvmOptions) | nindent 6 }}
    storage:
      type: persistent-claim
      size: {{ include "fl.value" (list $ . .zookeeper.storage.size) }}
      class: {{ include "fl.value" (list $ . .zookeeper.storage.class) }}
      deleteClaim: false
  entityOperator:
    priorityClassName: {{ include "fl.valueQuoted" (list $ . .priorityClassName) }}
    template:
      pod:
        metadata:
          labels:
            apps-kafka-strimzi: entity-operator
        priorityClassName: {{ include "fl.valueQuoted" (list $ . .priorityClassName) }}
        {{- with .entityOperator.tolerations }}
        tolerations: {{ include "fl.value" (list $ $.CurrentApp .) | nindent 8 }}
        {{- end }}
        {{- with .entityOperator.affinity }}
        affinity: {{ include "fl.value" (list $ $.CurrentApp .) | nindent 10 }}
        {{- end }}
    topicOperator:
      resources: {{ include "fl.generateContainerResources" (list $ . .entityOperator.topicOperator.resources) | nindent 8 }}
    userOperator:
      resources: {{ include "fl.generateContainerResources" (list $ . .entityOperator.userOperator.resources) | nindent 8 }}

{{- include "kafka-topics" (list $ . .topics) }}

---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: {{ $.CurrentKafka.name }}-{{ $.Values.global.env }}-kafka
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: StatefulSet
    name: {{ $.CurrentKafka.name }}-{{ $.Values.global.env }}-kafka
  updatePolicy:
    updateMode: "Off"

---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: {{ $.CurrentKafka.name }}-{{ $.Values.global.env }}-zookeeper
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: StatefulSet
    name: {{ $.CurrentKafka.name }}-{{ $.Values.global.env }}-zookeeper
  updatePolicy:
    updateMode: "Off"

---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: {{ $.CurrentKafka.name }}-{{ $.Values.global.env }}-entity-operator
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: {{ $.CurrentKafka.name }}-{{ $.Values.global.env }}-entity-operator
  updatePolicy:
    updateMode: "Off"

---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: {{ $.CurrentKafka.name }}-{{ $.Values.global.env }}-kafka-exporter
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: {{ $.CurrentKafka.name }}-{{ $.Values.global.env }}-kafka-exporter
  updatePolicy:
    updateMode: "Off"


{{- end }}
{{- end }}

{{- define "kafka-topics"}}
  {{- $ := index . 0 }}
  {{- $relativeScope := index . 1 }}
  {{- $topics := index . 2 }}
{{- range $name, $topic :=  $topics }}
---
apiVersion: kafka.strimzi.io/v1beta1
kind: KafkaTopic
metadata:
  name: {{ $name }}
  labels:
    strimzi.io/cluster: {{ $.CurrentApp.name }}-{{ $.Values.global.env }}
spec:
  topicName: {{ $name }}
  partitions: {{ include "fl.value" (list $ . .partitions) }}
  replicas: {{  include "fl.value" (list $ . .replicas) }}
  config:
    retention.ms: {{  include "fl.value" (list $ . .retention) }}
    segment.bytes: {{  include "fl.value" (list $ . .segment_bytes) }}
    min.insync.replicas: {{  include "fl.value" (list $ . .min_insync_replicas) }}
{{- end }}
{{- end }}

