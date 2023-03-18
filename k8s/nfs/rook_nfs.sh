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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

K8S_WORKDIR="$HOME/k8s" && mkdir -p "${K8S_WORKDIR}"

cp "${MY_SHELL_SCRIPTS}/k8s/nfs"/*.yaml "${K8S_WORKDIR}"

# Rook: Open-Source, Cloud-Native Storage for Kubernetes
# Production ready management for File, Block and Object Storage
# https://rook.io/
INSTALLER_CHECK_URL="https://api.github.com/repos/rook/nfs/tags"
ROOK_TAG=$(curl "${CURL_CHECK_OPTS[@]}" "${INSTALLER_CHECK_URL}" | grep 'name' | grep -Ev 'main|master|alpha|beta|rc' | cut -d\" -f4 | sort -rV | head -n1)

[[ -d "${K8S_WORKDIR}/rook-nfs" ]] && rm -rf "${K8S_WORKDIR}/rook-nfs"

# git clone --single-branch --branch "${ROOK_TAG}" "https://github.com/rook/nfs" "${K8S_WORKDIR}/rook-nfs"
Git_Clone_Update_Branch "rook/nfs" "${K8S_WORKDIR}/rook-nfs" "github.com" "${ROOK_TAG}"


# Deploy NFS Operator
cd "${K8S_WORKDIR}/rook-nfs/cluster/examples/kubernetes/nfs" || exit
kubectl create -f crds.yaml
kubectl create -f operator.yaml

kubectl wait -n rook-nfs-system --for=condition=ready pod --all --timeout=120s


# Deploy NFS Admission Webhook (Optional)
# First, ensure that cert-manager is installed
kubectl wait -n cert-manager --for=condition=ready pod --all --timeout=120s

# Once cert-manager is running, you can now deploy the NFS webhook
kubectl create -f webhook.yaml

kubectl wait -n rook-nfs-system --for=condition=ready pod --all --timeout=120s

kubectl -n rook-nfs-system get pod -o wide


# Create Pod Security Policies (Recommended)
[[ -s "${K8S_WORKDIR}/rook_nfs_psp.yaml" ]] && kubectl create -f "${K8S_WORKDIR}/rook_nfs_psp.yaml"

# Create ServiceAccount and RBAC rules
[[ -s "${K8S_WORKDIR}/rook_nfs_rbac.yaml" ]] && kubectl create -f "${K8S_WORKDIR}/rook_nfs_rbac.yaml"


# Create and Initialize NFS Server
# Default StorageClass example: this example requires a default StorageClass to exist
[[ -s "${K8S_WORKDIR}/rook_nfs_server.yaml" ]] && kubectl create -f "${K8S_WORKDIR}/rook_nfs_server.yaml"


## Rook Ceph volume example
# [[ -s "${K8S_WORKDIR}/rook_nfs_ceph.yaml" ]] && kubectl create -f "${K8S_WORKDIR}/rook_nfs_ceph.yaml"


# Verify NFS Server
kubectl -n rook-nfs get nfsservers.nfs.rook.io

# Verify that the NFS server pod is up and running:
kubectl -n rook-nfs get pod -l app=rook-nfs


# Accessing the Export
[[ -s "${K8S_WORKDIR}/rook_nfs_sc.yaml" ]] && kubectl create -f "${K8S_WORKDIR}/rook_nfs_sc.yaml"
[[ -s "${K8S_WORKDIR}/rook_nfs_pvc.yaml" ]] && kubectl create -f "${K8S_WORKDIR}/rook_nfs_pvc.yaml"


# Consuming the Export
kubectl create -f busybox-rc.yaml
kubectl create -f web-rc.yaml

kubectl wait -l app=nfs-demo --for=condition=ready pod --all --timeout=120s
kubectl get pod -l app=nfs-demo

# In order to be able to reach the web server over the network, let’s create a service for it:
kubectl create -f web-service.yaml


# Troubleshooting
# If the NFS server pod does not come up, the first step would be to examine the NFS operator’s logs:
kubectl -n rook-nfs-system logs -l app=rook-nfs-operator


cd "${CURRENT_DIR}" || exit
