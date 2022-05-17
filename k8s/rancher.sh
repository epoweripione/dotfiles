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

if [[ ! -x "$(command -v docker)" ]]; then
    [[ -s "${MY_SHELL_SCRIPTS}/installer/docker_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/docker_installer.sh"
fi

[[ ! -x "$(command -v docker)" ]] && colorEcho "${FUCHSIA}docker${BLUE} is not installed!" && exit 1

## Single Node Using Docker
## https://rancher.com/docs/rancher/v2.6/en/installation/other-installation-methods/single-node-docker/
# sudo docker run --privileged -d --restart=unless-stopped \
#     -p 9880:80 -p 9843:443 \
#     -e HTTP_PROXY="http://${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_MIXED_PORT}" \
#     -e HTTPS_PROXY="http://${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_MIXED_PORT}" \
#     -e NO_PROXY="localhost,127.0.0.1,0.0.0.0,10.0.0.0/8,cattle-system.svc,192.168.10.0/24,.svc,.cluster.local,example.com" \
#     -v $PWD/rancher:/var/lib/rancher \
#     rancher/rancher:latest

## https://<SERVER_IP>


# https://kubernetes.io/docs/reference/kubectl/
# https://kubernetes.io/docs/reference/kubectl/cheatsheet/
[[ ! -x "$(command -v kubectl)" ]] && asdf_App_Install kubectl
[[ ! -x "$(command -v kubectl)" ]] && colorEcho "${FUCHSIA}kubectl${BLUE} is not installed!" && exit 1

# https://helm.sh/
# https://artifacthub.io/
[[ ! -x "$(command -v helm)" ]] && asdf_App_Install helm
[[ ! -x "$(command -v helm)" ]] && colorEcho "${FUCHSIA}helm${BLUE} is not installed!" && exit 1

[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env
[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

# Setting up a High-availability RKE2 Kubernetes Cluster for Rancher
# https://rancher.com/docs/rancher/v2.6/en/installation/resources/k8s-tutorials/ha-rke2/
RKE_HOSTNAME="${1:-$HOSTNAME}"

[[ -z "${RKE_HOSTNAME}" ]] && RKE_HOSTNAME=$(uname -n 2>/dev/null)
[[ -z "${RKE_HOSTNAME}" ]] && RKE_HOSTNAME=$(hostname 2>/dev/null)

RKE_HOSTIP=$(hostname -i 2>/dev/null)

sudo mkdir -p "/etc/rancher/rke2"
sudo tee "/etc/rancher/rke2/config.yaml" >/dev/null <<-EOF
token: my-shared-secret
tls-san:
  - ${RKE_HOSTNAME}
  - ${RKE_HOSTIP}
EOF

curl -sfL https://get.rke2.io | sudo sh -

sudo systemctl enable rke2-server.service && sudo systemctl start rke2-server.service

# journalctl -eu rke2-server -f

# Confirm that RKE2 is Running
/var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml get nodes
/var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml get pods --all-namespaces

## To join the rest of the nodes, 
## you need to configure each additional node with the same shared token or the one generated automatically. 
## Here is an example of the configuration file: 
# token: my-shared-secret
# server: https://my-fixed-registration-address.com:9345
# tls-san:
# my-kubernetes-domain.com
# another-kubernetes-domain.com
## After that you need to run the installer and enable then start rke2
# curl -sfL https://get.rke2.io | sudo sh -
# systemctl enable rke2-server.service
# systemctl start rke2-server.service
## Repeat the same command on your third RKE2 server node.

# Configure nginx to be a daemonset
sudo tee "/var/lib/rancher/rke2/server/manifests/rke2-ingress-nginx-daemonset.yaml" >/dev/null <<-EOF
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-ingress-nginx
  namespace: kube-system
spec:
  valuesContent: |-
    controller:
      kind: DaemonSet
      daemonset:
        useHostPort: true
EOF

cp "/etc/rancher/rke2/rke2.yaml" "$HOME/.kube/rke2.yaml"
kubectl --kubeconfig "$HOME/.kube/rke2.yaml" get pods -A

# Export config for Lens
kubectl --kubeconfig "$HOME/.kube/rke2.yaml" config view --raw


## To uninstall RKE2 installed via the Tarball method from your system, simply run the command below. 
## This will shutdown process, remove the RKE2 binary, and clean up files used by RKE2.
# /usr/local/bin/rke2-uninstall.sh


# Install/Upgrade Rancher on a Kubernetes Cluster
# https://rancher.com/docs/rancher/v2.6/en/installation/install-rancher-on-k8s/
# Add the Helm Chart Repository
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest

# Create a Namespace for Rancher
kubectl --kubeconfig "$HOME/.kube/rke2.yaml" create namespace cattle-system

## Choose your SSL Configuration
# CONFIGURATION	                            HELM CHART OPTION               REQUIRES CERT-MANAGER
# Rancher Generated Certificates (Default)    ingress.tls.source=rancher      yes
# Let’s Encrypt                               ingress.tls.source=letsEncrypt  yes
# Certificates from Files                     ingress.tls.source=secret       no

## Install cert-manager
## This step is only required to use certificates 
## issued by Rancher’s generated CA (ingress.tls.source=rancher) 
## or to request Let’s Encrypt issued certificates (ingress.tls.source=letsEncrypt).

## If you have installed the CRDs manually instead of with the 
## `--set installCRDs=true` option added to your Helm install command, 
## you should upgrade your CRD resources before upgrading the Helm chart:
# CHECK_URL="https://api.github.com/repos/jetstack/cert-manager/releases/latest"
# CERT_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null)
# kubectl --kubeconfig "$HOME/.kube/rke2.yaml" \
#     apply -f "https://github.com/jetstack/cert-manager/releases/download/${CERT_VERSION}/cert-manager.crds.yaml"

# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io

# Update your local Helm chart repository cache
helm repo update

# Install the cert-manager Helm chart
helm --kubeconfig "$HOME/.kube/rke2.yaml" install \
    cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version "${CERT_VERSION}" \
    --set installCRDs=true

kubectl --kubeconfig "$HOME/.kube/rke2.yaml" get pods --namespace cert-manager
kubectl --kubeconfig "$HOME/.kube/rke2.yaml" get crd

# Install Rancher with Helm and Your Chosen Certificate Option
helm --kubeconfig "$HOME/.kube/rke2.yaml" install \
    rancher rancher-latest/rancher \
    --namespace cattle-system \
    --set hostname="${RKE_HOSTNAME}" \
    --set bootstrapPassword="admin"

# Verify that the Rancher Server is Successfully Deployed
kubectl --kubeconfig "$HOME/.kube/rke2.yaml" -n cattle-system rollout status deploy/rancher
kubectl --kubeconfig "$HOME/.kube/rke2.yaml" -n cattle-system get deploy rancher
kubectl --kubeconfig "$HOME/.kube/rke2.yaml" -n cattle-system get pods

# kubectl --kubeconfig "$HOME/.kube/rke2.yaml" -n cattle-system logs -f rancher-<xxx>
# kubectl --kubeconfig "$HOME/.kube/rke2.yaml" -n cattle-system describe certificate
# kubectl --kubeconfig "$HOME/.kube/rke2.yaml" -n cattle-system describe issuer
# kubectl --kubeconfig "$HOME/.kube/rke2.yaml" -n cattle-system describe ingress

echo "https://${RKE_HOSTNAME}/dashboard/?setup=$(kubectl --kubeconfig "$HOME/.kube/rke2.yaml" get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}')"
# kubectl --kubeconfig "$HOME/.kube/rke2.yaml" get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}{{ "\n" }}'


# List All Container Images Running in a Cluster
kubectl --kubeconfig "$HOME/.kube/rke2.yaml" get pods --all-namespaces \
    -o jsonpath="{.items[*].spec.containers[*].image}" \
    | tr -s '[:space:]' '\n' | sort | uniq -c

## Dry run; print the corresponding API objects without creating them
# kubectl --kubeconfig "$HOME/.kube/rke2.yaml" run nginx --image=nginx --dry-run=client

## Delete a pod
# kubectl --kubeconfig "$HOME/.kube/rke2.yaml" delete pod nginx --now
