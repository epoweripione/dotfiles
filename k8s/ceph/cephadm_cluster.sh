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

CEPH_WORKDIR="$HOME/ceph" && mkdir -p "${CEPH_WORKDIR}"
CEPH_RELEASE="quincy"

if [[ -x "$(command -v pacman)" ]]; then
    get_os_desktop

    PackagesList=(
        chrony
        lvm2
    )
    InstallSystemPackages "" "${PackagesList[@]}"
fi

# cephadm: deploys and manages a Ceph cluster
# https://docs.ceph.com/en/quincy/cephadm/install
if [[ ! -x "$(command -v cephadm)" ]]; then
    INSTALLER_DOWNLOAD_URL="https://github.com/ceph/ceph/raw/${CEPH_RELEASE}/src/cephadm/cephadm"
    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/cephadm"

    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" && \
        chmod +x "${INSTALLER_DOWNLOAD_FILE}"
    
    if [[ -x "${INSTALLER_DOWNLOAD_FILE}" ]]; then
        sudo "${INSTALLER_DOWNLOAD_FILE}" add-repo --release "${CEPH_RELEASE}"
        sudo "${INSTALLER_DOWNLOAD_FILE}" install
        sudo "${INSTALLER_DOWNLOAD_FILE}" install ceph-common
    fi
fi

[[ ! -x "$(command -v cephadm)" ]] && colorEcho "${FUCHSIA}cephadm${BLUE} is not installed!" && exit 1

# Disable firewall
if systemctl is-enabled firewalld >/dev/null 2>&1; then
    sudo systemctl stop firewalld && sudo systemctl disable firewalld
    sudo iptables -F && sudo iptables -X && sudo iptables -F -t nat && sudo iptables -X -t nat
    sudo iptables -P FORWARD ACCEPT
fi

## Disable selinux
# sudo pacman -S selinux-utils libselinux-utils
# getenforce && sestatus && selinuxenabled
[[ -x "$(command -v setenforce)" ]] && sudo setenforce 0
[[ -s "/etc/selinux/config" ]] && sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/' "/etc/selinux/config"

# chrony
# /etc/chrony.conf
# chronyc activity
# journalctl -u chronyd
# chronyc sources -v
# chronyc sourcestats -v
sudo systemctl enable chronyd && sudo systemctl start chronyd

# timedatectl status
# timedatectl set-timezone Asia/Shanghai
# chronyc -a makestep


## NTP server on master nodes
# echo "allow 192.168.1.0/24" | sudo tee " /etc/chrony.conf" >/dev/null
# sudo systemctl restart chronyd


## NTP client on other nodes
# echo "server ceph-admin iburst" | sudo tee " /etc/chrony.conf" >/dev/null
# sudo systemctl restart chronyd


## hosts map
# sudo tee -a "/etc/hosts" >/dev/null <<-EOF
# 192.168.1.100 ceph-admin
# 192.168.1.101 ceph01
# 192.168.1.102 ceph02
# EOF

MONITOR_IP=""
CEPH_NODES=""
HOSTS_MAP="${CEPH_WORKDIR}/ceph.hosts"
if [[ -s "${HOSTS_MAP}" ]]; then
    HOSTS_ENTRY=$(< "${HOSTS_MAP}")

    FIRST_ENTRY=$(echo "${HOSTS_ENTRY}" | grep -Ev '^#' | grep -Ev '^$' | head -n1)
    if ! grep -q "${FIRST_ENTRY}" "/etc/hosts"; then
        echo "${HOSTS_ENTRY}" | sudo tee -a "/etc/hosts" >/dev/null
    fi

    # monitor node: 1st entry in hosts list
    MONITOR_IP=$(echo "${FIRST_ENTRY}" | awk '{print $1}')

    # other nodes
    CEPH_NODES=$(echo "${HOSTS_ENTRY}" | grep -Ev '^#' | grep -Ev '^$' | sed '1d' | awk '{print $2}')
fi

[[ -z "${MONITOR_IP}" ]] && MONITOR_IP=${1:-"192.168.1.100"}


# BOOTSTRAP A NEW CLUSTER
cephadm bootstrap --mon-ip "${MONITOR_IP}"

# Ceph Dashboard
# https://ceph-admin:8443/

## Change `admin` password
# ceph dashboard ac-user-set-password admin -i <new-password>

## Activate Telemetry module
# ceph telemetry on --license sharing-1-0

## ENABLE CEPH CLI
# cephadm shell
## To execute ceph commands, you can also run commands like this:
# cephadm shell -- ceph -s


