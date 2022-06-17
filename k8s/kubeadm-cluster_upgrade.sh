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

# Upgrading kubeadm clusters
# https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/
# Upgrading control plane nodes
# For the first control plane node
# Upgrade kubeadm
KUBEADM_VERSION=${1:-"v1.22.1"}
"${MY_SHELL_SCRIPTS}/k8s/kubeadm_installer.sh" "${KUBEADM_VERSION}"

kubeadm version
kubeadm upgrade plan
sudo kubeadm upgrade apply "${KUBEADM_VERSION}"

## Manually upgrade your CNI provider plugin
# Upgrade Calico on Kubernetes
# https://docs.projectcalico.org/maintenance/kubernetes-upgrade
alias calicoctl="kubectl exec -i -n kube-system calicoctl -- /calicoctl"
helm upgrade calico projectcalico/tigera-operator
# calicoctl get hep -owide | grep '*' | awk '{print $1}' \
#     | xargs -I {} kubectl exec -i -n kube-system calicoctl -- /calicoctl label hostendpoint {} host-endpoint-upgrade=
# cat > allow-all-upgrade.yaml <<EOF
# apiVersion: projectcalico.org/v3
# kind: GlobalNetworkPolicy
# metadata:
#   name: allow-all-upgrade
# spec:
#   selector: has(host-endpoint-upgrade)
#   types:
#   - Ingress
#   - Egress
#   ingress:
#   - action: Log
#   - action: Allow
#   egress:
#   - action: Log
#   - action: Allow
# EOF
# calicoctl apply -f - < allow-all-upgrade.yaml


# Upgrade NGINX Ingress Controller for Kubernetes
helm upgrade --reuse-values ngx-ingress ingress-nginx/ingress-nginx


## For the other control plane nodes
## Same as the first control plane node but use:
# sudo kubeadm upgrade node


cd "${CURRENT_DIR}" || exit
