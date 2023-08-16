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
    colorEcho "${FUCHSIA}kubeadm${BLUE}: Checking Pre-requisite packages..."
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
INSTALLER_INSTALL_PATH="/usr/local/bin"
[[ "${OS_INFO_RELEASE}" == "flatcar" ]] && INSTALLER_INSTALL_PATH="/opt/bin"

CNI_INSTALL_PATH="/opt/cni/bin"

sudo mkdir -p "${INSTALLER_INSTALL_PATH}"
sudo mkdir -p "${CNI_INSTALL_PATH}"
sudo mkdir -p "/etc/systemd/system/kubelet.service.d"

# Install CNI plugins (required for most pod network):
INSTALLER_CHECK_URL="https://api.github.com/repos/containernetworking/plugins/releases/latest"
CNI_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${INSTALLER_CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null)
INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-${OS_INFO_TYPE}-${OS_INFO_ARCH}-${CNI_VERSION}.tgz"
INSTALLER_DOWNLOAD_FILE="${WORKDIR}/cni-plugins.tgz"

colorEcho "${BLUE}Installing ${FUCHSIA}CNI plugins ${YELLOW}${CNI_VERSION}${BLUE}..."
colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"
curl_download_status=$?
if [[ ${curl_download_status} -eq 0 ]]; then
    sudo tar -xzf "${INSTALLER_DOWNLOAD_FILE}" -C "${CNI_INSTALL_PATH}"
fi

# Install crictl (required for kubeadm / Kubelet Container Runtime Interface (CRI))
colorEcho "${BLUE}Checking latest version for ${FUCHSIA}crictl${BLUE}..."
INSTALLER_CHECK_URL="https://api.github.com/repos/kubernetes-sigs/cri-tools/releases/latest"
CRICTL_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${INSTALLER_CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null)

INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-${OS_INFO_TYPE}-${OS_INFO_ARCH}.tar.gz"
INSTALLER_DOWNLOAD_FILE="${WORKDIR}/crictl.tar.gz"

