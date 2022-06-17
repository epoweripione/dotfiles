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

colorEchoN "${ORANGE}Are you sure to teardown the kubeadm cluster?[y/${CYAN}N${ORANGE}]: "
read -r -t 5 TEARDOWN_CLUSTER
echo ""

[[ "${TEARDOWN_CLUSTER}" != "y" && "${TEARDOWN_CLUSTER}" != "Y" ]] && exit 1

K8S_WORKDIR="$HOME/k8s"

# Tear down the cluster
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#tear-down
# https://kubernetes.io/zh/docs/tasks/administer-cluster/safely-drain-node/

# Cleanup helm install
helm uninstall ingress-nginx
helm uninstall calico

# Uninstall cert-manager
# Before continuing, ensure that all cert-manager resources that have been created by users have been deleted.
# You can check for any existing resources with the following command:
# kubectl get Issuers,ClusterIssuers,Certificates,CertificateRequests,Orders,Challenges --all-namespaces
helm --namespace cert-manager delete cert-manager
kubectl delete namespace cert-manager
[[ -s "${K8S_WORKDIR}/cert-manager.crds.yaml" ]] && kubectl delete -f "${K8S_WORKDIR}/cert-manager.crds.yaml"
# Namespace Stuck in Terminating State
kubectl delete apiservice v1beta1.webhook.cert-manager.io

# Cleanup deployment
[[ -s "${K8S_WORKDIR}/tigera-resources.yaml" ]] && kubectl delete -f "${K8S_WORKDIR}/tigera-resources.yaml"
[[ -s "${K8S_WORKDIR}/tigera-operator.yaml" ]] && kubectl delete -f "${K8S_WORKDIR}/tigera-operator.yaml"
[[ -s "${K8S_WORKDIR}/canal.yaml" ]] && kubectl delete -f "${K8S_WORKDIR}/canal.yaml"
[[ -s "${K8S_WORKDIR}/calicoctl.yaml" ]] && kubectl delete -f "${K8S_WORKDIR}/calicoctl.yaml"

# Teardown kube-prometheus
cd "${K8S_WORKDIR}/prometheus-manifests" && \
    kubectl delete --ignore-not-found=true -f manifests/ -f manifests/setup

# Kuboard
[[ -s "${K8S_WORKDIR}/kuboard.yaml" ]] && kubectl delete -f "${K8S_WORKDIR}/kuboard.yaml"
# Clear etcd date on master and nodes have label k8s.kuboard.cn/role=etcd
[[ -d "/usr/share/kuboard" ]] && rm -rf "/usr/share/kuboard"

# rook CEPH
# https://rook.io/docs/rook/latest/ceph-teardown.html
if [[ -d "${K8S_WORKDIR}/rook-ceph/cluster/examples/kubernetes/ceph" ]]; then
    # Delete the Block and File artifacts
    kubectl delete -f ../wordpress.yaml
    kubectl delete -f ../mysql.yaml
    kubectl delete -n rook-ceph cephblockpool replicapool
    kubectl delete storageclass rook-ceph-block
    # kubectl delete -f csi/cephfs/kube-registry.yaml
    [[ -s "${K8S_WORKDIR}/rook_ceph_filesystem_kube-registry.yaml" ]] && kubectl delete -f "${K8S_WORKDIR}/rook_ceph_filesystem_kube-registry.yaml"
    kubectl delete storageclass csi-cephfs

    # Delete the CephCluster CRD
    kubectl -n rook-ceph patch cephcluster rook-ceph --type merge -p '{"spec":{"cleanupPolicy":{"confirmation":"yes-really-destroy-data"}}}'
    kubectl -n rook-ceph delete cephcluster rook-ceph
    # Verify that the cluster CR has been deleted before continuing to the next step.
    kubectl -n rook-ceph get cephcluster
    # If the cleanupPolicy was applied, then wait for the rook-ceph-cleanup jobs to be completed on all the nodes.
    # These jobs will perform the following operations:
    # Delete the directory `/var/lib/rook` (or the path specified by the `dataDirHostPath` in `cluster.yaml`) on all the nodes
    # Wipe the data on the drives on all the nodes where OSDs were running in this cluster
    # Note: The cleanup jobs might not start if the resources created on top of Rook Cluster are not deleted completely.
    # See https://rook.io/docs/rook/v1.7/ceph-teardown.html#delete-the-block-and-file-artifacts

    # Delete the Operator and related Resources
    kubectl delete -f operator.yaml
    kubectl delete -f common.yaml
    kubectl delete -f crds.yaml

    # Delete the data on hosts
    # Connect to each machine and delete `/var/lib/rook`, or the path specified by the `dataDirHostPath` in `cluster.yaml`.
