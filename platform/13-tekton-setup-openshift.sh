#!/usr/bin/env bash
set -euo pipefail

GIT_ROOT=$(git rev-parse --show-toplevel)

# Define variables.
C_GREEN='\033[32m'
C_RESET_ALL='\033[0m'


## openshift ##TODO
oc adm policy add-scc-to-user anyuid system:serviceaccount:tekton-pipelines:tekton-pipelines-controller|| true
oc adm policy add-scc-to-user anyuid system:serviceaccount:tekton-pipelines:tekton-pipelines-webhook || true




# Setup Tekton.
echo -e "${C_GREEN}Setting up Tekton CD...${C_RESET_ALL}"
oc apply --filename "$GIT_ROOT"/platform/vendor/tekton/pipeline/openshift/release.yaml




ca_cert="${GIT_ROOT}/platform/certs/ca/ca.pem"
# TODO: at most only one of these is actually needed
oc -n tekton-pipelines create configmap config-registry-cert \
  --from-file=cert="${ca_cert}" \
  --dry-run=client -o=yaml | oc apply -f -
oc patch \
      deployment tekton-pipelines-controller \
      -n tekton-pipelines \
      --patch-file "$GIT_ROOT"/platform/components/tekton/pipelines/patch_ca_certs.json
oc -n tekton-pipelines delete pod -l app=tekton-pipelines-controller

oc rollout status -n tekton-pipelines deployment/tekton-pipelines-controller

# Setup the Dashboard.
#   Use `oc proxy --port=8080` and then
#   http://localhost:8080/api/v1/namespaces/tekton-pipelines/services/tekton-dashboard:http/proxy/
#   to access it.
oc apply --filename "$GIT_ROOT"/platform/vendor/tekton/dashboard/tekton-dashboard-release.yaml
oc rollout status -n tekton-pipelines deployment/tekton-dashboard

# Wait for tekton pipelines configuration webhook to come up
oc rollout status -n tekton-pipelines deployment/tekton-pipelines-webhook
