#!/usr/bin/env bash
set -euo pipefail

GIT_ROOT=$(git rev-parse --show-toplevel)

oc create serviceaccount  tekton-chains-controller -n tekton-chains || true

# Setup tekton Chains
oc adm policy add-scc-to-user nonroot system:serviceaccount:tekton-chains:tekton-chains-controller || true
oc adm policy add-scc-to-user anyuid system:serviceaccount:tekton-chains:tekton-chains-controller || true
oc adm policy add-scc-to-user privileged system:serviceaccount:tekton-chains:tekton-chains-controller || true
#oc set sa deploy tekton-chains-controller tekton-chains-controller -n tekton-chains



# Install Chains.
oc apply --filename "$GIT_ROOT"/platform/vendor/tekton/chains/openshift/release.yaml || true
oc rollout status -n tekton-chains deployment/tekton-chains-controller

# Patch chains to generate in-toto provenance and store output in OCI
oc patch \
      configmap chains-config \
      -n tekton-chains \
      --patch-file "$GIT_ROOT"/platform/components/tekton/chains/patch_config_oci.yaml

oc patch \
      configmap chains-config \
      -n tekton-chains \
      --patch-file "$GIT_ROOT"/platform/components/tekton/chains/patch_config_kms.yaml

oc patch \
      deployment tekton-chains-controller \
      -n tekton-chains \
      --patch-file "$GIT_ROOT"/platform/components/tekton/chains/patch_spire.json

oc patch \
      deployment tekton-chains-controller \
      -n tekton-chains \
      --patch-file "$GIT_ROOT"/platform/components/tekton/chains/patch_ca_certs.json

oc rollout status -n tekton-chains deployment/tekton-chains-controller
