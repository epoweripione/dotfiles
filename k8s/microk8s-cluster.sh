#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
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


if [[ ! -x "$(command -v snap)" ]]; then
    [[ -s "${MY_SHELL_SCRIPTS}/installer/snap_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/snap_installer.sh"
fi

[[ ! -x "$(command -v snap)" ]] && colorEcho "${FUCHSIA}snap${BLUE} is not installed!" && exit 1

# https://kubernetes.io/docs/reference/kubectl/
# https://kubernetes.io/docs/reference/kubectl/cheatsheet/
[[ ! -x "$(command -v kubectl)" ]] && asdf_App_Install kubectl
[[ ! -x "$(command -v kubectl)" ]] && colorEcho "${FUCHSIA}kubectl${BLUE} is not installed!" && exit 1

# https://helm.sh/
# https://artifacthub.io/
[[ ! -x "$(command -v helm)" ]] && asdf_App_Install helm
[[ ! -x "$(command -v helm)" ]] && colorEcho "${FUCHSIA}helm${BLUE} is not installed!" && exit 1

[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

# MicroK8s: High availability K8s. Zero-ops Kubernetes for developers, edge and IoT
# https://microk8s.io/
sudo snap install microk8s --classic

# Installing behind a proxy
# https://microk8s.io/docs/install-proxy
if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
    sed -i 's|https://registry-1.docker.io|https://docker.mirrors.sjtug.sjtu.edu.cn|' "/var/snap/microk8s/current/args/containerd-template.toml"

    # hostname & hostip
    [[ -z "${HOSTNAME}" ]] && HOSTNAME=$(uname -n 2>/dev/null)
    [[ -z "${HOSTNAME}" ]] && HOSTNAME=$(hostname 2>/dev/null)

    # [[ -z "${HOSTIP}" ]] && HOSTIP=$(hostname -i 2>/dev/null)
    [[ -z "${HOSTIP}" ]] && HOSTIP=$(hostname -I 2>/dev/null)
    [[ -n "${HOSTIP}" ]] && HOSTIP="${HOSTIP% }" && HOSTIP="${HOSTIP// /,}"

    NO_PROXY_K8S="10.1.0.0/16,10.152.183.0/24"
    [[ -n "${HOSTNAME}" ]] && NO_PROXY_K8S="${NO_PROXY_K8S},${HOSTNAME}"
    [[ -n "${HOSTIP}" ]] && NO_PROXY_K8S="${NO_PROXY_K8S},${HOSTIP}"

#     sudo tee -a "/etc/environment" >/dev/null <<-EOF
# HTTPS_PROXY=http://${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_MIXED_PORT}
# HTTP_PROXY=http://${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_MIXED_PORT}
# NO_PROXY=10.1.0.0/16,10.152.183.0/24,127.0.0.1

# https_proxy=http://${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_MIXED_PORT}
# http_proxy=http://${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_MIXED_PORT}
# no_proxy=${NO_PROXY_K8S},127.0.0.1
# EOF

    sudo tee -a "/var/snap/microk8s/current/args/containerd-env" >/dev/null <<-EOF

HTTPS_PROXY=http://${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_MIXED_PORT}
NO_PROXY=${NO_PROXY_K8S}
EOF
    microk8s stop && microk8s start
fi

# Check the status while Kubernetes starts
microk8s status --wait-ready

# Turn on the services
microk8s enable dashboard dns ingress prometheus registry storage
# Try `microk8s enable --help` for a list of available services and optional features.
# `microk8s disable <name>` turns off a service.

# Start using Kubernetes
microk8s kubectl get all --all-namespaces
# If you mainly use MicroK8s you can make our kubectl the default one on your command-line with alias mkctl="microk8s kubectl".
# Since it is a standard upstream kubectl, 
# you can also drive other Kubernetes clusters with it by pointing to the respective kubeconfig file via the --kubeconfig argument.

# Access the Kubernetes dashboard
microk8s dashboard-proxy

## Start and stop Kubernetes to save battery
# Kubernetes is a collection of system services that talk to each other all the time. 
# If you don’t need them running in the background then you will save battery by stopping them. 
# `microk8s start` and `microk8s stop` will do the work for you.

## Reset to the default initial state
# microk8s reset

## Troubleshooting
# microk8s inspect
# sudo journalctl -u snap.microk8s.daemon-etcd


# Export config
kubectl config view --raw > "$HOME/.kube/config"
cat "$HOME/.kube/config"


## Clustering with MicroK8s
## https://microk8s.io/docs/clustering


## Lens: The Kubernetes IDE
## https://k8slens.dev/
# sudo snap install kontena-lens --classic


# Kalm: Kubernetes AppLication Manager
# https://kalm.dev/
Git_Clone_Update_Branch "kalmhq/kalm" "$HOME/kalm"
cd "$HOME/kalm" && ./scripts/install-local-mode.sh

## open a port to the web server
# nohup kubectl port-forward --address 0.0.0.0 -n kalm-system \
#     $(kubectl get pod -n kalm-system -l app=kalm -ojsonpath="{.items[0].metadata.name}") 3010:3010 > kalm-port-forward.log 2>&1 &
kubectl -n kalm-system expose service kalm --port=3010 --target-port=3010 --name=kalm-expose-3010 --labels='kalm-component=kalm-expose'
nohup kubectl -n kalm-system port-forward --address 0.0.0.0 service/kalm-expose-3010 3010:3010 > kalm-port-forward.log 2>&1 &
# Kalm should now be accessible at http://localhost:3010


## https://hub.docker.com/r/crccheck/hello-world
# nohup kubectl port-forward --address 0.0.0.0 -n hello-world-app \
#     $(kubectl get pod -n hello-world-app -l app=hello-world -ojsonpath="{.items[0].metadata.name}") 9800:8000 > hello-world-port-forward.log 2>&1 &


## Helm3
# https://helm.sh/
# Initialize a Helm Chart Repository
# Available Helm chart repositories: https://artifacthub.io/packages/search?kind=0
# https://hub.kubeapps.com/charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add elastic https://helm.elastic.co
helm repo add gitlab https://charts.gitlab.io
helm repo add harbor https://helm.goharbor.io
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest

helm repo update
helm repo list

# helm search repo bitnami


# Install/Upgrade Rancher on a Kubernetes Cluster
# https://rancher.com/docs/rancher/v2.6/en/installation/install-rancher-on-k8s/
kubectl create namespace cattle-system

helm install \
    rancher rancher-latest/rancher \
    --namespace cattle-system \
    --set hostname="${HOSTNAME}" \
    --set bootstrapPassword="admin"

kubectl -n cattle-system rollout status deploy/rancher
kubectl -n cattle-system get deploy rancher
kubectl -n cattle-system get pods

# kubectl get pods -A -l app=rancher
# kubectl -n cattle-system get svc rancher
# kubectl -n cattle-system describe svc rancher
# kubectl -n cattle-system get ep rancher
# kubectl -n cattle-system edit svc rancher

tee "$PWD/rancher-nodeport-443.yaml" >/dev/null <<-EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: rancher-nodeport-443
  name: rancher-nodeport-443
  namespace: cattle-system
spec:
  type: NodePort
  selector:
    app: rancher
  ports:
  - name: rancher-nodeport-443
    nodePort: 30443
    port: 443
    protocol: TCP
    targetPort: 444
EOF

kubectl -n cattle-system create -f "$PWD/rancher-nodeport-443.yaml"
kubectl -n cattle-system get svc rancher-nodeport-443
# kubectl -n cattle-system delete svc rancher-nodeport-443

echo "https://${HOSTNAME}/dashboard/?setup=$(kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}')"


# List All Container Images Running in a Cluster
kubectl get pods --all-namespaces \
    -o jsonpath="{.items[*].spec.containers[*].image}" \
    | tr -s '[:space:]' '\n' | sort | uniq -c


cd "${CURRENT_DIR}" || exit
