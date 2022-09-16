#!/usr/bin/env bash
set -euo pipefail

GIT_ROOT=$(git rev-parse --show-toplevel)

# Define variables.
C_GREEN='\033[32m'
C_RESET_ALL='\033[0m'

#oc create serviceaccount anyuid
oc adm policy add-scc-to-user anyuid system:serviceaccount:registry:registry-sa || true
oc adm policy add-scc-to-user nonroot system:serviceaccount:registry:registry-sa || true
oc adm policy add-scc-to-user privileged system:serviceaccount:registry:registry-sa || true

# Setup Registry.
echo -e "${C_GREEN}Setting up Registry...${C_RESET_ALL}"
kubectl create namespace registry --dry-run=client --output=yaml | kubectl apply -f -
oc apply --filename "$GIT_ROOT"/platform/components/registry/openshift/registry-scc.yaml 
oc apply --filename "$GIT_ROOT"/platform/components/registry/openshift/registry.yaml
oc rollout status -n registry statefulset/registry
oc rollout status -n registry daemonset/registry-proxy
