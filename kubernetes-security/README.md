### Kubernetes security

#### Task #1

1. Добавлены ServiceAccount для bob и dave
2. Добавлен ClusterRoleBinding "admin" для bob

#### Task #2

1. Добавлен Namespace "prometheus" и ServiceAccount "carol"
2. Добавлена роль "pod-reader" с необходимыми правами
3. Добавлен ClusterRoleBinding с созданной ролью для всех ServiceAccount в Namespace "prometheus"

#### Task #3

1. Добавлен Namespace "dev" и ServiceAccount "jane" и "ken"
2. Добавлены RoleBinding для аккаунтов с правами "admin" и "view" соответственно
