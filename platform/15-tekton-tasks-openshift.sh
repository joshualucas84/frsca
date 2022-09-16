#!/usr/bin/env bash
set -euo pipefail

GIT_ROOT=$(git rev-parse --show-toplevel)

# Setup tekton tasks
oc apply -f "${GIT_ROOT}"/platform/vendor/tekton/catalog/main/task/buildpacks/0.5/buildpacks.yaml
oc apply -f "${GIT_ROOT}"/platform/vendor/tekton/catalog/main/task/buildpacks-phases/0.2/buildpacks-phases.yaml
oc apply -f "${GIT_ROOT}"/platform/vendor/tekton/catalog/main/task/git-clone/0.6/git-clone.yaml
oc apply -f "${GIT_ROOT}"/platform/vendor/tekton/catalog/main/task/golang-build/0.3/golang-build.yaml
oc apply -f "${GIT_ROOT}"/platform/vendor/tekton/catalog/main/task/golang-test/0.2/golang-test.yaml
oc apply -f "${GIT_ROOT}"/platform/vendor/tekton/catalog/main/task/jib-gradle/0.4/jib-gradle.yaml
oc apply -f "${GIT_ROOT}"/platform/vendor/tekton/catalog/main/task/kaniko/0.6/kaniko.yaml
oc apply -f "${GIT_ROOT}"/platform/vendor/tekton/catalog/main/task/maven/0.2/maven.yaml
oc apply -f "${GIT_ROOT}"/platform/vendor/tekton/catalog/main/task/trivy-scanner/0.1/trivy-scanner.yaml

# Setup tekton pipelines
oc apply -f "${GIT_ROOT}"/platform/vendor/tekton/catalog/main/pipeline/buildpacks/0.2/buildpacks.yaml

# Patch tasks for built in CA
oc patch Task buildpacks --patch-file "${GIT_ROOT}"/platform/components/tekton/tasks/patch_buildpacks.yml --type=json
oc patch Task jib-gradle --patch-file "${GIT_ROOT}"/platform/components/tekton/tasks/patch_gradle.yml --type=json
oc patch Task kaniko --patch-file "${GIT_ROOT}"/platform/components/tekton/tasks/patch_kaniko.yml --type=json
oc patch Task trivy-scanner --patch-file "${GIT_ROOT}"/platform/components/tekton/tasks/patch_trivy.yml --type=json
