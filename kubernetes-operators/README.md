### Kubernetes-Operators

1\. Создаем CustomResourceDefinition и MySQL манифесты

2\. Описываем контроллер на основе библиотеки `kopf`

3\. Создаем образ с оператором, `antik9/mysql-operator:0.1`

4\. Деплом оператор в кластер

5\. Создаем MySQL, Записываем данные в БД, удалем MySQL, поднимамем вновь, ждем restore. Проверяем работу:

```
$ kubects get job
NAME                         COMPLETIONS   DURATION   AGE
backup-mysql-instance-job    1/1           2s         4m59s
restore-mysql-instance-job   1/1           51s        4m42s
$ export MYSQLPOD=(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
$ kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "SELECT * FROM test" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
```
