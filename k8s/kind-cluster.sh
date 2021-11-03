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


# kind is a tool for running local Kubernetes clusters using Docker container “nodes”
# https://kind.sigs.k8s.io/
[[ ! -x "$(command -v kind)" ]] && asdf_App_Install kind
[[ ! -x "$(command -v kind)" ]] && colorEcho "${FUCHSIA}kind${BLUE} is not installed!" &&　exit 1

# https://kubernetes.io/docs/reference/kubectl/
# https://kubernetes.io/docs/reference/kubectl/cheatsheet/
[[ ! -x "$(command -v kubectl)" ]] && asdf_App_Install kubectl
[[ ! -x "$(command -v kubectl)" ]] && colorEcho "${FUCHSIA}kubectl${BLUE} is not installed!" && exit 1

# https://helm.sh/
# https://artifacthub.io/
[[ ! -x "$(command -v helm)" ]] && asdf_App_Install helm
[[ ! -x "$(command -v helm)" ]] && colorEcho "${FUCHSIA}helm${BLUE} is not installed!" && exit 1

## https://istio.io/latest/
# [[ ! -x "$(command -v istioctl)" ]] && asdf_App_Install istioctl
# [[ ! -x "$(command -v istioctl)" ]] && colorEcho "${FUCHSIA}istioctl${BLUE} is not installed!" &&　exit 1


# Creating a Cluster
if [[ "$(uname -r)" =~ "microsoft" ]]; then
    # https://kind.sigs.k8s.io/docs/user/using-wsl2/
    tee "$PWD/kind-cluster-config.yml" >/dev/null <<-'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30000
    hostPort: 30000
    protocol: TCP
EOF
    kind create cluster --config=kind-cluster-config.yml
else
    kind create cluster
fi

# create deployment
kubectl create deployment nginx --image=nginx --port=80

# create service
kubectl create service nodeport nginx --tcp=80:80 --node-port=30000

# get pods,services
kubectl get pods,svc -o wide

# access service
curl localhost:30000

# Interacting With Your Cluster
kind get clusters

# In order to interact with a specific cluster, you only need to specify the cluster name as a context in kubectl:
kubectl cluster-info --context kind-kind

## Export config for Lens
# kind get kubeconfig
kubectl config view --raw > "$HOME/.kube/config"
cat "$HOME/.kube/config"


# Helm Chart Repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add stable https://charts.helm.sh/stable
helm repo add traefik https://helm.traefik.io/traefik
helm repo update && helm repo list

# helm search hub nginx
# helm search repo nginx

## Customizing the Chart Before Installing
# helm show values bitnami/wordpress
## You can then override any of these settings in a YAML formatted file, and then pass that file during installation.
# echo '{mariadb.auth.database: user0db, mariadb.auth.username: user0}' > wordpress_values.yaml
# helm install -f wordpress_values.yaml bitnami/wordpress --generate-name

helm install prometheus prometheus-community/prometheus
helm install traefik traefik/traefik --set metrics.prometheus.enabled=true

# helm list --all

# helm uninstall RELEASE_NAME [...] [flags]


## Display one or many resources
# kubectl api-resources
# kubectl get configmaps prometheus-server -o yaml


## Pause & Restart kind Cluster
## docker ps -a
# docker pause kind-control-plane
# docker restart kind-control-plane


## Deleting a Cluster
# kind delete cluster


## Loading an Image Into Your Cluster
## Docker images can be loaded into your cluster nodes with:
# kind load docker-image my-custom-image-0 my-custom-image-1 --name kind
