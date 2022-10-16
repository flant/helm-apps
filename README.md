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
     werf helm repo add --force-update  helm-apps https://alvnukov.github.io/helm-apps
  ```
  + к примеру так:
    ```yaml
    before_script:
    - type trdl && source $(trdl use werf ${WERF_VERSION:-1.2 ea})
    - type werf && source $(werf ci-env gitlab --as-file)
    - werf helm repo add --force-update  helm-apps https://alvnukov.github.io/helm-apps
    ```
    у себя на компьютере добавляем репозиторий helm-apps:
    ```yaml
    werf helm repo add --force-update  helm-apps https://alvnukov.github.io/helm-apps
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
* В [values.yaml](docs/example/.helm/values.yaml) отредактировать секцию global._includes с параметрами по умолчанию для хелперов.

На данный момент актуальная документация находится в файле  [tests/.helm/values.yaml](tests/.helm/values.yaml). Ведется дополнительная работа над созданием расширенной версии документации.

[О хелперах]( docs/usage.md)

## Пример простейшего деплоймента Nginx на библиотеке:
<details>
<summary>values.yaml секция приложений</summary>

```yaml
global:
  ci_url: example.com
# ...
apps-stateless:
  # Приложение из примера в документации
  nginx:
    _include: ["apps-stateless-defaultApp"]
    replicas: 1
    containers:
      nginx:
        image:
          name: nginx
        ports: |
          - name: http
            containerPort: 80
        configFiles:
          default.conf:
            mountPath: /etc/nginx/templates/default.conf.template
            content: |
              server {
                listen         80 default_server;
                listen         [::]:80 default_server;
                server_name    {{ $.Values.global.ci_url }} {{ $.Values.global.ci_url }};
                root           /var/www/{{ $.Values.global.ci_url }};
                index          index.html;
                try_files $uri /index.html;
                location / {
                  proxy_set_header Authorization "Bearer ${SECRET_TOKEN}";
                  proxy_pass_header Authorization;
                  proxy_pass https://backend:3000;
                }
              }
        secretEnvVars:
          SECRET_TOKEN: "!!!secret-token-for-backend!!!"
    service:
      enabled: true
      ports: |
        - name: http
          port: 80

apps-ingresses:
  nginx:
    _include: ["apps-ingresses-defaultIngress"]
    host:  '{{ $.Values.global.ci_url }}'
    paths: |
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
    tls:
      enabled: true
```
</details>
<details>
<summary>Сгенерирует следующее...</summary>

```yaml
# Helm Apps Library: apps-stateless.nginx.podDisruptionBudget
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: "nginx"
  labels:
    app: "nginx"
    chart: "tests"
    repo: ""
  annotations:
    project.werf.io/env: ""
    project.werf.io/name: test
    werf.io/version: v1.2.162
spec:
  selector:
    matchLabels:
      app: "nginx"
  maxUnavailable: "15%"
---
# Helm Apps Library: apps-stateless.nginx.containers.nginx.secretEnvVars
apiVersion: v1
kind: Secret
metadata:
  name: "envs-containers-nginx-nginx"
  labels:
    app: "nginx"
    chart: "tests"
    repo: ""
  annotations:
    project.werf.io/env: ""
    project.werf.io/name: test
    werf.io/version: v1.2.162
type: Opaque
data:
  "SECRET_TOKEN": "ISEhc2VjcmV0LXRva2VuLWZvci1iYWNrZW5kISEh"
---
# Helm Apps Library: apps-stateless.nginx.containers.nginx.configFiles.default.conf
apiVersion: v1
kind: ConfigMap
metadata:
  name: "config-containers-nginx-nginx-default-conf"
  labels:
    app: "nginx"
    chart: "tests"
    repo: ""
  annotations:
    project.werf.io/env: ""
    project.werf.io/name: test
    werf.io/version: v1.2.162
data:
  "default.conf": |
    server {
      listen         80 default_server;
      listen         [::]:80 default_server;
      server_name    example.com example.com;
      root           /var/www/example.com;
      index          index.html;
      try_files $uri /index.html;
      location / {
        proxy_set_header Authorization "Bearer ${SECRET_TOKEN}";
        proxy_pass_header Authorization;
        proxy_pass https://backend:3000;
      }
    }
---
# Helm Apps Library: apps-stateless.nginx.service
apiVersion: v1
kind: Service
metadata:
  name: "nginx"
  labels:
    app: "nginx"
    chart: "tests"
    repo: ""
  annotations:
    project.werf.io/env: ""
    project.werf.io/name: test
    werf.io/version: v1.2.162
spec:
  selector:
    app: "nginx"
  ports:
    - name: http
      port: 80
---
# Source: tests/templates/init-flant-apps-library.yaml
# Helm Apps Library: apps-stateless.nginx
apiVersion: apps/v1
kind: Deployment
metadata:
  name: "nginx"
  annotations:
    checksum/config: "19812d5210967fd69097dc991263af171c4071ebb455357bd49be2a0ca05acdd"
    project.werf.io/env: ""
    project.werf.io/name: test
    werf.io/version: v1.2.162
  labels:
    app: "nginx"
    chart: "tests"
    repo: ""
spec:
  strategy:
    rollingUpdate:
      maxSurge: 20%
      maxUnavailable: 50%
    type: RollingUpdate
  template:
    metadata:
      name: "nginx"
      annotations:
        checksum/config: "19812d5210967fd69097dc991263af171c4071ebb455357bd49be2a0ca05acdd"
      labels:
        app: "nginx"
        chart: "tests"
        repo: ""
    spec:
      containers:
        - name: "nginx"
          image: REPO:TAG
          envFrom:
            - secretRef:
                name: "envs-containers-nginx-nginx"
          resources:
          volumeMounts:
            - name: "config-containers-nginx-nginx-default-conf"
              subPath: "default.conf"
              mountPath: "/etc/nginx/templates/default.conf.template"
          ports:
            - name: http
              containerPort: 80
      imagePullSecrets:
        - name: registrysecret
      volumes:
        - name: "config-containers-nginx-nginx-default-conf"
          configMap:
            name: "config-containers-nginx-nginx-default-conf"
  selector:
    matchLabels:
      app: "nginx"
  revisionHistoryLimit: 3
  replicas: 1
---
# Source: tests/templates/init-flant-apps-library.yaml
# Helm Apps Library: apps-ingresses.nginx
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: "nginx"
  annotations:
    kubernetes.io/ingress.class: "nginx"
    project.werf.io/env: ""
    project.werf.io/name: test
    werf.io/version: v1.2.162
  labels:
    app: "nginx"
    chart: "tests"
    repo: ""
spec:
  tls:
    - secretName: nginx
  rules:
    - host: "example.com"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx
                port:
                  number: 80
---
# Helm Apps Library: apps-ingresses.nginx.tls
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: nginx
  annotations:
    project.werf.io/env: ""
    project.werf.io/name: test
    werf.io/version: v1.2.162
spec:
  secretName: nginx
  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt
  dnsNames:
    - "example.com"
---
# Helm Apps Library: apps-stateless.nginx.verticalPodAutoscaler
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: "nginx"
  labels:
    app: "nginx"
    chart: "tests"
    repo: ""
  annotations:
    project.werf.io/env: ""
    project.werf.io/name: test
    werf.io/version: v1.2.162
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: "nginx"
  updatePolicy:
    updateMode: "Off"
  resourcePolicy: {}
```
</details>

Самостоятельно можно отрендерить следующей командой:

```bash
$ cd tests && werf render --dev --set "apps-ingresses.nginx.enabled=true" --set "apps-stateless.nginx.enabled=true"
```
