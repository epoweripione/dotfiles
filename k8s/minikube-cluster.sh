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

# minikube implements a local Kubernetes cluster on macOS, Linux, and Windows
# https://minikube.sigs.k8s.io/
colorEcho "${BLUE}Installing ${FUCHSIA}minikube${BLUE}..."
INSTALLER_FILE_NAME="minikube-${OS_INFO_TYPE}-${OS_INFO_ARCH}"
INSTALLER_DOWNLOAD_URL="https://storage.googleapis.com/minikube/releases/latest/${INSTALLER_FILE_NAME}"

curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/${INSTALLER_FILE_NAME}" "${INSTALLER_DOWNLOAD_URL}" && \
    sudo install "${WORKDIR}/${INSTALLER_FILE_NAME}" "/usr/local/bin/minikube"
[[ ! -x "$(command -v minikube)" ]] && colorEcho "${FUCHSIA}minikube${BLUE} is not installed!" && exit 1

[[ ! -x "$(command -v kubectl)" && "$(command -v mise)" ]] && mise global kubectl@latest
[[ ! -x "$(command -v kubectl)" && "$(command -v asdf)" ]] && asdf_App_Install kubectl
[[ ! -x "$(command -v kubectl)" ]] && colorEcho "${FUCHSIA}kubectl${BLUE} is not installed!" && exit 1

## Start your cluster
# From a terminal with administrator access (but not logged in as root), run:
minikube start

# Interact with your cluster
kubectl get po -A

# Dashboard
minikube dashboard

## Deploy applications
# Create a sample deployment and expose it on port 8080:
kubectl create deployment hello-minikube --image=k8s.gcr.io/echoserver:1.4
kubectl expose deployment hello-minikube --type=NodePort --port=8080

kubectl get services hello-minikube

# The easiest way to access this service is to let minikube launch a web browser for you:
minikube service hello-minikube

# Alternatively, use kubectl to forward the port:
kubectl port-forward service/hello-minikube 7080:8080
# Tada! Your application is now available at http://localhost:7080/


## LoadBalancer deployments
## To access a LoadBalancer deployment, use the “minikube tunnel” command. Here is an example deployment:
# kubectl create deployment balanced --image=k8s.gcr.io/echoserver:1.4  
# kubectl expose deployment balanced --type=LoadBalancer --port=8080

## In another window, start the tunnel to create a routable IP for the ‘balanced’ deployment:
# minikube tunnel

## To find the routable IP, run this command and examine the EXTERNAL-IP column:
# kubectl get services balanced
## Your deployment is now available at <EXTERNAL-IP>:8080


## Manage your cluster
## Pause Kubernetes without impacting deployed applications:
# minikube pause

## Unpause a paused instance:
# minikube unpause

## Halt the cluster:
# minikube stop

## Increase the default memory limit (requires a restart):
# minikube config set memory 16384

## Browse the catalog of easily installed Kubernetes services:
# minikube addons list

## Create a second cluster running an older Kubernetes release:
# minikube start -p aged --kubernetes-version=v1.16.1

## Delete all of the minikube clusters:
# minikube delete --all
