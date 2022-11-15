#!/usr/bin/env bash
set -euo pipefail

GIT_ROOT=$(git rev-parse --show-toplevel)

# Define variables.
C_GREEN='\033[32m'
C_RESET_ALL='\033[0m'

#oc create serviceaccount anyuid for registry
oc create serviceaccount registry-sa -n registry || true
oc adm policy add-scc-to-user anyuid system:serviceaccount:registry:registry-sa || true
oc adm policy add-scc-to-user nonroot system:serviceaccount:registry:registry-sa || true
oc adm policy add-scc-to-user privileged system:serviceaccount:registry:registry-sa || true

#oc create serviceaccount anyuid for spire
oc create serviceaccount spire-sa -n spire || true
oc adm policy add-scc-to-user anyuid system:serviceaccount:spire:spire-sa || true
oc adm policy add-scc-to-user nonroot system:serviceaccount:spire:spire-sa || true
oc adm policy add-scc-to-user privileged system:serviceaccount:spire:spire-sa || true

#oc create serviceaccount anyuid for vault
oc create serviceaccount vault-sa -n vault || true
oc adm policy add-scc-to-user anyuid system:serviceaccount:vault:vault-sa || true
oc adm policy add-scc-to-user nonroot system:serviceaccount:vault:vault-sa || true
oc adm policy add-scc-to-user privileged system:serviceaccount:vault:vault-sa || true

#oc create serviceaccount anyuid for gitea
oc create serviceaccount gitea-sa -n gitea || true
oc adm policy add-scc-to-user anyuid system:serviceaccount:gitea:gitea-sa || true
oc adm policy add-scc-to-user nonroot system:serviceaccount:gitea:gitea-sa || true
oc adm policy add-scc-to-user privileged system:serviceaccount:gitea:gitea-sa || true

#oc create serviceaccount for tekton-pipelines-controller
oc create serviceaccount  tekton-pipelines-controller -n tekton-pipelines || true
oc adm policy add-scc-to-user anyuid system:serviceaccount:tekton-pipelines:tekton-pipelines-controller|| true
oc adm policy add-scc-to-user anyuid system:serviceaccount:tekton-pipelines:tekton-pipelines-webhook || true

#oc create serviceaccount for tekton-chains-controller
oc create serviceaccount  tekton-chains-controller -n tekton-chains || true
oc adm policy add-scc-to-user nonroot system:serviceaccount:tekton-chains:tekton-chains-controller || true
oc adm policy add-scc-to-user anyuid system:serviceaccount:tekton-chains:tekton-chains-controller || true
oc adm policy add-scc-to-user privileged system:serviceaccount:tekton-chains:tekton-chains-controller || true
