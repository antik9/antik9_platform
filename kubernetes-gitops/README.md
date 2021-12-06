### Kubernetes GitOps 

#### [Repo](https://gitlab.com/antik9/microservices-demo)

1\. Копируем helm чарты из [демонстрационного репозитория](https://gitlab.com/express42/kubernetes-platform-demo/microservices-demo/)

2\. Добавляем build and push образов в [pipeline](https://gitlab.com/antik9/microservices-demo/-/blob/master/ci/build-images-ci.yml)

3\. Устанавливаем HelmRelease и Flux:

```bash
$ kubectl apply -f "https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml"
$ kubectl create ns flux
$ helm upgrade --install flux fluxcd/flux -f flux.values.yaml --namespace flux
```

4\. Устанваливаем helm operator:

```bash
$ helm upgrade --install helm-operator fluxcd/helm-operator -f helmoperator.values.yaml --namespace flux
```

5\. Деплоим namespace и release для frontend. Проверяем, что flux [автоматически коммитит новые теги для релизов](https://gitlab.com/antik9/microservices-demo/-/commit/c1243e099e64fab154de15504735c3cd221d5e6d)

6\. Проверяем, как flux меняет deployment при переименовании:

```
ts=2021-12-05T20:47:20.662327409Z caller=helm.go:69 component=helm version=v3 info="creating upgraded release for frontend" targetNamespace=microservices-demo release=frontend
ts=2021-12-05T20:47:20.675869013Z caller=helm.go:69 component=helm version=v3 info="checking 5 resources for changes" targetNamespace=microservices-demo release=frontend
ts=2021-12-05T20:47:20.686031806Z caller=helm.go:69 component=helm version=v3 info="Looks like there are no changes for Service \"frontend\"" targetNamespace=microservices-demo release=frontend
ts=2021-12-05T20:47:20.697060725Z caller=helm.go:69 component=helm version=v3 info="Created a new Deployment called \"frontend-hipster\" in microservices-demo\n" targetNamespace=microservices-demo release=frontend
ts=2021-12-05T20:47:20.836358969Z caller=helm.go:69 component=helm version=v3 info="Deleting \"frontend\" in microservices-demo..." targetNamespace=microservices-demo release=frontend
ts=2021-12-05T20:47:20.854703052Z caller=helm.go:69 component=helm version=v3 info="updating status for upgraded release for frontend" targetNamespace=microservices-demo release=frontend
```

7\. Устанавливаем [Istio](https://istio.io/latest/docs/setup/install/helm/), Prometheus и Flagger

```bash
$ kubectl apply -f "https://raw.githubusercontent.com/fluxcd/flagger/main/charts/flagger/crds/crd.yaml"
$ kubectl create namespace istio-system
$ helm install istio-base istio/base -n istio-system
$ helm install istiod istio/istiod -n istio-system --wait
$ kubectl create ns istio-ingress
$ kubectl label namespace istio-ingress istio-injection=enabled
$ helm install istio-ingress istio/gateway -n istio-ingress --wait
$ helm upgrade --install prometheus prometheus-community/prometheus --namespace=istio-system
$ helm upgrade --install flagger flagger/flagger \
    --namespace=istio-system \
    --set crd.create=false \
    --set meshProvider=istio \
    --set metricsServer=http://prometheus-server:80
```

8\. Добавялем Gateway и VirtualService для frontend. Проверяем, что есть доступ снаружи к сервису

```bash
$ curl http://51.250.6.235/
```

9\. Деплоим canary для frontend, проверяем, что работает loadgenerator для сервиса. Результат:

```bash
$ kubectl get canaries -n microservices-demo
NAME       STATUS      WEIGHT   LASTTRANSITIONTIME
frontend   Succeeded   0        2021-12-06T15:45:15Z

$ kubectl describe canary -n microservices-demo frontend
Name:         frontend
Namespace:    microservices-demo
Labels:       app.kubernetes.io/managed-by=Helm
Annotations:  helm.fluxcd.io/antecedent: microservices-demo:helmrelease/frontend
              meta.helm.sh/release-name: frontend
              meta.helm.sh/release-namespace: microservices-demo
API Version:  flagger.app/v1beta1
Kind:         Canary
Metadata:
  Creation Timestamp:  2021-12-06T15:34:12Z
  Generation:          2
  Managed Fields:
    API Version:  flagger.app/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .:
          f:meta.helm.sh/release-name:
          f:meta.helm.sh/release-namespace:
        f:labels:
          .:
          f:app.kubernetes.io/managed-by:
      f:spec:
        .:
        f:analysis:
          .:
          f:maxWeight:
          f:stepWeight:
          f:threshold:
        f:progressDeadlineSeconds:
        f:provider:
        f:service:
          .:
          f:gateways:
          f:hosts:
          f:port:
          f:retries:
            .:
            f:attempts:
            f:perTryTimeout:
            f:retryOn:
          f:targetPort:
          f:trafficPolicy:
            .:
            f:tls:
              .:
              f:mode:
        f:targetRef:
          .:
          f:apiVersion:
          f:kind:
          f:name:
    Manager:      helm-operator
    Operation:    Update
    Time:         2021-12-06T15:34:12Z
    API Version:  flagger.app/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          f:helm.fluxcd.io/antecedent:
    Manager:      kubectl
    Operation:    Update
    Time:         2021-12-06T15:34:12Z
    API Version:  flagger.app/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:spec:
        f:service:
          f:portDiscovery:
      f:status:
        .:
        f:canaryWeight:
        f:conditions:
        f:failedChecks:
        f:iterations:
        f:lastAppliedSpec:
        f:lastTransitionTime:
        f:phase:
        f:trackedConfigs:
    Manager:      flagger
    Operation:    Update
    Time:         2021-12-06T15:35:16Z
    API Version:  flagger.app/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          f:kubectl.kubernetes.io/last-applied-configuration:
      f:spec:
        f:analysis:
          f:interval:
          f:metrics:
    Manager:         kubectl-client-side-apply
    Operation:       Update
    Time:            2021-12-06T15:49:48Z
  Resource Version:  538804
  UID:               1b160a2f-edeb-49e9-955d-b643973d1bc5
Spec:
  Analysis:
    Interval:    5m
    Max Weight:  30
    Metrics:
      Interval:               5m
      Name:                   request-success-rate
      Threshold:              90
    Step Weight:              10
    Threshold:                10
  Progress Deadline Seconds:  60
  Provider:                   istio
  Service:
    Gateways:
      frontend-gateway
    Hosts:
      *
    Port:  80
    Retries:
      Attempts:         3
      Per Try Timeout:  1s
      Retry On:         gateway-error,connect-failure,refused-stream
    Target Port:        8080
    Traffic Policy:
      Tls:
        Mode:  DISABLE
  Target Ref:
    API Version:  apps/v1
    Kind:         Deployment
    Name:         frontend
Status:
  Canary Weight:  0
  Conditions:
    Last Transition Time:  2021-12-06T15:45:15Z
    Last Update Time:      2021-12-06T15:45:15Z
    Message:               Canary analysis completed successfully, promotion finished.
    Reason:                Succeeded
    Status:                True
    Type:                  Promoted
  Failed Checks:           1
  Iterations:              0
  Last Applied Spec:       659ffdbc46
  Last Transition Time:    2021-12-06T15:45:15Z
  Phase:                   Succeeded
  Tracked Configs:
Events:
  Type     Reason  Age                From     Message
  ----     ------  ----               ----     -------
  Warning  Synced  23m                flagger  frontend-primary.microservices-demo not ready: waiting for rollout to finish: observed deployment generation less than desired generation
  Normal   Synced  22m (x2 over 23m)  flagger  all the metrics providers are available!
  Normal   Synced  22m                flagger  Initialization done! frontend.microservices-demo
  Normal   Synced  20m                flagger  New revision detected! Scaling up frontend.microservices-demo
  Normal   Synced  19m                flagger  New revision detected! Restarting analysis for frontend.microservices-demo
  Normal   Synced  18m                flagger  Starting canary analysis for frontend.microservices-demo
  Normal   Synced  18m                flagger  Advance frontend.microservices-demo canary weight 10
  Warning  Synced  17m                flagger  Halt advancement no values found for istio metric request-success-rate probably frontend.microservices-demo is not receiving traffic: running query failed: no values found
  Normal   Synced  16m                flagger  Advance frontend.microservices-demo canary weight 20
  Normal   Synced  15m                flagger  Advance frontend.microservices-demo canary weight 30
  Normal   Synced  14m                flagger  Copying frontend.microservices-demo template spec to frontend-primary.microservices-demo
  Normal   Synced  12m (x2 over 13m)  flagger  (combined from similar events): Promotion completed! Scaling down frontend.microservices-demo
```
