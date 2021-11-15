### Kubernetes logging

#### Запуск кластера kubernetes в Yandex Cloud

1. https://cloud.yandex.com/en/docs/managed-kubernetes/quickstart
2. Делаем три ноды с taint `node-role=infra:NoSchedule` и одну обычную

```bash
$ kubectl get nodes

NAME                        STATUS   ROLES    AGE     VERSION
cl10205chvnk6ggnegn0-irag   Ready    <none>   2m17s   v1.20.11
cl10205chvnk6ggnegn0-ybop   Ready    <none>   118s    v1.20.11
cl10205chvnk6ggnegn0-ynup   Ready    <none>   96s     v1.20.11
cl1ddmq2lpn21dca87pg-ocal   Ready    <none>   152m    v1.20.11
```

#### Разворачиваем hipster-shop

1\. Создаем Namespace и запускаем готовый манифест

```bash
$ kubectl create ns microservices-demo
$ kubectl apply -f https://raw.githubusercontent.com/express42/otus-platformsnippets/master/Module-02/Logging/microservices-demo-without-resources.yaml -n microservices-demo
$ kubectl get pods -n microservices-demo -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName

NAME                                     NODE
adservice-56d56d89cc-rhzqc               cl1ddmq2lpn21dca87pg-ocal
cartservice-c8b9fc586-l85mm              cl1ddmq2lpn21dca87pg-ocal
checkoutservice-74f4c5464f-7sdb8         cl1ddmq2lpn21dca87pg-ocal
currencyservice-7df4d74b7c-pwhtm         cl1ddmq2lpn21dca87pg-ocal
emailservice-86794489df-6z5dd            cl1ddmq2lpn21dca87pg-ocal
frontend-cf49f7975-2985s                 cl1ddmq2lpn21dca87pg-ocal
loadgenerator-7fdb874b-2khc4             cl1ddmq2lpn21dca87pg-ocal
paymentservice-5768d9bb67-scgq8          cl1ddmq2lpn21dca87pg-ocal
productcatalogservice-84fd74ccc9-fcx8f   cl1ddmq2lpn21dca87pg-ocal
recommendationservice-6fcb597467-nmdfm   cl1ddmq2lpn21dca87pg-ocal
redis-cart-55d76945cb-px6fc              cl1ddmq2lpn21dca87pg-ocal
shippingservice-6bc75ffff-lb2pl          cl1ddmq2lpn21dca87pg-ocal
```

#### Разворачиваем EFK stack

1\. Кастомизируем elasticsearch.values.yaml, запускаем deploy ElasticSearch

```bash
$ kubectl create ns observability
$ helm upgrade --install elasticsearch elastic/elasticsearch \
    --namespace observability \
    -f elasticsearch.values.yaml
$ kubectl get pods -n observability -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName

NAME                     NODE
elasticsearch-master-0   cl10205chvnk6ggnegn0-ybop
elasticsearch-master-1   cl10205chvnk6ggnegn0-irag
elasticsearch-master-2   cl10205chvnk6ggnegn0-ynup
```

2\. Устанавливаем ingress на infra ноды

```bash
$ kubectl create ns nginx-ingress
$ helm upgrade --install nginx-ingress stable/nginx-ingress --wait \
    --namespace=nginx-ingress \
    --version=1.41.3 \
    -f nginx-ingress.values.yaml
```

3\. Устанавливаем kibana и даем доступ к ней через ingress

```bash
$ helm upgrade --install kibana elastic/kibana \
    --namespace observability \
    -f kibana.values.yaml
$ curl -I http://kibana.51.250.9.1.nip.io/app/home | grep OK

HTTP/1.1 200 O
```

4\. Устанавливаем fluent-bit и делаем так, чтобы он смотрел на elasticsearch

```bash
$ helm upgrade --install fluent-bit stable/fluent-bit \
    --namespace observability \
    -f fluent-bit.values.yaml
```

5\. Устанавливаем prometheus-operator на infra нодах

```bash
$ helm upgrade --install prometheus-operator stable/prometheus-operator \
    --namespace=observability \
    -f prometheus-operator.values.yaml
```

6\. Устанавливаем prometheus exporter для мониторинга ElasticSearch

```bash
$ helm upgrade --install elasticsearch-exporter stable/elasticsearch-exporter \
    --set es.uri=http://elasticsearch-master:9200 \
    --set serviceMonitor.enabled=true \
    --namespace=observability
```

7\. Порверяем [дашборд](http://grafana.51.250.9.1.nip.io/d/PbEt0b5nz/elasticsearch?orgId=1&refresh=1m) ElasticSearch exporter

8\. Настраиваем дашборд в Kibana:

 - Добавляем index pattern для нашего хоста
 - Правим конфиг NGINX, чтобы он отдавался в JSON
 - Добавляем графики со status на [дашборд](http://kibana.51.250.9.1.nip.io/app/dashboards#/view/aeefbe00-456a-11ec-b0b3-2f00f22a4423)

9\. Разворачиваем Loki

```bash
$ helm repo add loki https://grafana.github.io/loki/charts
$ helm upgrade --install loki loki/loki-stack \
    --namespace=observability \
    -f loki.yaml
```

10\. Делаем [дашборд](http://grafana.51.250.9.1.nip.io/d/8vz7abc7z/nginx-loki?orgId=1&from=now-1h&to=now) в графане для Nginx с логами
