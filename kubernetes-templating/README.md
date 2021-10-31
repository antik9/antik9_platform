### Kubernetes templating

#### Запуск кластера kubernetes в Yandex cloud

1. https://cloud.yandex.com/en/docs/managed-kubernetes/quickstart

#### Установка cert-manager

1. Сначала установим nginx-ingress, затем cert-manager
2. Для выпуска сертификатов надо добавить манифест ClusterIssuer, в котором задать metadata.name и spec.acme.email

#### Установка chartmuseum

1. Устанавливаем чарт chartmuseum с заданным конфигом для получения сертификата
2. Проверяем в браузере, что соединение защищено

```bash
$ open https://chartmuseum.62.84.113.62.nip.io/
```

#### Установка harbor

1. Устанавливаем чарт harbor с заданным конфигом для получения сертификата
2. Проверяем в браузере, что соединение защищено

```bash
$ open https://harbor.62.84.113.62.nip.io/
```

#### Hipster Shop Helm Chart

1\. Устанавливаем Hipster Shop из единого чарта

2\. Проверяем работу:

```bash
$ kubectl proxy
$ http://127.0.0.1:8001/api/v1/namespaces/hipster-shop/services/frontend:80/proxy/
```

3\. Создаем отдельный helm чарт для frontend, добавляем ingress с выпуском сертификата

4\. Проверяем работу:

```bash
$ open https://hipster-shop.62.84.113.62.nip.io/
```

5\. Шаблонизируем чарт, вынося конфиги для портов, названия сервиса, количества реплик в _values.yaml_

6\. Добавляем frontend как зависимость для hipster-shop в _Chart.yaml_

7\. * Испольуем community chart для Redis как dependency, проверям, что ничего не сломалось

8\. * Проверяем как работают helm-secrets через gpg шифрование

```bash
$ kubectl get secret secret -n hipster-shop --template={{.data.visibleKey}} | base64 -d
```

9\. Загружаем вручную чарты на harbor, добавляем новый репозиторий в helm:

```bash
$ ./repo.sh
```

10\. Установим Hipster Shop из репозитория и проверим его работу вновь

```bash
helm upgrade --install hipster-shop templating/hispter-shop \
    --wait \
    --namespaces=hipster-shop \
    --version=0.1.0 \
    -f kubernetes-templating/hipster-shop/values.yaml
```

#### Kubecfg

1. Вынесем отдельно paymentservice и shippingservice из манифеста hipster shop
2. Зададим конфиг в формате jsonnet для этих сервисов

```bash
$ kubecfg update services.jsonnet --namespace hipster-shop
```

#### Kustomize

1. Вынесем recommendation service из hipster shop для конфига через kustomize
2. Создаем base и overlay манифесты, запускаем сервис заново:

```bash
$ kubectl apply -k kubernetes-templating/kustomize/overrides/dev
```
