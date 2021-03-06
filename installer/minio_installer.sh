#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

# MinIO - High Performance, Kubernetes Native Object Storage
# https://github.com/minio/minio
# http://docs.minio.org.cn/docs/
EXEC_INSTALL_PATH="/usr/local/bin"

DOWNLOAD_DOMAIN="https://dl.min.io"
# [[ "${THE_WORLD_BLOCKED}" == "true" ]] && DOWNLOAD_DOMAIN="http://dl.minio.org.cn"

# MINIO SERVER
APP_INSTALL_NAME="minio"
EXEC_INSTALL_NAME="minio"
DOWNLOAD_FILENAME="${WORKDIR}/${EXEC_INSTALL_NAME}"

[[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]] && IS_INSTALL="no" || IS_INSTALL="yes"

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch

    DOWNLOAD_URL="${DOWNLOAD_DOMAIN}/server/minio/release/${OS_INFO_TYPE}-${OS_INFO_ARCH}/${EXEC_INSTALL_NAME}"

    colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
    curl_download_status=$?

    if [[ ${curl_download_status} -eq 0 ]]; then
        sudo cp -f "${DOWNLOAD_FILENAME}" "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}" && \
            sudo chmod +x "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}"
    fi
fi

# MINIO CLIENT
APP_INSTALL_NAME="mc"
EXEC_INSTALL_NAME="mc"
DOWNLOAD_FILENAME="${WORKDIR}/${EXEC_INSTALL_NAME}"

[[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]] && IS_INSTALL="no" || IS_INSTALL="yes"

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch

    DOWNLOAD_URL="${DOWNLOAD_DOMAIN}/client/mc/release/${OS_INFO_TYPE}-${OS_INFO_ARCH}/${EXEC_INSTALL_NAME}"

    colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
    curl_download_status=$?

    if [[ ${curl_download_status} -eq 0 ]]; then
        sudo cp -f "${DOWNLOAD_FILENAME}" "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}" && \
            sudo chmod +x "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}"
    fi
fi


## Run the MinIO Server with Non-Default Credentials
# MINIO_SERVER_URL="https://minio.example.net"
# MINIO_ROOT_USER=minio-admin
# MINIO_ROOT_PASSWORD=$(cat /dev/urandom | head -c32 | base64 - | head -c16)
# MINIO_ENCRYPTION_KEY=$(cat /dev/urandom | head -c32 | base64 -)
# MINIO_SERVER_VOLUMES="/mnt/sda1"
# MINIO_MC_ALIAS="minio"

# tee "$HOME/minio_server_config.env" <<-EOF
# export MINIO_ROOT_USER=${MINIO_ROOT_USER}
# export MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}
# export MINIO_SERVER_URL=${MINIO_SERVER_URL}
# export MINIO_KMS_SECRET_KEY=minio-encryption-key:${MINIO_ENCRYPTION_KEY}
# export MINIO_SERVER_VOLUMES=${MINIO_SERVER_VOLUMES}
# export MINIO_MC_ALIAS=${MINIO_MC_ALIAS}
# EOF

# source "$HOME/minio_server_config.env"

# minio server "${MINIO_SERVER_VOLUMES}" --console-address ":9001"
# nohup minio server "${MINIO_SERVER_VOLUMES}" --console-address ":9001" >/dev/null 2>&1 & disown


## Systemd service for MinIO
## https://github.com/minio/minio-service/tree/master/linux-systemd
# sudo tee "/etc/default/minio" <<-EOF
# # Volume to be used for MinIO server.
# MINIO_VOLUMES="${MINIO_SERVER_VOLUMES}"
# # Use if you want to run MinIO on a custom port.
# MINIO_OPTS="--address :9000 --console-address :9001"
# # Root user for the server.
# MINIO_ROOT_USER=${MINIO_ROOT_USER}
# # Root secret for the server.
# MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}
# EOF