fi

# rook NFS
if [[ -d "${K8S_WORKDIR}/rook-nfs/cluster/examples/kubernetes/nfs" ]]; then
    cd "${K8S_WORKDIR}/rook-nfs/cluster/examples/kubernetes/nfs" || exit
    kubectl delete -f web-service.yaml
    kubectl delete -f web-rc.yaml
    kubectl delete -f busybox-rc.yaml
    [[ -s "${K8S_WORKDIR}/rook_nfs_pvc.yaml" ]] && kubectl delete -f "${K8S_WORKDIR}/rook_nfs_pvc.yaml"
    [[ -s "${K8S_WORKDIR}/rook_nfs_pv.yaml" ]] && kubectl delete -f "${K8S_WORKDIR}/rook_nfs_pv.yaml"
    [[ -s "${K8S_WORKDIR}/rook_nfs_sc.yaml" ]] && kubectl delete -f "${K8S_WORKDIR}/rook_nfs_sc.yaml"
    [[ -s "${K8S_WORKDIR}/rook_nfs_server.yaml" ]] && kubectl delete -f "${K8S_WORKDIR}/rook_nfs_server.yaml"
    [[ -s "${K8S_WORKDIR}/rook_nfs_xfs.yaml" ]] && kubectl delete -f "${K8S_WORKDIR}/rook_nfs_xfs.yaml"
    [[ -s "${K8S_WORKDIR}/rook_nfs_ceph.yaml" ]] && kubectl delete -f "${K8S_WORKDIR}/rook_nfs_ceph.yaml"
    [[ -s "${K8S_WORKDIR}/rook_nfs_rbac.yaml" ]] && kubectl delete -f "${K8S_WORKDIR}/rook_nfs_rbac.yaml"
    [[ -s "${K8S_WORKDIR}/rook_nfs_psp.yaml" ]] && kubectl delete -f "${K8S_WORKDIR}/rook_nfs_psp.yaml"
    [[ -s "${K8S_WORKDIR}/rook_nfs_scc.yaml" ]] && kubectl delete -f "${K8S_WORKDIR}/rook_nfs_scc.yaml"
    kubectl delete -f webhook.yaml
    kubectl delete -f operator.yaml
    kubectl delete -f crds.yaml
fi

# Remove nodes
ALL_NODES=$(kubectl get nodes | grep -v 'NAME' | awk '{print $1}')
CP_NODES=$(kubectl get nodes | grep 'control-plane\|master' | awk '{print $1}')
WORKER_NODES=$(kubectl get nodes | grep -v 'NAME\|control-plane\|master' | awk '{print $1}')

# Remove worker nodes
while read -r node; do
    [[ -n "${node}" ]] && kubectl drain "${node}" --delete-emptydir-data --force --ignore-daemonsets
done <<<"${WORKER_NODES}"

# Remove control-plane nodes
while read -r node; do
    [[ -n "${node}" ]] && kubectl drain "${node}" --delete-emptydir-data --force --ignore-daemonsets
done <<<"${CP_NODES}"

# reset or clean up iptables rules or IPVS tables
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X && \
    sudo ipvsadm -C

# remove all nodes
while read -r node; do
    [[ -n "${node}" ]] && kubectl delete node "${node}"
done <<<"${ALL_NODES}"

# Clean up the control plane
sudo kubeadm reset -f

rm "$HOME/.kube/config"

# Cleanup add-ons
sudo ip link delete cni0
sudo ip link delete flannel.1
sudo rm -rf /var/lib/cni/ && sudo rm -f /etc/cni/net.d/*

## IP tunnel: tunl0@NONE
# sudo ip tunnel show
# if lsmod | grep -q 'ipip' 2>/dev/null; then
#     sudo modprobe -r ipip
# fi


cd "${CURRENT_DIR}" || exit