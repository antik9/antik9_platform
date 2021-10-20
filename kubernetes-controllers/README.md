### Kubernetes Controllers

#### Frontend Replicaset

1. Добавлен манифест для fronent ReplicaSet
2. Проверено, что при обновление образа новые поды не рестартятся из-за того, что количество уже запущенных подов заматченных по лейблам соответствует ожиданию. Для рестарта нужно удалить старые поды.

#### Payment Service Deployment

1. Добавлен манифест c типом Deployment для paymentservice
2. Добавлены дополнительные манифесты:
 - Blue-Green с конфигурацией (maxSurge: 100%, maxUnavailable: 0)
 - Reverse Rolluing Update с конфигурацией (maxSurge: 0, maxUnavailable: 1)

#### Frontend Server Deployment

1. Добавлен манифест c типом Deployment для frontend
2. Добавлена readinessProbe для проверки готовности сервиса

#### Node Exported DaemonSet

1. За основу взят конфиг из статьи [__How to Setup Prometheus Node Exporter on Kubernetes__](https://devopscube.com/node-exporter-kubernetes/)
2. Для запуска node-exporter на master ноде добавлен tolerations c key=node-role.kubernetes.io/master
