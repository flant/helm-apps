## Репозиторий библиотеки для развертывания приложений в Kubernetes.
1. Позволяет:
   *  упростить структуру описания приложения.
   *  переиспользовать шаблоны одного приложения для множества других
2. Ускоряет:
   * процесс ревью изменений приложения за счет стандартизирования подхода и уменьшению количества кода.
   * развертывание новых приложений за счет лаконичного синтаксиса, сокращения повторяемого кода
   * редактирование и добавление новых ресурсов к приложению
3. Упрощает:
   * работу с сущностями Kubernetes (не нужно описывать все поля приложения, не нужно думать как правильно выглядит конструкции сущностей).
   * связывание сущностей Kubernetes за счет использования хелперов

>  :warning: **На данный момент корректная работа чартов гарантируется только с утилитой** [**Werf**](https://werf.io)

## Для подключения библиотеки необходимо:
### Инструкция по использованию
#### Использовать пример:
* Скопировать содержимое папки [docs/example](/docs/example) в корень нового проекта
* настроить файлы под свой проект
#### Вручную:
* Добавить в .gitlab-ci.yml строку подключения библиотеки общих чартов
  ```bash
     werf helm repo add --force-update  helm-apps https://flant.github.io/helm-apps
  ```
  + к примеру так:
    ```yaml
    before_script:
    - type trdl && source $(trdl use werf ${WERF_VERSION:-1.2 ea})
    - type werf && source $(werf ci-env gitlab --as-file)
    - werf helm repo add --force-update  helm-apps https://flant.github.io/helm-apps
    ```
    у себя на компьютере добавляем репозиторий helm-apps:
    ```yaml
    werf helm repo add --force-update  helm-apps https://flant.github.io/helm-apps
    ```
    и обновляем зависимости:
    ```yaml
    werf helm dependency update .helm
    ```
* Добавить в папку .helm/templates файл [init-helm-apps.yaml](tests/.helm/templates/init-helm-apps.yaml) для инициализаци библиотеки, содержимое файла:
  ```yaml
    {{- /* Подключаем библиотеку */}}
    {{- include "apps-utils.init-library" $ }}
  ```
* В Chart.yaml в секцию **dependencies**:
  ```yaml
  apiVersion: v2
  name: test-app
  version: 1.0.0
  dependencies:
  - name: helm-apps
    version: ~1
    repository: "@helm-apps"
  ```
* В values.yaml добавить секцию global._includes с параметрами по умолчанию для хелперов и отредактировать их под клиента
  ```yaml
  global:
  ## Альтернатива ограниченным yaml-алиасам Helm'а. Даёт возможность не дублировать одну и ту же конфигурацию много раз.
  #
  # Здесь, в "global._includes", объявляются блоки конфигурации, которые потом можно использовать в любых values-файлах.
  # Пример подтягивания этих блоков конфигурации в репозитории приложения:
  # -----------------------------------------------------------------------------------------------
  # .helm/values.yaml:
  # -----------------------------------------------------------------------------------------------
  # apps-cronjobs:
  #   cronjob-1:
  #     _include: ["apps-cronjobs-defaultCronJob"]
  #     backoffLimit: 1
  # -----------------------------------------------------------------------------------------------
  #
  # В примере выше конфигурация из include-блока "apps-cronjobs-defaultCronJob" развернётся на уровне
  # apps-cronjobs.cronjob-1, а потом поверх развернувшейся конфигурации применится параметр "backoffLimit: 1",
  # при необходимости перезаписав параметр "backoffLimit" из include-блока.
  #
  # Подробнее: https://github.com/flant/helm-charts/tree/master/.helm/charts/flant-lib#flexpandincludesinvalues-function
  _includes:
    apps-defaults:
      enabled: false
    apps-default-library-app:
      _include: ["apps-defaults"]
      # CLIENT: ask if this is ok for a defaul
      imagePullSecrets: |
        - name: registrysecret
    ## Конфигурация по умолчанию для CronJob в целом.
    apps-cronjobs-defaultCronJob:
      _include: ["apps-default-library-app"]
      concurrencyPolicy: "Forbid"
      successfulJobsHistoryLimit: 1
      failedJobsHistoryLimit: 1
      backoffLimit: 0
      priorityClassName:
        prod: "production-high"
      restartPolicy: "Never"
      startingDeadlineSeconds: 60
      verticalPodAutoscaler:
        enabled: true
        updateMode: "Off"
        resourcePolicy: |
          {}

    apps-secrets-defaultSecret:
      _include: ["apps-defaults"]

    apps-ingresses-defaultIngress:
      _include: ["apps-defaults"]
      class: "nginx"

    apps-jobs-defaultJob:
      _include: ["apps-default-library-app"]
      backoffLimit: 0
      priorityClassName:
        prod: "production-high"
      restartPolicy: "Never"
      verticalPodAutoscaler:
        enabled: true
        updateMode: "Off"
        resourcePolicy: |
          {}

    apps-stateful-defaultApp:
      _include: ["apps-default-library-app"]
      revisionHistoryLimit: 3
      terminationGracePeriodSeconds:
        _default: 30
        prod: 60
        rspec: 3
      affinity: |
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - podAffinityTerm:
              labelSelector:
                matchLabels: {{ include "fl.generateSelectorLabels" (list $ . .name) | nindent 22 }}
              topologyKey: kubernetes.io/hostname
            weight: 10
      priorityClassName:
        prod: "production-medium"
      podDisruptionBudget:
        enabled: true
        maxUnavailable: "15%"
      verticalPodAutoscaler:
        enabled: true
        updateMode: "Off"
      service:
        enabled: false
        name: "{{ $.CurrentApp.name }}"
        headless: true

    apps-stateless-defaultApp:
      _include: ["apps-default-library-app"]
      revisionHistoryLimit: 3
      strategy:
        _default: |
          rollingUpdate:
            maxSurge: 20%
            maxUnavailable: 50%
          type: RollingUpdate
        prod: |
          rollingUpdate:
            maxSurge: 20$
            maxUnavailable: 25%
          type: RollingUpdate
      priorityClassName:
        prod: "production-medium"
      podDisruptionBudget:
        enabled: true
        maxUnavailable: "15%"
      verticalPodAutoscaler:
        enabled: true
        updateMode: "Off"
        resourcePolicy: |
          {}
      horizontalPodAutoscaler:
        enabled: false
      service:
        enabled: false
        name: "{{ $.CurrentApp.name }}"
        headless: true

    apps-configmaps-defaultConfigmap:
      _include: ["apps-defaults"]
  ```

На данный момент актуальная документация находится в файле  [tests/.helm/values.yaml](tests/.helm/values.yaml). Ведется дополнительная работа над созданием расширенной версии документации.

[О хелперах]( docs/usage.md)