# colorEcho "${BLUE}  Installing ${FUCHSIA}minio systemd service${BLUE}..."
# SERVICE_FILENAME="/etc/systemd/system/minio.service"
# DOWNLOAD_URL="https://raw.githubusercontent.com/minio/minio-service/master/linux-systemd/minio.service"
# sudo curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${SERVICE_FILENAME}" "${DOWNLOAD_URL}"
# curl_download_status=$?
# if [[ ${curl_download_status} -eq 0 ]]; then
#     MINIO_RUN_USER=$(id -un) && MINIO_RUN_GROUP=$(id -gn)
#     sudo sed -i -e "s/User=minio-user/User=${MINIO_RUN_USER}/" -e "s/Group=minio-user/Group=${MINIO_RUN_GROUP}/" "${SERVICE_FILENAME}"
#     sudo systemctl enable minio.service && sudo systemctl start minio.service && sudo systemctl status minio.service
# fi


## MinIO Admin Complete Guide
## https://docs.min.io/docs/minio-admin-complete-guide.html
# mc alias set "${MINIO_MC_ALIAS}" http://127.0.0.1:9000 "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}"

# mc admin info "${MINIO_MC_ALIAS}"
# mc admin console "${MINIO_MC_ALIAS}"
# mc admin service restart "${MINIO_MC_ALIAS}"
# mc admin service stop "${MINIO_MC_ALIAS}"
# mc admin config export "${MINIO_MC_ALIAS}"


## MinIO Multi-user Quickstart Guide
## https://docs.min.io/docs/minio-multi-user-quickstart-guide.html
# MINIO_USER_DBDATA=dbdata
# MINIO_USER_DBDATA_PASSWORD=$(cat /dev/urandom | head -c32 | base64 - | head -c16)
# MINIO_GROUP_BACKUP=backup
# mc admin user add "${MINIO_MC_ALIAS}" "${MINIO_USER_DBDATA}" "${MINIO_USER_DBDATA_PASSWORD}"
# mc admin group add "${MINIO_MC_ALIAS}" "${MINIO_GROUP_BACKUP}" "${MINIO_USER_DBDATA}"

# mc admin user list "${MINIO_MC_ALIAS}"
# mc admin user info "${MINIO_MC_ALIAS}" "${MINIO_USER_DBDATA}"
# mc admin group list "${MINIO_MC_ALIAS}"
# mc admin group info "${MINIO_MC_ALIAS}" "${MINIO_GROUP_BACKUP}"

# mc admin policy list "${MINIO_MC_ALIAS}"
# mc admin policy info "${MINIO_MC_ALIAS}" writeonly
# mc admin policy set "${MINIO_MC_ALIAS}" writeonly user="${MINIO_USER_DBDATA}"
# mc admin policy set "${MINIO_MC_ALIAS}" writeonly group="${MINIO_GROUP_BACKUP}"


## https://docs.min.io/docs/minio-client-complete-guide.html
## MinIO Client Complete Guide
# mc ls "${MINIO_MC_ALIAS}"
# mc tree "${MINIO_MC_ALIAS}"

## creates a new bucket
# mc mb "${MINIO_MC_ALIAS}/mybucket"

## Enable versioning on bucket
# mc version enable "${MINIO_MC_ALIAS}/mybucket"

# mc cp myobject.txt "${MINIO_MC_ALIAS}/mybucket/"
# mc rm "${MINIO_MC_ALIAS}/mybucket/myobject.txt"


## Upgrade a MinIO Deployment
# mc admin update "${MINIO_MC_ALIAS}"
# mc update


# Set up Nginx proxy with MinIO Server
# https://docs.min.io/docs/setup-nginx-proxy-with-minio.html


## Rclone with MinIO Server
## https://docs.min.io/docs/rclone-with-minio-server.html
## https://rclone.org/s3/
# rclone config
## create a new remote called minio (or anything else) of type S3 and enter the MinIO Server configuration
# rclone copy "/path/to/files" "minio:mybucket"
