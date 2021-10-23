1\. Применяем манифесты для StatefulSet и HeadlessService

2\. Устанавливаем в другом поде утилиту [mc](https://github.com/minio/mc). Проверяем работу:

```bash
$ mc mc alias set minio http://<MINIO_POD_IP>:9000 minio minio123
$ mc cp file minio/test/file
$ mc cat minio/test/file
```

3\. Добавляем манифест с секретами (не коммитим его в публичном репозитории, находящийся здесь манифест является примером). Проверяем еще раз, что все работает через утилите `mc`