# ADDING HOSTS
# https://docs.ceph.com/en/pacific/cephadm/host-management/#cephadm-adding-hosts
while read -r node; do
    # Install the cluster’s public SSH key in the new host’s root user’s authorized_keys file:
    # ssh-copy-id -f -i /etc/ceph/ceph.pub root@<new-host>
    ssh-copy-id -f -i "/etc/ceph/ceph.pub" "root@${node}"

    # Tell Ceph that the new node is part of the cluster:
    # ceph orch host add *<newhost>* [*<ip>*] [*<label1> ...*]
    node_ip=$(echo "${HOSTS_ENTRY}" | grep "${node}" | awk '{print $1}')
    ceph orch host add "${node}" "${node_ip}"
done <<<"${CEPH_NODES}"

ceph orch host ls


# ADDING ADDITIONAL MONS
# https://docs.ceph.com/en/pacific/cephadm/mon/#deploy-additional-monitors


# ADDING STORAGE
# https://docs.ceph.com/en/pacific/cephadm/osd/#cephadm-deploy-osds
ceph orch apply osd --all-available-devices

ceph orch device ls


# USING CEPH
# Deploy CephFS
# https://docs.ceph.com/en/pacific/cephadm/mds/#orchestrator-cli-cephfs
ceph fs volume create cephfs --placement=3

ceph osd pool create cephfs_data 32
ceph osd pool create cephfs_metadata 32

ceph fs new cephfs cephfs_metadata cephfs_data

ceph orch apply mds cephfs --placement=3


# Deploy RGWs
# https://docs.ceph.com/en/pacific/cephadm/rgw/#cephadm-deploy-rgw
ceph orch apply rgw rgw --placement=3