if [[ -x "$(command -v crictl)" ]]; then
    INSTALLER_VER_CURRENT=v$(crictl --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    if version_le "${CRICTL_VERSION}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_DOWNLOAD_URL=""
    fi
fi

if [[ -n "${INSTALLER_DOWNLOAD_URL}" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}crictl ${YELLOW}${CRICTL_VERSION}${BLUE}..."
    colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"
    curl_download_status=$?
    if [[ ${curl_download_status} -eq 0 ]]; then
        sudo tar -xzf "${INSTALLER_DOWNLOAD_FILE}" -C "${INSTALLER_INSTALL_PATH}"
    fi
fi

# Install kubeadm, kubelet, kubectl and add a kubelet systemd service:
colorEcho "${BLUE}Checking latest version for ${FUCHSIA}kubeadm, kubelet, kubectl${BLUE}..."
K8S_LATEST_RELEASE="$(curl "${CURL_CHECK_OPTS[@]}" https://dl.k8s.io/release/stable.txt)"

K8S_VERSION=${1:-"${K8S_LATEST_RELEASE}"}
INSTALLER_DOWNLOAD_URL="https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/${OS_INFO_TYPE}/${OS_INFO_ARCH}"

if [[ -x "$(command -v kubeadm)" ]]; then
    INSTALLER_VER_CURRENT=v$(kubeadm version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    if version_le "${K8S_VERSION}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_DOWNLOAD_URL=""
    fi
fi

if [[ -n "${INSTALLER_DOWNLOAD_URL}" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}kubeadm, kubelet, kubectl ${YELLOW}${K8S_VERSION}${BLUE}..."
    colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
    cd "${WORKDIR}" && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" --remote-name-all "${INSTALLER_DOWNLOAD_URL}"/{kubeadm,kubelet,kubectl} && \
        sudo cp -f {kubeadm,kubelet,kubectl} "${INSTALLER_INSTALL_PATH}" && \
        sudo chmod +x "${INSTALLER_INSTALL_PATH}"/{kubeadm,kubelet,kubectl}
fi

if [[ ! -s "/etc/systemd/system/kubelet.service" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}kubelet${BLUE} service..."
    INSTALLER_CHECK_URL="https://api.github.com/repos/kubernetes/release/releases/latest"
    KUBELET_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${INSTALLER_CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null)

    INSTALLER_DOWNLOAD_URL=""
    [[ -x "/usr/bin/apt-get" ]] && INSTALLER_DOWNLOAD_URL="https://raw.githubusercontent.com/kubernetes/release/${KUBELET_VERSION}/cmd/kubepkg/templates/latest/deb"
    [[ -x "/usr/bin/yum" ]] && INSTALLER_DOWNLOAD_URL="https://raw.githubusercontent.com/kubernetes/release/${KUBELET_VERSION}/cmd/kubepkg/templates/latest/rpm"
    [[ -x "/usr/bin/dnf" ]] && INSTALLER_DOWNLOAD_URL="https://raw.githubusercontent.com/kubernetes/release/${KUBELET_VERSION}/cmd/kubepkg/templates/latest/rpm"

    if [[ -n "${INSTALLER_DOWNLOAD_URL}" ]]; then
        curl "${CURL_DOWNLOAD_OPTS[@]}" "${INSTALLER_DOWNLOAD_URL}/kubelet/lib/systemd/system/kubelet.service" \
            | sed "s:/usr/bin:${INSTALLER_INSTALL_PATH}:g" \
            | sudo tee "/etc/systemd/system/kubelet.service"

        curl "${CURL_DOWNLOAD_OPTS[@]}" "${INSTALLER_DOWNLOAD_URL}/kubeadm/10-kubeadm.conf" \
            | sed "s:/usr/bin:${INSTALLER_INSTALL_PATH}:g" \
            | sudo tee "/etc/systemd/system/kubelet.service.d/10-kubeadm.conf"
    fi
fi

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
if [[ ! -x "$(command -v kubectl-krew)" ]]; then
    (
        set -x; cd "$(mktemp -d)" &&
        OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
        ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
        KREW="krew-${OS}_${ARCH}" &&
        curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
        tar zxvf "${KREW}.tar.gz" &&
        ./"${KREW}" install krew
    )
fi

if [[ -d "${KREW_ROOT:-$HOME/.krew}" ]]; then
    export PATH=$PATH:${KREW_ROOT:-$HOME/.krew}/bin
fi

if [[ -x "$(command -v kubectl-krew)" ]]; then
    # kubectl krew version
    kubectl krew upgrade
fi


# Install calicoctl
# https://projectcalico.docs.tigera.io/maintenance/clis/calicoctl/install
colorEcho "${BLUE}Checking latest version for ${FUCHSIA}calicoctl${BLUE}..."
INSTALLER_CHECK_URL="https://api.github.com/repos/projectcalico/calico/releases/latest"
CALICO_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${INSTALLER_CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null)

INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/projectcalico/calico/releases/download/${CALICO_VERSION}/calicoctl-${OS_INFO_TYPE}-${OS_INFO_ARCH}"
INSTALLER_DOWNLOAD_FILE="${WORKDIR}/calicoctl"

if [[ -x "$(command -v kubectl-calico)" ]]; then
    INSTALLER_VER_CURRENT=v$(kubectl-calico version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    if version_le "${CALICO_VERSION}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_DOWNLOAD_URL=""
    fi
fi

if [[ -n "${INSTALLER_DOWNLOAD_URL}" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}calicoctl ${YELLOW}${CALICO_VERSION}${BLUE}..."
    colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"
    curl_download_status=$?
    if [[ ${curl_download_status} -eq 0 ]]; then
        sudo cp -f "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_INSTALL_PATH}/kubectl-calico" && sudo chmod +x "${INSTALLER_INSTALL_PATH}/kubectl-calico"
    fi
fi


cd "${CURRENT_DIR}" || exit
