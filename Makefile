NODE_IP=10.0.0.21
DHCP_IP=10.0.0.179

# TALOS_VERSION=v1.7.6
OUTPUT_DIR=out
YQ_ARGS=--prettyPrint --no-colors --inplace
# TALOSCTL="./bin/talosctl"
TALOS_NODECONF=$(OUTPUT_DIR)/controlplane.yaml
TALOS_CONFIG=$(OUTPUT_DIR)/talosconfig

.PHONY: build kustomize talos-config
build: talos-config kubeseal

$(OUTPUT_DIR)/talos-secrets.yaml:
	mkdir -p out
	talosctl gen secrets --output-file "$@"
kustomize:
	mkdir -p out
	kubectl kustomize ./infra/argocd > $(OUTPUT_DIR)/infra-argocd.yaml
	kubectl kustomize --enable-helm ./infra/traefik > $(OUTPUT_DIR)/infra-traefik.yaml
	kubectl kustomize --enable-helm ./infra/cillium > $(OUTPUT_DIR)/infra-cillium.yaml

talos-config: bin/talosctl $(OUTPUT_DIR)/talos-secrets.yaml kustomize
	mkdir -p $(OUTPUT_DIR)/talos
	talosctl gen config prod https://$(NODE_IP):6443 \
		--force \
		--config-patch=@talos/talos-merge.yaml \
		--output-dir "$(OUTPUT_DIR)" \
		--with-secrets "$(OUTPUT_DIR)/talos-secrets.yaml"
	yq eval $(YQ_ARGS) '.machine.network.interfaces[0].addresses[0] = "$(NODE_IP)/24"'                       $(TALOS_NODECONF)
	yq eval $(YQ_ARGS) '.cluster.inlineManifests[0].contents = load_str("secrets/eso-k8s-token.yaml")' $(TALOS_NODECONF)
	yq eval $(YQ_ARGS) '.cluster.inlineManifests[1].contents = load_str("$(OUTPUT_DIR)/infra-argocd.yaml")'  $(TALOS_NODECONF)
	yq eval $(YQ_ARGS) '.cluster.inlineManifests[2].contents = load_str("$(OUTPUT_DIR)//infra-cillium.yaml")'  $(TALOS_NODECONF)
	yq eval $(YQ_ARGS) '.cluster.inlineManifests[3].contents = load_str("$(OUTPUT_DIR)/infra-traefik.yaml")'  $(TALOS_NODECONF)
	yq eval $(YQ_ARGS) '.cluster.inlineManifests[4].contents = load_str("infra/auto-untaint.yaml")'  $(TALOS_NODECONF)
	yq eval $(YQ_ARGS) '.cluster.inlineManifests[5].contents = load_str("secrets/cluster-secrets.yaml")'  $(TALOS_NODECONF)
	yq eval $(YQ_ARGS) '.contexts.prod.endpoints[0] = "$(NODE_IP)"'                                          $(TALOS_CONFIG)

talos-init: talos-config
	talosctl apply-config --insecure --nodes $(DHCP_IP) --file $(TALOS_NODECONF)
talos-bootstrap:
	echo Bootstrap etcd...
	talosctl bootstrap --talosconfig $(TALOS_CONFIG) --nodes $(NODE_IP)

kubeconfig:
	talosctl kubeconfig ./kubeconfig --talosconfig $(TALOS_CONFIG) --nodes $(NODE_IP)

# === Debugging targets ===
talos-reset:
	talosctl reset --talosconfig $(TALOS_CONFIG) --nodes $(NODE_IP)
talos-apply: talos-config
	talosctl apply-config --talosconfig $(TALOS_CONFIG) --nodes $(NODE_IP) --file $(TALOS_NODECONF)

# Temporary Workaround. Kubernetes 1.27 is not yet supported by the k8s operator controller-runtime
# https://github.com/alex1989hu/kubelet-serving-cert-approver/issues/139
approve-csr: kubeconfig
	kubectl --kubeconfig ./kubeconfig certificate approve $(kubectl get csr --kubeconfig ./kubeconfig --sort-by=.metadata.creationTimestamp | grep Pending | awk '{print $1}')

# There is a Job that automatically untaints the Nodes
untaint: kubeconfig
	kubectl --kubeconfig ./kubeconfig taint nodes --all node-role.kubernetes.io/control-plane-
