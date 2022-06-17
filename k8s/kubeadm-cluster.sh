#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

[[ -z "${MY_SHELL_SCRIPTS}" ]] && MY_SHELL_SCRIPTS="$HOME/.dotfiles"

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS}/custom_functions.sh does not exist!"
        exit 0
    fi
fi


if [[ ! -x "$(command -v kubeadm)" ]]; then
    [[ -s "${MY_SHELL_SCRIPTS}/k8s/kubeadm_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/k8s/kubeadm_installer.sh"
fi

[[ ! -x "$(command -v kubeadm)" ]] && colorEcho "${FUCHSIA}kubeadm${BLUE} is not installed!" && exit 1


[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type
[[ -z "${OS_INFO_ARCH}" ]] && get_arch
[[ -z "${OS_INFO_RELEASE}" ]] && get_os_release

[[ "${OS_INFO_TYPE}" != "linux" ]] && colorEcho "${RED}Only support Linux!" && exit 1

K8S_WORKDIR="$HOME/k8s" && mkdir -p "${K8S_WORKDIR}"

## Verify the MAC address and product_uuid are unique for every node
# ip link
# ifconfig -a
# sudo cat /sys/class/dmi/id/product_uuid

# Disable Swap
sudo sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a
## or
# echo "KUBELET_EXTRA_ARGS=--fail-swap-on=false" > /etc/sysconfig/kubelet

# Check network adapters

# Disable firewall
if [[ $(systemctl is-enabled firewalld 2>/dev/null) ]]; then
    sudo systemctl stop firewalld && sudo systemctl disable firewalld
    sudo iptables -F && sudo iptables -X && sudo iptables -F -t nat && sudo iptables -X -t nat
    sudo iptables -P FORWARD ACCEPT
fi

## Disable selinux
# sudo pacman -S selinux-utils libselinux-utils
# getenforce && sestatus && selinuxenabled
[[ -x "$(command -v setenforce)" ]] && sudo setenforce 0
[[ -s "/etc/selinux/config" ]] && sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/' "/etc/selinux/config"

## Changing docker cgroup driver to systemd
# /lib/systemd/system/docker.service
if ! grep -q "native\.cgroupdriver" "/etc/docker/daemon.json" 2>/dev/null; then
#     if grep -q "^{" "/etc/docker/daemon.json" 2>/dev/null; then
#         sudo sed -i '/^{/a\    "exec-opts": ["native.cgroupdriver=systemd"],' "/etc/docker/daemon.json"
#     else
#         sudo tee -a "/etc/docker/daemon.json" >/dev/null <<-'EOF'
# {
#     "exec-opts": ["native.cgroupdriver=systemd"]
# }
# EOF
#     fi

    [[ ! -s "/etc/docker/daemon.json" ]] && echo '{}' | sudo tee "/etc/docker/daemon.json" >/dev/null

    if [[ -x "$(command -v jq)" ]]; then
        cat "/etc/docker/daemon.json" \
            | jq -r '."exec-opts"=."exec-opts" + ["native.cgroupdriver=systemd"]' \
            | sudo tee "/etc/docker/daemon.json" >/dev/null
    fi

    sudo systemctl daemon-reload && sudo systemctl restart docker
fi

## Letting iptables see bridged traffic
# Make sure that the `br_netfilter` module is loaded
# lsmod | grep br_netfilter
# sudo modprobe br_netfilter
# ipvs
# grep -e ipvs -e nf_conntrack "/lib/modules/$(uname -r)/modules.builtin"
# lsmod | grep -e ip_vs -e nf_conntrack
colorEcho "${BLUE}Setting kernel mod ${FUCHSIA}br_netfilter, ipvs${BLUE}..."
KERNEL_MOD_NF_CONNTRACK=$(find "/lib/modules/$(uname -r)" -name "nf_conntrack_ipv4" 2>/dev/null)
[[ -n "${KERNEL_MOD_NF_CONNTRACK}" ]] && KERNEL_MOD_NF_CONNTRACK="nf_conntrack_ipv4" || KERNEL_MOD_NF_CONNTRACK="nf_conntrack"

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf >/dev/null
br_netfilter
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
${KERNEL_MOD_NF_CONNTRACK}
EOF
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf >/dev/null
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
vm.swappiness=0
EOF
sudo sysctl --system

## Check required ports
# Control-plane node(s)
# Protocol	Direction	Port Range	Purpose                     Used By
# TCP         Inbound     6443*       Kubernetes API server	    All
# TCP         Inbound     2379-2380   etcd server client API	    kube-apiserver, etcd
# TCP         Inbound     10250	    kubelet API                 Self, Control plane
# TCP         Inbound     10251	    kube-scheduler              Self
# TCP         Inbound     10252	    kube-controller-manager     Self
# Worker node(s)
# Protocol	Direction	Port Range	Purpose                     Used By
# TCP         Inbound     10250	    kubelet API                 Self, Control plane
# TCP         Inbound     30000-32767 NodePort Services†          All


## Installing runtime
# To run containers in Pods, Kubernetes uses a container runtime.
# Runtime     Path to Unix domain socket
# Docker      /var/run/dockershim.sock
# containerd  /run/containerd/containerd.sock
# CRI-O       /var/run/crio/crio.sock


# Network
# Enable systemd-networkd in host
# https://wiki.archlinux.org/title/Systemd-networkd
# ls /etc/systemd/network/
# journalctl --boot=0 --unit=systemd-networkd
sudo systemctl disable network && sudo systemctl stop network
sudo systemctl disable networking && sudo systemctl stop networking
sudo systemctl disable NetworkManager && sudo systemctl stop NetworkManager

[[ -s "/etc/network/interfaces" ]] && sudo mv "/etc/network/interfaces" "/etc/network/interfaces.save"

sudo systemctl enable systemd-networkd && sudo systemctl start systemd-networkd
sudo systemctl enable systemd-resolved && sudo systemctl start systemd-resolved
# sudo ln -sf "/run/systemd/resolve/resolv.conf" "/etc/resolv.conf"

## Setting a static IP for default network interface
## networkctl list
# [[ -z "${NETWORK_INTERFACE_DEFAULT}" ]] && get_network_interface_default
# sudo tee "/etc/systemd/network/20-wired-${NETWORK_INTERFACE_DEFAULT}.network" >/dev/null <<-EOF
# [Match]
# Name=${NETWORK_INTERFACE_DEFAULT}
#
# [Network]
# #DHCP=yes
# Address=192.168.1.100/24
# Gateway=192.168.1.1
# # DNS=1.1.1.1
# # DNS=8.8.8.8
# EOF
# sudo systemctl restart systemd-networkd

## resolvectl status
# sudo tee "/etc/resolv.conf" >/dev/null <<-'EOF'
# nameserver 114.114.114.114
# nameserver 1.1.1.1
# nameserver 8.8.8.8
# EOF
# sudo systemctl restart systemd-resolved


## systemd-timesyncd
## https://wiki.archlinux.org/title/Systemd-timesyncd
## /etc/systemd/timesyncd.conf
# timedatectl show-timesync --all
# timedatectl status
# timedatectl timesync-status


## https://kubesphere.com.cn/forum/d/1272-kubeadm-k8s-kubesphere-2-1-1
## https://chinalhr.github.io/post/kubeadm-install-kubernetes/
## https://www.cnblogs.com/along21/p/10044931.html
## http://www.dev-share.top/2019/12/02/k8s-%E5%B8%B8%E8%A7%81%E9%97%AE%E9%A2%98%E4%B8%8E%E8%A7%A3%E5%86%B3%E6%96%B9%E6%A1%88/


# Kubeadm: Aggregator for issues filed against kubeadm
# https://github.com/kubernetes/kubeadm
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

## Creating a cluster with kubeadm
# control-plane node
CP_ENDPOINT=${1:-"cp.k8s.corp"}
CP_ADDRESS=${2:-""}

[[ -z "${CP_ADDRESS}" ]] && CP_ADDRESS=$(hostname -i 2>/dev/null)

# sudo -i "s/${HOSTNAME}/${CP_ENDPOINT}/g" /etc/hosts
# sudo hostnamectl set-hostname "${CP_ENDPOINT}"

## hosts map
# sudo tee -a "/etc/hosts" >/dev/null <<-EOF
# 192.168.1.100 cp.k8s.corp
# 192.168.1.101 node01.k8s.corp
# 192.168.1.102 node02.k8s.corp
# EOF

# if ! grep -q "${CP_ADDRESS} ${CP_ENDPOINT}" /etc/hosts 2>/dev/null; then
#     CP_HOST_ENTRY=$(grep -v "127.0.0.1" /etc/hosts | grep "\s${CP_ENDPOINT}$")
#     if [[ -n "${CP_HOST_ENTRY}" ]]; then
#         sudo sed -i "s/${CP_HOST_ENTRY}/${CP_ADDRESS} ${CP_ENDPOINT}/g" /etc/hosts
#     else
#         echo "${CP_ADDRESS} ${CP_ENDPOINT}" | sudo tee -a /etc/hosts >/dev/null
#     fi
# fi

HOSTS_MAP="${K8S_WORKDIR}/k8s.hosts"
if [[ -s "${HOSTS_MAP}" ]]; then
    HOSTS_ENTRY=$(< "${HOSTS_MAP}")
    echo "${HOSTS_ENTRY}" | sudo tee -a "/etc/hosts" >/dev/null
fi


## Export default config
## Configuring each kubelet in your cluster using kubeadm
# kubeadm config print init-defaults --component-configs KubeletConfiguration > "${K8S_WORKDIR}/kubeadm.yml"

## List & pull images
# kubeadm config images list
# kubeadm config images pull
# kubeadm config images list --config "${K8S_WORKDIR}/kubeadm.yml"
# kubeadm config images pull --config "${K8S_WORKDIR}/kubeadm.yml"


## Initializing control-plane node
# kubeadm init --config="${K8S_WORKDIR}/kubeadm.yml" --upload-certs | tee "${K8S_WORKDIR}/kubeadm-init.log"
sudo kubeadm init \
    --control-plane-endpoint="${CP_ENDPOINT}" \
    --apiserver-advertise-address="${CP_ADDRESS}" \
    --pod-network-cidr=10.244.0.0/16

# To start using your cluster, you need to run the following as a regular user:
mkdir -p "$HOME/.kube" && \
    sudo cp -i "/etc/kubernetes/admin.conf" "$HOME/.kube/config" && \
    sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

# fix `kubectl get cs` error: componentstatus/scheduler Unhealthy
sudo sed -i "/--port=0$/ s/^\(.*\)$/#\1/" "/etc/kubernetes/manifests/kube-controller-manager.yaml"
sudo sed -i "/--port=0$/ s/^\(.*\)$/#\1/" "/etc/kubernetes/manifests/kube-scheduler.yaml"

# etcd metrics
sudo sed -i "s/127.0.0.1:2381/0.0.0.0:2381/" "/etc/kubernetes/manifests/etcd.yaml"

sudo systemctl daemon-reload && sudo systemctl restart kubelet

# Cluster configuration
kubectl -n kube-system get cm kubeadm-config -o yaml
kubectl get cs,ns -o wide
kubectl get pod,svc -n kube-system -o wide


## Add worker nodes
# kubeadm token list
# openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
# sudo kubeadm token create --print-join-command
# sudo kubeadm join 192.168.1.100:6443 --token <token> --discovery-token-ca-cert-hash <hash>
kubectl get nodes -o wide


# By default, your cluster will not schedule Pods on the control-plane node for security reasons.
# If you want to be able to schedule Pods on the control-plane node, 
# for example for a single-machine Kubernetes cluster for development, run:
kubectl taint nodes --all node-role.kubernetes.io/master-
# kubectl taint nodes NODE_NAME node-role.kubernetes.io/master=true:NoSchedule


# Deploy a pod network to the cluster
# https://kubernetes.io/docs/concepts/cluster-administration/addons/
[[ -z "${NETWORK_INTERFACE_DEFAULT}" ]] && get_network_interface_default

# Calico on Kubernetes
# https://docs.projectcalico.org/getting-started/kubernetes/quickstart
curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${K8S_WORKDIR}/tigera-operator.yaml" \
    "https://docs.projectcalico.org/manifests/tigera-operator.yaml"
curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${K8S_WORKDIR}/tigera-resources.yaml" \
    "https://docs.projectcalico.org/manifests/custom-resources.yaml"
if [[ -s "${K8S_WORKDIR}/tigera-operator.yaml" && -s "${K8S_WORKDIR}/tigera-resources.yaml" ]]; then
    sed -i 's|cidr: 192.168.0.0|cidr: 10.244.0.0|' "${K8S_WORKDIR}/tigera-resources.yaml"

    sed -i '/- name: WATCH_NAMESPACE/i\            - name: IP_AUTODETECTION_METHOD' "${K8S_WORKDIR}/tigera-operator.yaml" && \
        sed -i "/- name: WATCH_NAMESPACE/i\              value: \"interface=${NETWORK_INTERFACE_DEFAULT:0:3}.*\"" "${K8S_WORKDIR}/tigera-operator.yaml" && \
        sed -i '/- name: WATCH_NAMESPACE/i\            - name: IP6_AUTODETECTION_METHOD' "${K8S_WORKDIR}/tigera-operator.yaml" && \
        sed -i "/- name: WATCH_NAMESPACE/i\              value: \"interface=${NETWORK_INTERFACE_DEFAULT:0:3}.*\"" "${K8S_WORKDIR}/tigera-operator.yaml"

    kubectl create -f "${K8S_WORKDIR}/tigera-operator.yaml" -f "${K8S_WORKDIR}/tigera-resources.yaml"
fi

## Install Calico on a Kubernetes cluster using Helm 3
## https://docs.projectcalico.org/getting-started/kubernetes/helm
# helm repo add projectcalico https://docs.projectcalico.org/charts
# helm repo update
## helm show values projectcalico/tigera-operator --version v3.20.0
## helm install calico projectcalico/tigera-operator --version v3.20.0
# helm install calico projectcalico/tigera-operator

## Configure IP autodetection
## https://docs.projectcalico.org/networking/ip-autodetection
# kubectl set env daemonset/calico-node -n calico-system IP_AUTODETECTION_METHOD="interface=eth.*"
# kubectl set env daemonset/calico-node -n calico-system IP6_AUTODETECTION_METHOD="interface=eth.*"

# watch kubectl get pods -n calico-system
kubectl wait -n calico-system --for=condition=ready pod --all --timeout=60s
kubectl get daemonset -n calico-system

## Install Calico for policy and flannel for networking
## https://docs.projectcalico.org/getting-started/kubernetes/flannel/flannel
# curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${K8S_WORKDIR}/canal.yaml" \
#     "https://docs.projectcalico.org/manifests/canal.yaml"
# if [[ -s "${K8S_WORKDIR}/canal.yaml" ]]; then
#     ## Configure IP autodetection
#     ## grep -C 5 '\- name: CLUSTER_TYPE' "${K8S_WORKDIR}/canal.yaml"
#     # sed -i '/- name: CLUSTER_TYPE/i\            - name: IP_AUTODETECTION_METHOD' "${K8S_WORKDIR}/canal.yaml" && \
#     #     sed -i "/- name: CLUSTER_TYPE/i\              value: \"interface=${NETWORK_INTERFACE_DEFAULT:0:3}.*\"" "${K8S_WORKDIR}/canal.yaml" && \
#     #     sed -i '/- name: CLUSTER_TYPE/i\            - name: IP6_AUTODETECTION_METHOD' "${K8S_WORKDIR}/canal.yaml" && \
#     #     sed -i "/- name: CLUSTER_TYPE/i\              value: \"interface=${NETWORK_INTERFACE_DEFAULT:0:3}.*\"" "${K8S_WORKDIR}/canal.yaml"
#     kubectl apply -f "${K8S_WORKDIR}/canal.yaml"
#     kubectl wait -n kube-system --for=condition=ready pod --all --timeout=60s
# fi

# Install calicoctl as a Kubernetes pod (Kubernetes API datastore)
# https://docs.projectcalico.org/getting-started/clis/calicoctl/install
# https://docs.projectcalico.org/getting-started/clis/calicoctl/configure/kdd
if [[ ! -x "$(command -v calicoctl)" && -x "$(command -v kubectl)" ]]; then
    kubectl apply -f "https://docs.projectcalico.org/manifests/calicoctl.yaml"

    kubectl exec -ti -n kube-system calicoctl -- /calicoctl get profiles -o wide

    export CALICO_DATASTORE_TYPE=kubernetes
    export CALICO_KUBECONFIG="$HOME/.kube/config"
    alias calicoctl="kubectl exec -i -n kube-system calicoctl -- /calicoctl"
    ## In order to use the calicoctl alias when reading manifests, redirect the file into stdin, for example:
    # calicoctl create -f - < my_manifest.yaml
fi

calicoctl get workloadendpoints
calicoctl node status


# cert-manager
# https://cert-manager.io/docs/installation/
# https://artifacthub.io/packages/helm/cert-manager/cert-manager
CHECK_URL="https://api.github.com/repos/jetstack/cert-manager/releases/latest"
CERT_MANAGER_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null)

helm repo add jetstack https://charts.jetstack.io
helm repo update

if [[ -n "${CERT_MANAGER_VERSION}" ]]; then
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${K8S_WORKDIR}/cert-manager.crds.yaml" \
        "https://github.com/jetstack/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.crds.yaml" && \
        kubectl apply -f "${K8S_WORKDIR}/cert-manager.crds.yaml"

    helm install \
        cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --create-namespace \
        --version "${CERT_MANAGER_VERSION}"

    kubectl wait -n cert-manager --for=condition=ready pod --all --timeout=120s
fi


# NGINX Ingress Controller for Kubernetes
# https://github.com/kubernetes/ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx

# wait until it is ready to run the next command
kubectl wait -n default --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

# Detect installed version
POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it "${POD_NAME}" -- /nginx-ingress-controller --version


# Storage
# Kubernetes NFS Subdir External Provisioner
# https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update

helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=127.0.0.1 \
    --set nfs.path=/nfs


## Kubernetes Metrics Server
## https://github.com/kubernetes-sigs/metrics-server

## Prerequisites for Metrics Server
## fix: Error from server (ServiceUnavailable): the server is currently unable to handle the request
# kubectl get apiservice | grep metrics.k8s.io
# kubectl describe apiservice v1beta1.metrics.k8s.io
# if ! sudo grep -q "enable-aggregator-routing=true" "/etc/kubernetes/manifests/kube-apiserver.yaml"; then
#     sudo sed -i '/--enable-bootstrap-token-auth/a\    - --enable-aggregator-routing=true' \
#         "/etc/kubernetes/manifests/kube-apiserver.yaml"
# fi
# sudo systemctl daemon-reload && sudo systemctl restart kubelet

# curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${K8S_WORKDIR}/metrics-server.yaml" \
#     "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml" && \
#     sed -i '/--metric-resolution/a\        - --kubelet-insecure-tls' "${K8S_WORKDIR}/metrics-server.yaml" && \
#     kubectl apply -f "${K8S_WORKDIR}/metrics-server.yaml"

# kubectl get pods -n kube-system | grep metric
## kubectl logs {pod-name} -n kube-system
## kubectl edit deployment metrics-server -n kube-system

# kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
# kubectl top node
# kubectl top pod


# Prometheus Operator: creates/configures/manages Prometheus clusters atop Kubernetes
# kube-prometheus: Use Prometheus to monitor Kubernetes and applications running on Kubernetes
# https://github.com/prometheus-operator/kube-prometheus
# https://blog.51cto.com/legehappy/2721873

# Prerequisites for Prometheus Operator
sudo sed -i "s/- --bind-address=127.0.0.1/- --bind-address=0.0.0.0/" "/etc/kubernetes/manifests/kube-controller-manager.yaml"
sudo sed -i "s/- --bind-address=127.0.0.1/- --bind-address=0.0.0.0/" "/etc/kubernetes/manifests/kube-scheduler.yaml"

# sudo sed -i 's/--authorization-mode=Node,RBAC/--authorization-mode=Node,Webhook,RBAC/' "/etc/kubernetes/manifests/kube-apiserver.yaml"
# sudo sed -i '/--enable-bootstrap-token-auth/a\    - --authentication-token-webhook=true' "/etc/kubernetes/manifests/kube-apiserver.yaml"

KUBEADM_SYSTEMD_CONF="/etc/systemd/system/kubelet.service.d/10-kubeadm.conf"
sudo sed -i "/cadvisor-port=0/d" "${KUBEADM_SYSTEMD_CONF}"
if ! sudo grep -q "authentication-token-webhook=true" "${KUBEADM_SYSTEMD_CONF}"; then
    sudo sed -i 's/\$KUBELET_EXTRA_ARGS/\$KUBELET_EXTRA_ARGS --authentication-token-webhook=true --authorization-mode=Webhook/' \
        "${KUBEADM_SYSTEMD_CONF}"
fi

sudo systemctl daemon-reload && sudo systemctl restart kubelet

# Clean exists crd
kubectl get crd -A | grep 'coreos.com' | awk '{print $1}' | xargs kubectl delete crd

# Create the namespace and CRDs, and then wait for them to be available before creating the remaining resources
CHECK_URL="https://api.github.com/repos/prometheus-operator/kube-prometheus/branches"
KUBE_PROM_BRANCH=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | grep 'name' | cut -d\" -f4 | grep '^release' | sort -rV | head -n1)

Git_Clone_Update "prometheus-operator/kube-prometheus" "${K8S_WORKDIR}/kube-prometheus"
if [[ -d "${K8S_WORKDIR}/kube-prometheus" ]]; then
    git switch "${KUBE_PROM_BRANCH}" || git checkout "${KUBE_PROM_BRANCH}"

    cp -Rf "${K8S_WORKDIR}/kube-prometheus/manifests" "${K8S_WORKDIR}/prometheus-manifests"
    # cd "${K8S_WORKDIR}/prometheus-manifests" || exit
fi

# Create the namespace and CRDs
kubectl create -f "${K8S_WORKDIR}/prometheus-manifests/setup"
until kubectl get servicemonitors -A; do date; sleep 1; echo ""; done

# Storage for Prometheus Operator
sed -i "/prometheus-config-reloader/a\        - --storage.tsdb.retention.time=30d" "${K8S_WORKDIR}/prometheus-manifests/prometheus-operator-deployment.yaml"

tee -a "${K8S_WORKDIR}/prometheus-manifests/prometheus-prometheus.yaml" >/dev/null <<-'EOF'
storage:
  volumeClaimTemplate:
    spec:
      storageClassName: nfsv4-sc
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
EOF

tee -a "${K8S_WORKDIR}/prometheus-manifests/alertmanager-alertmanager.yaml" >/dev/null <<-'EOF'
storage:
  volumeClaimTemplate:
    spec:
      storageClassName: nfsv4-sc
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
EOF

sed -i '/- emptyDir: {}/i\      - name: grafana-storage' "${K8S_WORKDIR}/prometheus-manifests/grafana-deployment.yaml" && \
    sed -i '/- emptyDir: {}/i\        persistentVolumeClaim:' "${K8S_WORKDIR}/prometheus-manifests/grafana-deployment.yaml" && \
    sed -i '/- emptyDir: {}/i\          claimName: grafana-pvc' "${K8S_WORKDIR}/prometheus-manifests/grafana-deployment.yaml" && \
    sed -i '/- emptyDir: {}/,+1 d' "${K8S_WORKDIR}/prometheus-manifests/grafana-deployment.yaml"

kubectl apply -f "${K8S_WORKDIR}/NFS4Storage.yaml"
# kubectl apply -f "${K8S_WORKDIR}/prometheus-manifests/prometheus-prometheus.yaml"
# kubectl apply -f "${K8S_WORKDIR}/prometheus-manifests/alertmanager-alertmanager.yaml"
# kubectl apply -f "${K8S_WORKDIR}/prometheus-manifests/grafana-deployment.yaml"

# Create the remaining resources
kubectl create -f "${K8S_WORKDIR}/prometheus-manifests/"

kubectl wait -n monitoring --for=condition=ready pod --all --timeout=120s

# Services for Prometheus Operator
cp "${MY_SHELL_SCRIPTS}/k8s/prometheus"/*.yaml "${K8S_WORKDIR}"

CONTROL_IP=$(kubectl get ep/kubernetes -ojsonpath="{.subsets[0].addresses[*].ip}")
NODE_IP=$(kubectl -n kube-system get ep/kubelet -ojsonpath="{.subsets[0].addresses[*].ip}")
while read -r epip; do
    sed -i "/- addresses:/a\  - ip: ${epip}" "${K8S_WORKDIR}/EtcdService.yaml"
    sed -i "/- addresses:/a\  - ip: ${epip}" "${K8S_WORKDIR}/KubeControllerManagerService.yaml"
    sed -i "/- addresses:/a\  - ip: ${epip}" "${K8S_WORKDIR}/kubeSchedulerService.yaml"
done < <(echo "${CONTROL_IP}" | tr ' ' '\n' | sort -r)

kubectl -n kube-system create -f "${K8S_WORKDIR}/KubeControllerManagerService.yaml"
kubectl -n kube-system create -f "${K8S_WORKDIR}/kubeSchedulerService.yaml"

## etcd metrics
## Grafana dashboard: 3070
## sudo curl https://localhost:2379/metrics -k --cert /etc/kubernetes/pki/etcd/ca.crt --key /etc/kubernetes/pki/etcd/ca.key
## sudo curl https://localhost:2379/metrics -k --cert /etc/kubernetes/pki/etcd/healthcheck-client.crt --key /etc/kubernetes/pki/etcd/healthcheck-client.key
# POD_NAME=$(kubectl get pods -A -l component=etcd -o jsonpath='{.items[0].metadata.name}')
# kubectl -n kube-system get pod "${POD_NAME}" -o yaml | grep '-file'

# sudo cp "/etc/kubernetes/pki/etcd/ca.crt" "${K8S_WORKDIR}/etcd-ca.crt"
# sudo cp "/etc/kubernetes/pki/etcd/healthcheck-client.crt" "${K8S_WORKDIR}/etcd-cert.crt"
# sudo cp "/etc/kubernetes/pki/etcd/healthcheck-client.key" "${K8S_WORKDIR}/etcd-cert.key"
# sudo chown $(id -u):$(id -g) "${K8S_WORKDIR}"/etcd-*.*
# kubectl -n monitoring create secret generic etcd-cert --from-file="${K8S_WORKDIR}/etcd-ca.crt" --from-file="${K8S_WORKDIR}/etcd-cert.crt" --from-file="${K8S_WORKDIR}/etcd-cert.key"
# rm "${K8S_WORKDIR}"/etcd-cert.*
# kubectl -n monitoring patch deployment prometheus-operator -p '{"spec":{"template":{"spec":{"volumes":[{"name":"etcd-cert","secret":{"defaultMode":420,"secretName":"etcd-cert"}}]}}}}'
# kubectl -n monitoring patch deployment prometheus-operator -p '{"spec":{"template":{"spec":{"containers":[{"name":"prometheus-operator","volumeMounts": [{"mountPath": "/opt/prometheus/secrets/etcd-certs","name": "etcd-cert"}]}]}}}}'

kubectl apply -f "${K8S_WORKDIR}/EtcdService.yaml"
kubectl apply -f "${K8S_WORKDIR}/EtcdServiceMonitor.yaml"

kubectl get deploy -n monitoring -o wide
kubectl get statefulset -n monitoring -o wide
kubectl get pod,svc,ds -n monitoring -o wide
kubectl get servicemonitors -n monitoring | grep etcd
kubectl get sc,pvc,pv -n monitoring  -o wide

# Access the dashboards
# Prometheus
nohup kubectl -n monitoring port-forward --address 0.0.0.0 svc/prometheus-k8s 9090 > prometheus-k8s-port-forward.log 2>&1 &
# kubectl -n monitoring expose service prometheus-k8s --type=NodePort --port=9090 --target-port=9090 --name=prometheus-k8s-expose-9090
# Then access via http://localhost:9090

# Grafana
nohup kubectl -n monitoring port-forward --address 0.0.0.0 svc/grafana 3000 > grafana-k8s-port-forward.log 2>&1 &
# Then access via http://localhost:3000 and use the default grafana user:password of admin:admin.

# Alert Manager
nohup kubectl -n monitoring port-forward --address 0.0.0.0 svc/alertmanager-main 9093 > alertmanager-k8s-port-forward.log 2>&1 &
# Then access via http://localhost:9093


cd "${CURRENT_DIR}" || exit
