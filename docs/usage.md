# Инструкции по использованию хелперов

* Любой параметр хелпера может иметь разные значения для разных окружений:
    ```yaml
    revisionHistoryLimit: 3   # Для всех окружений значение будет одно.

    revisionHistoryLimit:
      _default: 3   # То же самое, что и выше.

    revisionHistoryLimit:
      _default: 3   # Значение по умолчанию для всех окружений.
      some_other_env: 5   # Но для этого окружения значение другое.
    ```
  [Подробнее здесь](https://github.com/flant/helm-charts/tree/master/.helm/charts/flant-lib#flvalue-function).

* Любой параметр хелпера можно шаблонизировать:
    ```yaml
    apps-stateless:
      app-1:
        service:
          name: "{{ $.CurrentApp.name | trim 15 }}"
    ```
  [Подробнее здесь](https://github.com/flant/helm-charts/tree/master/.helm/charts/flant-lib#flvalue-function).

* Все компоненты могут включаться/выключаться ключом `enabled`:
    ```yaml
    apps-stateless:
      app-1:
        service:
          enabled: true
          ...
        horizontalPodAutoscaler:
          enabled: true
          ...
    ```
* Можно создать несколько ресурсов одного типа (если в документации к параметру это допускается):
    ```yaml
    # Содержит список приложений. Можно указывать несколько.
    apps-stateless:
      app-1:   # Создать первое приложение.
        ...
      app-2:   # Создать второе приложение.
        ...
    ```
* Структура `values.yaml` повторяет структуру Kubernetes-ресурсов насколько возможно, в том числе нейминг старался сохранять тем же. Т. е. если вам кажется, что `command` в `values.yaml` — это то, что пробросится в `command` контейнера, то скорее всего так и есть.
* Если в `values.yaml` [multiline-строкой](https://lzone.de/cheat-sheet/YAML#yaml-heredoc-multiline-strings) пробрасывается список или словарь (`command: | ...`), то это значит, что этот блок вставится в манифест Kubernetes-ресурса *без преобразований*. Такие параметры обязательно пробрасывать именно строкой, содержащей в себе список или словарь. Также для подобных параметров поддерживается только YAML-стиль оформления списков и словарей, но не JSON-стиль. Пример:
    ```yaml
    # Верно:
    command: |
      - echo

    # Неверно:
    command:
      - echo
    command: ["echo"]
    command: |
      ["echo"]

    # Верно:
    annotations: |
      key: value

    # Неверно:
    annotations:
      key: value
    annotations: {"key": "value"}
    annotations: |
      {"key": "value"}
    ```
* Логика отделена от конфигурации: вся логика находится в шаблонах хелпера ([пример](../charts/helm-apps/templates/)), вся конфигурация по умолчанию находится в `values.yaml` в секции global._includes, а вся актуальная конфигурация приложения находится в `.helm/values.yaml` в репозитории приложения. В репозитории приложения обычно шаблонов быть не должно(кроме шаблона подключения библиотеки), только конфигурация в `.helm/values.yaml` и `.helm/secret-values.yaml`.
* Дублирование конфигурации минимизировано за счет специального хелпера, реализующего более мощную альтернативу YAML-алисам. Подробнее смотрите в файлах `values.yaml` .
