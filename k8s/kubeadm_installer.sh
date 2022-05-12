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

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type
[[ -z "${OS_INFO_ARCH}" ]] && get_arch
[[ -z "${OS_INFO_RELEASE}" ]] && get_os_release

[[ "${OS_INFO_TYPE}" != "linux" ]] && colorEcho "${RED}Only support Linux!" && exit 1


if [[ ! -x "$(command -v docker)" ]]; then
    [[ -s "${MY_SHELL_SCRIPTS}/installer/docker_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/docker_installer.sh"
fi
[[ ! -x "$(command -v docker)" ]] && colorEcho "${FUCHSIA}docker${BLUE} is not installed!" && exit 1

if [[ -x "$(command -v pacman)" ]]; then
    PackagesList=(
        conntrack
        ethtool
        ipvsadm
        ipset
        lvm2
        nfs-common
        nfs-utils
        socat
    )
    for TargetPackage in "${PackagesList[@]}"; do
        if checkPackageNeedInstall "${TargetPackage}"; then
            colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
            sudo pacman --noconfirm -S "${TargetPackage}"
        fi
    done
fi

# Kubeadm: Aggregator for issues filed against kubeadm
# https://github.com/kubernetes/kubeadm
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/
EXEC_INSTALL_PATH="/usr/local/bin"
[[ "${OS_INFO_RELEASE}" == "flatcar" ]] && EXEC_INSTALL_PATH="/opt/bin"

CNI_INSTALL_PATH="/opt/cni/bin"

sudo mkdir -p "${EXEC_INSTALL_PATH}"
sudo mkdir -p "${CNI_INSTALL_PATH}"
sudo mkdir -p "/etc/systemd/system/kubelet.service.d"

# Install CNI plugins (required for most pod network):
colorEcho "${BLUE}Installing ${FUCHSIA}CNI plugins${BLUE}..."
CHECK_URL="https://api.github.com/repos/containernetworking/plugins/releases/latest"
CNI_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty')
DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-${OS_INFO_TYPE}-${OS_INFO_ARCH}-${CNI_VERSION}.tgz"

DOWNLOAD_FILENAME="${WORKDIR}/cni-plugins.tgz"
curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" && \
    sudo tar -xzf "${DOWNLOAD_FILENAME}" -C "${CNI_INSTALL_PATH}"

# Install crictl (required for kubeadm / Kubelet Container Runtime Interface (CRI))
colorEcho "${BLUE}Installing ${FUCHSIA}crictl${BLUE}..."
CHECK_URL="https://api.github.com/repos/kubernetes-sigs/cri-tools/releases/latest"
CRICTL_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty')
DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-${OS_INFO_TYPE}-${OS_INFO_ARCH}.tar.gz"

DOWNLOAD_FILENAME="${WORKDIR}/crictl.tar.gz"
curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" && \
    sudo tar -xzf "${DOWNLOAD_FILENAME}" -C "${EXEC_INSTALL_PATH}"

# Install kubeadm, kubelet, kubectl and add a kubelet systemd service:
colorEcho "${BLUE}Installing ${FUCHSIA}kubeadm, kubelet, kubectl${BLUE}..."
LATEST_RELEASE="$(curl "${CURL_CHECK_OPTS[@]}" https://dl.k8s.io/release/stable.txt)"
RELEASE=${1:-"${LATEST_RELEASE}"}
DOWNLOAD_URL="https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/${OS_INFO_TYPE}/${OS_INFO_ARCH}"
# cd "${EXEC_INSTALL_PATH}" && \
#     sudo curl "${CURL_DOWNLOAD_OPTS[@]}" --remote-name-all "${DOWNLOAD_URL}"/{kubeadm,kubelet,kubectl} && \
#     sudo chmod +x {kubeadm,kubelet,kubectl}
cd "${WORKDIR}" && \
    curl "${CURL_DOWNLOAD_OPTS[@]}" --remote-name-all "${DOWNLOAD_URL}"/{kubeadm,kubelet,kubectl} && \
    sudo cp -f {kubeadm,kubelet,kubectl} "${EXEC_INSTALL_PATH}" && \
    sudo chmod +x "${EXEC_INSTALL_PATH}"/{kubeadm,kubelet,kubectl}

CHECK_URL="https://api.github.com/repos/kubernetes/release/releases/latest"
RELEASE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty')
DOWNLOAD_URL="https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb"

curl "${CURL_DOWNLOAD_OPTS[@]}" "${DOWNLOAD_URL}/kubelet/lib/systemd/system/kubelet.service" \
    | sed "s:/usr/bin:${EXEC_INSTALL_PATH}:g" \
    | sudo tee "/etc/systemd/system/kubelet.service"

curl "${CURL_DOWNLOAD_OPTS[@]}" "${DOWNLOAD_URL}/kubeadm/10-kubeadm.conf" \
    | sed "s:/usr/bin:${EXEC_INSTALL_PATH}:g" \
    | sudo tee "/etc/systemd/system/kubelet.service.d/10-kubeadm.conf"

## ipvs
## grep -e ipvs -e nf_conntrack /lib/modules/$(uname -r)/modules.builtin
## lsmod | grep -e ip_vs -e nf_conntrack
# colorEcho "${BLUE}Setting ${FUCHSIA}ipvs${BLUE}..."
# if ! grep -q "ip_vs" "/etc/systemd/system/kubelet.service.d/10-proxy-ipvs.conf" 2>/dev/null; then
#     # https://github.com/kubernetes/kubernetes/pull/70398
#     # use 'nf_conntrack' instead of 'nf_conntrack_ipv4' for linux kernel >= 4.19
#     KERNEL_MOD_NF_CONNTRACK=$(find /lib/modules/$(uname -r) -name "nf_conntrack_ipv4" 2>/dev/null)
#     [[ -n "${KERNEL_MOD_NF_CONNTRACK}" ]] && KERNEL_MOD_NF_CONNTRACK="nf_conntrack_ipv4" || KERNEL_MOD_NF_CONNTRACK="nf_conntrack"

#     sudo tee "/etc/systemd/system/kubelet.service.d/10-proxy-ipvs.conf" >/dev/null <<-EOF
# [Service]
# ExecStartPre=-/sbin/modprobe ip_vs
# ExecStartPre=-/sbin/modprobe ip_vs_rr
# ExecStartPre=-/sbin/modprobe ip_vs_wrr
# ExecStartPre=-/sbin/modprobe ip_vs_sh
# ExecStartPre=-/sbin/modprobe ${KERNEL_MOD_NF_CONNTRACK}
# EOF
# fi

## zsh auto-completion
# if ! grep -q "kubectl completion zsh" "$HOME/.zshrc" 2>/dev/null; then
#     echo -e '\n# kubectl completion\nsource <(kubectl completion zsh)' >> "$HOME/.zshrc"
# fi

# Enable and start kubelet:
colorEcho "${BLUE}Enable and start ${FUCHSIA}kubelet${BLUE}..."
sudo systemctl enable --now kubelet


# Krew is the package manager for kubectl plugins
# https://github.com/kubernetes-sigs/krew
colorEcho "${BLUE}Installing ${FUCHSIA}krew${BLUE}..."
(
    set -x; cd "$(mktemp -d)" &&
    OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
    ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz" &&
    tar zxvf krew.tar.gz &&
    KREW=./krew-"${OS}_${ARCH}" &&
    "$KREW" install krew
)
if [[ -d "${KREW_ROOT:-$HOME/.krew}" ]]; then
    export PATH=$PATH:${KREW_ROOT:-$HOME/.krew}/bin
fi


# Install calicoctl
# https://docs.projectcalico.org/getting-started/clis/calicoctl/install
colorEcho "${BLUE}Installing ${FUCHSIA}calicoctl${BLUE}..."
CHECK_URL="https://api.github.com/repos/projectcalico/calicoctl/releases/latest"
CALICO_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty')
DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/projectcalico/calicoctl/releases/download/${CALICO_VERSION}/calicoctl"

DOWNLOAD_FILENAME="${WORKDIR}/calicoctl"
curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" && \
    sudo cp -f "${DOWNLOAD_FILENAME}" "${EXEC_INSTALL_PATH}" && \
    sudo chmod +x "${EXEC_INSTALL_PATH}/calicoctl"


cd "${CURRENT_DIR}" || exit
