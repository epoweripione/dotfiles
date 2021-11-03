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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

K8S_WORKDIR="$HOME/k8s" && mkdir -p "${K8S_WORKDIR}"

cp "${MY_SHELL_SCRIPTS}/k8s/ceph"/*.yaml "${K8S_WORKDIR}"

# Rook: Open-Source, Cloud-Native Storage for Kubernetes
# Production ready management for File, Block and Object Storage
# https://rook.io/

## Ceph Prerequisites
## https://rook.io/docs/rook/latest/pre-reqs.html
## In order to configure the Ceph storage cluster, at least one of these local storage options are required:
## Raw devices (no partitions or formatted filesystems)
## Raw partitions (no formatted filesystem)
## PVs available from a storage class in block mode
## You can confirm whether your partitions or devices are formatted with filesystems with the following command.
# lsblk -f

CHECK_URL="https://api.github.com/repos/rook/rook/branches"
ROOK_BRANCH=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | grep 'name' | cut -d\" -f4 | grep '^release' | sort -rV | head -n1)

[[ -d "${K8S_WORKDIR}/rook-ceph" ]] && rm -rf "${K8S_WORKDIR}/rook-ceph"

# git clone --single-branch --branch "${ROOK_BRANCH}" "https://github.com/rook/rook" "${K8S_WORKDIR}/rook-ceph"
Git_Clone_Update_Branch "rook/rook" "${K8S_WORKDIR}/rook-ceph" "github.com" "${ROOK_BRANCH}"


# A simple Rook cluster can be created with the following kubectl commands and example manifests.
cd "${K8S_WORKDIR}/rook-ceph/cluster/examples/kubernetes/ceph"

# Deploy the Rook Operator
kubectl create -f crds.yaml -f common.yaml -f operator.yaml
kubectl wait -n rook-ceph --for=condition=ready pod --all --timeout=120s

# Create a Ceph Cluster
kubectl create -f cluster.yaml
kubectl wait -n rook-ceph --for=condition=ready pod --all --timeout=120s


# Rook Toolbox
[[ -s "${K8S_WORKDIR}/rook_toolbox.yaml" ]] && kubectl create -f "${K8S_WORKDIR}/rook_toolbox.yaml"

# Wait for the toolbox pod to download its container and get to the running state:
kubectl -n rook-ceph rollout status deploy/rook-ceph-tools

## Once the rook-ceph-tools pod is running, you can connect to it with:
# kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- bash

## All available tools in the toolbox are ready for your troubleshooting needs.
## Example:
## ceph status
## ceph osd status
## ceph df
## rados df

## When you are done with the toolbox, you can remove the deployment:
# kubectl -n rook-ceph delete deploy/rook-ceph-tools


# Toolbox Job
[[ -s "${K8S_WORKDIR}/rook_toolbox_job_ceph_status.yaml" ]] && kubectl create -f "${K8S_WORKDIR}/rook_toolbox_job_ceph_status.yaml"

# After the job completes, see the results of the script:
kubectl -n rook-ceph logs -l job-name=rook-ceph-toolbox-job


# Storage
# For a walkthrough of the three types of storage exposed by Rook, see the guides for:
# Block: Create block storage to be consumed by a pod (RWO)
# https://rook.io/docs/rook/latest/ceph-block.html
[[ -s "${K8S_WORKDIR}/rook_ceph_storageclass.yaml" ]] && kubectl create -f "${K8S_WORKDIR}/rook_ceph_storageclass.yaml"
# Consume the storage: Wordpress sample
cd "${K8S_WORKDIR}/rook-ceph/cluster/examples/kubernetes"
kubectl create -f mysql.yaml
kubectl create -f wordpress.yaml
kubectl get pvc
kubectl get svc wordpress


## Shared Filesystem: Create a filesystem to be shared across multiple pods (RWX)
## https://rook.io/docs/rook/latest/ceph-filesystem.html
# [[ -s "${K8S_WORKDIR}/rook_ceph_filesystem.yaml" ]] && kubectl create -f "${K8S_WORKDIR}/rook_ceph_filesystem.yaml"
# kubectl -n rook-ceph get pod -l app=rook-ceph-mds
## To see detailed status of the filesystem, start and connect to the Rook toolbox.
## A new line will be shown with `ceph status` for the mds service.
## Provision Storage
# [[ -s "${K8S_WORKDIR}/rook_ceph_filesystem_storageclass.yaml" ]] && kubectl create -f "${K8S_WORKDIR}/rook_ceph_filesystem_storageclass.yaml"
## Consume the Shared Filesystem: K8s Registry Sample
# [[ -s "${K8S_WORKDIR}/rook_ceph_filesystem_kube-registry.yaml" ]] && kubectl create -f "${K8S_WORKDIR}/rook_ceph_filesystem_kube-registry.yaml"
## You now have a docker registry which is HA with persistent storage.


## Object: Create an object store that is accessible inside or outside the Kubernetes cluster
## https://rook.io/docs/rook/latest/ceph-object.html
# [[ -s "${K8S_WORKDIR}/rook_ceph_object.yaml" ]] && kubectl create -f "${K8S_WORKDIR}/rook_ceph_object.yaml"
# kubectl -n rook-ceph get pod -l app=rook-ceph-rgw
### Connect to an External Object Store
## [[ -s "${K8S_WORKDIR}/rook_ceph_object-external.yaml" ]] && kubectl create -f "${K8S_WORKDIR}/rook_ceph_object-external.yaml"
## kubectl -n rook-ceph get svc -l app=rook-ceph-rgw
## Create a Bucket
# [[ -s "${K8S_WORKDIR}/rook_ceph_object_bucket.yaml" ]] && kubectl create -f "${K8S_WORKDIR}/rook_ceph_object_bucket.yaml"


# Ceph Dashboard
kubectl -n rook-ceph get service
# Login Credentials
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo

# Viewing the Dashboard External to the Cluster
# Node Port
[[ -s "${K8S_WORKDIR}/rook_ceph_dashboard_nodeport.yaml" ]] && kubectl create -f "${K8S_WORKDIR}/rook_ceph_dashboard_nodeport.yaml"

## Load Balancer
# [[ -s "${K8S_WORKDIR}/rook_ceph_dashboard_loadbalancer.yaml" ]] && kubectl create -f "${K8S_WORKDIR}/rook_ceph_dashboard_loadbalancer.yaml"

kubectl -n rook-ceph get service

## Ingress Controller
# [[ -s "${K8S_WORKDIR}/rook_ceph_dashboard_ingress.yaml" ]] && kubectl create -f "${K8S_WORKDIR}/rook_ceph_dashboard_ingress.yaml"
# kubectl -n rook-ceph get ingress
## And the new Secret for the TLS certificate:
# kubectl -n rook-ceph get secret rook-ceph.k8s.corp


# Prometheus Monitoring
# https://rook.io/docs/rook/latest/ceph-monitoring.html


# Advanced Configuration
# https://rook.io/docs/rook/latest/ceph-advanced-configuration.html


cd "${CURRENT_DIR}" || exit
