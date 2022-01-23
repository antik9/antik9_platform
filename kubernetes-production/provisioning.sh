#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

export EDITOR=vi

# disable swap
swapoff -a

# configure routing
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl --system

# install docker
apt update
apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg2

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

apt update
apt install -y containerd.io docker-ce docker-ce-cli

# install kubernetes
apt update
apt install -y apt-transport-https curl

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat > /etc/apt/sources.list.d/kubernetes.list << EOF
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt update
apt install -y kubelet=1.17.4-00 kubeadm=1.17.4-00 kubectl=1.17.4-00
