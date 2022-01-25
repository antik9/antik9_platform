### Kubernetes production

1\. Run on nodes

```
$ ./provisioning.sh
```

2\. Master node:

```
$ kubeadm init --pod-network-cidr=192.168.0.0/24
```

3\. Worker nodes:

```
$ kubeadm join <host:port> --token <token> --discovery-token-ca-cert-hash <hash>
```

4\. Deploy with kubespray

```
$ git clone https://github.com/kubernetes-sigs/kubespray.git
$ cp -rfp inventory/sample inventory/mycluster
$ ansible-playbook -i inventory/mycluster/inventory.ini --become --become-user=root \
    --user=${SSH_USERNAME} --key-file=${SSH_PRIVATE_KEY} cluster.yml
```
