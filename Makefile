# Project configuration.
PROJECT_NAME = frsca

# Makefile parameters.
TAG ?= 10m	# This is the TTL for the ttl.sh registry

# General.
SHELL = /usr/bin/env bash
TOPDIR = $(shell git rev-parse --show-toplevel)

# Docker.
DOCKERFILE = Dockerfile
DOCKER_ORG = ttl.sh
DOCKER_REPO = $(DOCKER_ORG)/$(PROJECT_NAME)
DOCKER_IMG = $(DOCKER_REPO):$(TAG)
SBOM = $(DOCKER_REPO)/sbom:$(TAG)

help: # Display help
	@awk -F ':|##' \
		'/^[^\t].+?:.*?##/ {\
			printf "\033[36m%-30s\033[0m %s\n", $$1, $$NF \
		}' $(MAKEFILE_LIST) | sort

.PHONY: quickstart
quickstart: setup-minikube setup-frsca setup-kyverno example-buildpacks ## Spin up the FRSCA project into minikube

.PHONY: setup-openshift
setup-openshift: setup-certs-openshift setup-registry-openshift setup-tekton-chains-openshift  example-buildpacks
#setup-spire setup-vault	 

.PHONY: teardown
teardown:
	minikube delete

.PHONY: setup-minikube
setup-minikube: ## Setup a Kubernetes cluster using Minikube
	bash platform/00-kubernetes-minikube-setup.sh

.PHONY: setup-frsca
setup-frsca: setup-certs setup-registry setup-tekton-chains setup-spire setup-vault

.PHONY: setup-certs
setup-certs: ## Setup certificates used by vault and spire
	bash platform/02-setup-certs.sh

.PHONY: setup-certs-openshift
setup-certs-openshift: ## Setup certificates used by vault and spire
	bash platform/03-setup-certs-openshift.sh

.PHONY: setup-registry
setup-registry: ## Setup a registry
	bash platform/04-registry-setup.sh

.PHONY: registry-proxy
registry-proxy: ## Forward the registry to the host
	bash platform/05-registry-proxy.sh

.PHONY: setup-registry-openshift
setup-registry-openshift: ## Setup a registry openshift
	bash platform/06-registry-setup-openshift.sh

.PHONY: setup-tekton-chains
setup-tekton-chains: ## Setup a Tekton CD with Chains.
	bash platform/10-tekton-setup.sh
	bash platform/11-tekton-chains.sh
	bash platform/12-tekton-tasks.sh


.PHONY: setup-tekton-chains-openshift
setup-tekton-chains-openshift: ## Setup a Tekton CD with Chains.
	bash platform/13-tekton-setup-openshift.sh
	bash platform/14-tekton-chains-openshift.sh
	bash platform/15-tekton-tasks-openshift.sh

.PHONY: tekton-generate-keys
tekton-generate-keys: ## Generate key pair for Tekton.
	bash scripts/gen-keys.sh

.PHONY: tekton-verify-taskrun
tekton-verify-taskrun: ## Verify taskrun payload against signature
	bash scripts/provenance.sh

.PHONY: setup-spire
setup-spire: ## Setup spire
	bash platform/20-spire-setup.sh

.PHONY: setup-vault
setup-vault: ## Setup vault
	bash platform/25-vault-install.sh
	bash platform/26-vault-setup.sh

.PHONY: setup-spire-openshift
setup-spire-openshift: ## Setup spire
	bash platform/21-spire-setup-openshift.sh

.PHONY: setup-vault-openshift
setup-vault-openshift: ## Setup vault
	bash platform/27-vault-install-openshift.sh
	bash platform/28-vault-setup-openshift.sh

.PHONY: setup-kyverno
setup-kyverno: ## Setup Kyverno.
	bash platform/30-kyverno-setup.sh

.PHONY: setup-opa-gatekeeper
setup-opa-gatekeeper: ##  Setup opa gatekeeper
	bash platform/31-opa-gatekeeper-setup.sh

.PHONY: setup-efk-stack
setup-efk-stack: ## Setup up EFK stack
	bash platform/40-efk-stack-setup/40-efk-stack-setup.sh

.PHONY: example-buildpacks
example-buildpacks: ## Run the buildpacks example
	bash examples/buildpacks/buildpacks.sh

.PHONY: example-cosign
example-cosign: ## Run the cosign example
	bash examples/cosign/cosign.sh

.PHONY: example-maven
example-maven: ## Run the maven example
	bash examples/maven/maven.sh

.PHONY: example-golang-pipeline
example-golang-pipeline: ## Run the go-pipeline example
	bash examples/go-pipeline/go-pipeline.sh

.PHONY: example-gradle-pipeline
example-gradle-pipeline: ## Run the gradle-pipeline example
	bash examples/gradle-pipeline/gradle-pipeline.sh

.PHONY: example-sample-pipeline
example-sample-pipeline: ## Run the sample-pipeline example
	bash examples/sample-pipeline/sample-pipeline.sh

.PHONY: example-ibm-tutorial
example-ibm-tutorial: ## Run the IBM pipeline example
	bash examples/ibm-tutorial/ibm-tutorial.sh

.PHONY: docs-setup
docs-setup: ## Install the tool to build the documentation
	bash docs/bootstrap.sh

.PHONY: docs-serve
docs-serve: ## Serve the site locally with hot-reloading
	bash docs/serve.sh

.PHONY: docs-build
docs-build: ## Build the documentation site
	cd docs && zola build

.PHONY: lint
lint: lint-md lint-yaml lint-shell ## Run all linters

.PHONY: lint-md
lint-md: ## Lint markdown files
	npx --yes markdownlint-cli2  "**/*.md" "#docs/themes" "#platform/vendor"

.PHONY: lint-shell
lint-shell: ## Lint shell files
	shfmt -f ./ | grep -ve "platform/vendor/.*/" | xargs shellcheck

.PHONY: lint-spellcheck
lint-spellcheck:
	npx --yes cspell --no-progress --show-suggestions --show-context "**/*"

.PHONY: lint-yaml
lint-yaml: ## Lint yaml files
	yamllint .

.PHONY: fmt-md ## Format markdown files
fmt-md:
	npx --yes prettier --write --prose-wrap always **/*.md

.PHONY: vendor ## vendor upstream projects
vendor:
	bash platform/vendor/vendor.sh
	bash platform/vendor/vendor-helm-all.sh -f
	