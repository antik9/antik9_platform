### Kubernetes Networks

#### Probes for Web pod

1. Запущен web pod с проверкой на readiness and liveness
2. Проверка на liveness через `sh -c ...` не имеет смысла, так как по завершению основого процесса, контейнер должен запуститься заново. Liveness probe же существует для того, чтобы проверять не стоит ли перезапустить контейнер.
3. Вероятно, такая команда может быть полезна, если у нас запущено больше одного процесса в контейнере

#### MetalLB manifest

1\. Использовал более новую версию MetalLB, со старой возникли проблемы:

```bash
$ kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.3/manifests/namespace.yaml
$ kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.3/manifests/metallb.yaml
```

2\. Задеплоен ConfigMap и LoadBalancer Service

3\. Проверен маршрут via minikube в браузере:

```bash
$ sudo ip route add 172.17.255.0/24 via 192.168.99.100
```

4\. Добавлени LoadBalancer для `opendns`
 - Для работы использована аннотация `metallb.universe.tf/allow-shared-ip: opendns`
 - Проверка работы через UDP/TCP:

 ```bash
$ dig +tcp web-svc-lb.default.svc.cluster.local @172.17.255.5
$ dig +notcp web-svc-lb.default.svc.cluster.local @172.17.255.5
 ```

#### Ingress manifest

1\. Добавлен основной манифест, Ingress LoadBalancer, Headless Service

2\. Манифест для ingress оказался outdated, сделаны правки для новой версии на основе [комментария к issue](https://github.com/kubernetes/kubernetes/issues/90077#issuecomment-768423075)

3\. Дальше возникла проблема с тем, что не присваивался адрес, пришлось заглянуть в логи ingress-controller

```
I1022 16:40:42.026264       8 store.go:367] "Ignoring ingress because of error while validating ingress class ingress="default/web" error="ingress does not contain a valid IngressClass"
```

4\. 🎉 Проблема решилась благодаря прописанному `kubernetes.io/ingress.class: nginx`

```
$ curl "http://172.17.0.2/web/index.html"
```

#### Dashboard Ingress

1\. Деплой [манифеста для дашборда](https://github.com/kubernetes/dashboard#install):

```bash
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml
```

2\. Дополнительно добавлены правила для rewrite-target и изменен backend-protocol на "HTTPS"


#### Canary Ingress

1\. Добавлен манифесты для запуска ингресса:

```bash
$ tree
canary
├── canary-ingress.yaml
├── web-deploy-canary.yaml
└── web-svc-main.yaml
$ kubectl apply -f canary/web-deploy-canary.yaml
$ kubectl apply -f canary/web-svc-main.yaml
$ kubectl apply -f canary/canary-ingress.yaml
```

2\. Проверка работы:

```bash
$ curl -H "canary: always" "http://172.17.255.2/web/index.html"  # canary release
$ curl -H "canary: never" "http://172.17.255.2/web/index.html"   # main release
```