# ENABLING THE OBJECT GATEWAY MANAGEMENT FRONTEND
RGW_USER=$(radosgw-admin user create --uid=rgw --display-name=rgw --system)
RGW_ACCESS_KEY=$(echo "${RGW_USER}" | grep 'access_key' | cut -d\" -f4)
RGW_SECRET_KEY=$(echo "${RGW_USER}" | grep 'secret_key' | cut -d\" -f4)
ceph dashboard set-rgw-api-access-key -i "${RGW_ACCESS_KEY}"
ceph dashboard set-rgw-api-secret-key -i "${RGW_SECRET_KEY}"


# NFS Service
# https://docs.ceph.com/en/pacific/cephadm/nfs/#deploy-cephadm-nfs-ganesha
ceph osd pool create ganesha_data 32
ceph osd pool application enable ganesha_data nfs

ceph orch apply nfs nfs ganesha_data --placement=3


# Deploying iSCSI
# https://docs.ceph.com/en/pacific/cephadm/iscsi/#cephadm-iscsi
ceph osd pool create  iscsi_pool 32 32
ceph osd pool application enable iscsi_pool iscsi

ALL_IP=$(echo "${HOSTS_ENTRY}" | grep -Ev '^#' | grep -Ev '^$' | awk '{print $1}' | tr '\n' ',' | sed 's/,$//')
ALL_NODE=$(echo "${HOSTS_ENTRY}" | grep -Ev '^#' | grep -Ev '^$' | awk '{print $2}' | sed 's/^/    - /')
tee "${CEPH_WORKDIR}/iscsi.yaml" >/dev/null <<-EOF
service_type: iscsi
service_id: gw
placement:
  hosts:
${ALL_NODE}
spec:
  pool: iscsi_pool
  trusted_ip_list: "${ALL_IP}"
  api_user: admin
  api_password: admin
  api_secure: false
EOF

ceph orch apply -i "${CEPH_WORKDIR}/iscsi.yaml"


# RBD MIRRORING
# https://docs.ceph.com/en/pacific/rbd/rbd-mirroring/
ceph orch apply rbd-mirror --placement=3


# CEPHFS MIRRORING
# https://docs.ceph.com/en/pacific/dev/cephfs-mirroring/
ceph orch apply cephfs-mirror --placement=3


# HIGH AVAILABILITY SERVICE FOR RGW
# https://docs.ceph.com/en/pacific/cephadm/rgw/
RGW_INGRESS_IP=$(echo "${HOSTS_ENTRY}" | grep '#rgw-ingress' | awk '{print $2}')
[[ -z "${RGW_INGRESS_IP}" ]] && RGW_INGRESS_IP="192.168.1.200"
tee "${CEPH_WORKDIR}/rgw-ingress.yaml" >/dev/null <<-EOF
service_type: ingress
service_id: rgw.rgw
placement:
  count: 3
spec:
  backend_service: rgw.rgw
  virtual_ip: ${RGW_INGRESS_IP}/24
  frontend_port: 8080
  monitor_port: 1967
EOF

ceph orch apply -i "${CEPH_WORKDIR}/rgw-ingress.yaml"

# docker exec -it <haproxy-container-id> bash
# cat /var/lib/haproxy/haproxy.cfg


# HIGH-AVAILABILITY NFS
# https://docs.ceph.com/en/pacific/cephadm/nfs/
NFS_INGRESS_IP=$(echo "${HOSTS_ENTRY}" | grep '#nfs-ingress' | awk '{print $2}')
[[ -z "${NFS_INGRESS_IP}" ]] && NFS_INGRESS_IP="192.168.1.201"
tee "${CEPH_WORKDIR}/nfs-ingress.yaml" >/dev/null <<-EOF
service_type: ingress
service_id: nfs.nfs
placement:
  count: 3
spec:
  backend_service: nfs.nfs
  virtual_ip: ${NFS_INGRESS_IP}/24
  frontend_port: 2050
  monitor_port: 1968
EOF

ceph orch apply -i "${CEPH_WORKDIR}/nfs-ingress.yaml"


# CEPH CLI
ceph orch ls
ceph orch ps

ceph -s
ceph status


## Troubleshooting
# ceph log last cephadm
# ceph orch ls --service_name=alertmanager --format yaml
# ceph orch ps --service-name <service-name> --daemon-id <daemon-id> --format yaml
# ceph orch daemon restart <service-name>


## Powering down and rebooting a Ceph Storage cluster
## https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/3/html/administration_guide/understanding-process-managemnet-for-ceph#powering-down-and-rebooting-a-red-hat-ceph-storage-cluster-management
## Stop the clients from using the RBD images, NFS-Ganesha Gateway, and RADOS Gateway on this cluster and any other clients.
## On the NFS-Ganesha Gateway node:
# systemctl stop nfs-ganesha.service

## On the RADOS Gateway node:
# systemctl stop ceph-radosgw.target

## The cluster must be in healthy state (Health_OK and all PGs active+clean) before proceeding.
## Run `ceph status` on a node with the client keyrings, 
## for example, the Ceph Monitor or OpenStack controller nodes, to ensure the cluster is healthy.
# ceph status

## If you use the Ceph File System (CephFS), the CephFS cluster must be brought down.
## Taking a CephFS cluster down is done by reducing the number of ranks to 1, 
## setting the cluster_down flag, and then failing the last rank. For example:
# ceph fs set <fs_name> max_mds 1
# ceph mds deactivate <fs_name>:1 # rank 2 of 2
# ceph status # wait for rank 1 to finish stopping
# ceph fs set <fs_name> cluster_down true
# ceph mds fail <fs_name>:0

## Setting the cluster_down flag prevents standbys from taking over the failed rank.
## Set the noout, norecover, norebalance, nobackfill, nodown and pause flags.
## Run the following on a node with the client keyrings, 
## for example, the Ceph Monitor or OpenStack controller node:
# ceph osd set noout
# ceph osd set norecover
# ceph osd set norebalance
# ceph osd set nobackfill
# ceph osd set nodown
# ceph osd set pause

## Shut down the OSD nodes one by one:
# systemctl stop ceph-osd.target
# systemctl stop ceph-mon.target


## Rebooting the Red Hat Ceph Storage cluster
## Power on the monitor nodes:
# systemctl start ceph-mon.target

## Power on the OSD nodes:
# systemctl start ceph-osd.target

## Wait for all the nodes to come up.

## Verify all the services are up and the connectivity is fine between the nodes.
## Unset the noout, norecover, norebalance, nobackfill, nodown and pause flags.
## Run the following on a node with the client keyrings, 
## for example, the Ceph Monitor or OpenStack controller node:
# ceph osd unset noout
# ceph osd unset norecover
# ceph osd unset norebalance
# ceph osd unset nobackfill
# ceph osd unset nodown
# ceph osd unset pause

## If you use the Ceph File System (CephFS), 
## the CephFS cluster must be brought back up by setting the cluster_down flag to false:
# ceph fs set <fs_name> cluster_down false

## Start the RADOS Gateway and NFS-Ganesha Gateway.
## On the RADOS Gateway node:
# systemctl start ceph-radosgw.target

## On the NFS-Ganesha Gateway node:
# systemctl start nfs-ganesha.service

## Verify the cluster is in healthy state (Health_OK and all PGs active+clean).
## Run `ceph status` on a node with the client keyrings, 
## for example, the Ceph Monitor or OpenStack controller nodes, to ensure the cluster is healthy.
# ceph status


cd "${CURRENT_DIR}" || exit
