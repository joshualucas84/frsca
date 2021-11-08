#!/bin/bash
set -euo pipefail

# TODO: Pin Brew versions for Mac
# TODO: Figure out a better mechanism for pinning versions in general
#       There are multiple ways to validate signatures, checksums, etc.

# PINNED VERSIONS GO HERE
MINIKUBE_VERSION=v1.24.0
MINIKUBE_FILE_NAME=minikube-linux-amd64
MINIKUBE_URL=https://github.com/kubernetes/minikube/releases/download/$MINIKUBE_VERSION/$MINIKUBE_FILE_NAME
MINIKUBE_SHA256=3bc218476cf205acf11b078d45210a4882e136d24a3cbb7d8d645408e423b8fe

HELM_VERSION=v3.7.1
HELM_FILE_NAME=helm-v3.7.1-linux-amd64.tar.gz
HELM_URL=https://get.helm.sh/$HELM_FILE_NAME
HELM_SHA256=6cd6cad4b97e10c33c978ff3ac97bb42b68f79766f1d2284cfd62ec04cd177f4

TKN_VERSION=0.21.0
TKN_FILE_NAME=tkn_0.21.0_Linux_x86_64.tar.gz
TKN_URL=https://github.com/tektoncd/cli/releases/download/v$TKN_VERSION/$TKN_FILE_NAME
TKN_SHA256=2158a202e4b04ff73e6427b565355c7bfc8cbe16dc7058a0414fb16e7b97008c

INSTALL_DIR=/usr/local/bin

# Define variables.
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_RED='\033[31m'
C_RESET_ALL='\033[0m'

# Detect the platform.
PLATFORM=$(uname)

# Install packages if needed.
echo -e "${C_GREEN}Installing packages if needed...${C_RESET_ALL}"
case "${PLATFORM}" in

  Darwin)
    minikube version || brew install minikube
    helm version || brew install helm
    tkn version || brew install tektoncd-cli
    ;;

  Linux)
    [[ $(minikube version | awk '{print $3}' | xargs) == $MINIKUBE_VERSION ]] || (
      TMP=$(mktemp -d)
      pushd $TMP
      curl -LO $MINIKUBE_URL
      ACTUAL_SHA256=$(sha256sum $MINIKUBE_FILE_NAME | awk '{print $1}')
      [[ $ACTUAL_SHA256 == $MINIKUBE_SHA256 ]] || (
        echo "Expected SHA256 for $MINIKUBE_FILE_NAME: $MINIKUBE_SHA256"
        echo "Actual SHA256 for $MINIKUBE_FILE_NAME: $ACTUAL_SHA256"
        exit 1
      )
      sudo install $MINIKUBE_FILE_NAME $INSTALL_DIR/minikube
      rm $MINIKUBE_FILE_NAME
      popd
      rmdir $TMP
    )
    [[ $(helm version | awk '{print $1 }' | sed -r 's/.*Version:\"(.*)\",/\1/') == $HELM_VERSION ]] || (
      TMP=$(mktemp -d)
      pushd $TMP
      curl -LO $HELM_URL
      ACTUAL_SHA256=$(sha256sum $HELM_FILE_NAME | awk '{print $1}')
      [[ $ACTUAL_SHA256 == $HELM_SHA256 ]] || (
        echo "Expected SHA256 for $HELM_FILE_NAME: $HELM_SHA256"
        echo "Actual SHA256 for $HELM_FILE_NAME: $ACTUAL_SHA256"
        exit 1
      )
      tar xvf $HELM_FILE_NAME
      sudo install linux-amd64/helm $INSTALL_DIR/helm
      rm -rf linux-amd64
      popd
      rmdir $TMP
    )
    tkn version || (
      TMP=$(mktemp -d)
      pushd $TMP
      curl -LO $TKN_URL
      ACTUAL_SHA256=$(sha256sum $TKN_FILE_NAME | awk '{print $1}')
      [[ $ACTUAL_SHA256 == $TKN_SHA256 ]] || (
        echo "Expected SHA256 for $TKN_FILE_NAME: $TKN_SHA256"
        echo "Actual SHA256 for $TKN_FILE_NAME: $ACTUAL_SHA256"
        exit 1
      )
      sudo tar xvzf $TKN_FILE_NAME -C /usr/local/bin tkn
      rm TKN_FILE_NAME
      popd
      rmdir $TMP
    )
    ;;

  *)
    echo -e "${C_RED}The ${PLATFORM} platform is unimplemented or unsupported.${C_RESET_ALL}"
    exit 1
    ;;

esac

# Start the service.
# shellcheck disable=SC1083
MINIKUBE_STATUS=$(minikube status --format  {{.Host}} || true)
if [ "${MINIKUBE_STATUS}" == "Running" ]; then
  echo -e "${C_YELLOW}Minikube is already running.${C_RESET_ALL}"
else
  echo -e "${C_GREEN}Starting Minikube...${C_RESET_ALL}"
  minikube start \
    --driver=docker \
    --extra-config=apiserver.service-account-signing-key-file=/var/lib/minikube/certs/sa.key \
    --extra-config=apiserver.service-account-key-file=/var/lib/minikube/certs/sa.pub \
    --extra-config=apiserver.service-account-issuer=api \
    --extra-config=apiserver.service-account-api-audiences=api,spire-server \
    --extra-config=apiserver.authorization-mode=Node,RBAC
fi

# Set up Minikube context.
echo -e "${C_GREEN}Configuring minikube context...${C_RESET_ALL}"
kubectl config use-context minikube

# Display a message to tell to update the environment variables.
minikube docker-env

# Note(rgreinhofer): this is currently not supported for M1 chips.
#   ❌  Exiting due to MK_USAGE: Due to networking limitations of driver docker
#       on darwin, ingress addon is not supported.
#   Alternatively to use this addon you can use a vm-based driver:
#
# 	  'minikube start --vm=true'
#
#   To track the update on this work in progress feature please check:
#   https://github.com/kubernetes/minikube/issues/7332
# Manage default Ingress Controller.
# minikube addons enable ingress

# Setup Minikube's registry.
minikube addons enable registry

# Add/Update Helm chart repositories.
echo -e "${C_GREEN}Configuring helm...${C_RESET_ALL}"
helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update