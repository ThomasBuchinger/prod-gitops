NODE_IP=10.0.0.33
DHCP_IP=10.0.0.167

OUTPUT_DIR=out
YQ_ARGS=--prettyPrint --no-colors --inplace
TALOSCTL="./bin/talosctl"
TALOS_NODECONF=$(OUTPUT_DIR)/controlplane.yaml
TALOS_CONFIG=$(OUTPUT_DIR)/talosconfig

.PHONY: build kustomize talos-config
build: talos-config kubeseal

bin/talosctl:
	@echo "Installing talosctl to $(TALOSCTL)"
	mkdir -p bin
	curl -Lo $(TALOSCTL) --silent https://github.com/siderolabs/talos/releases/download/v1.3.0/talosctl-linux-amd64
	chmod +x $(TALOSCTL)

$(OUTPUT_DIR)/talos-secrets.yaml:
	mkdir -p out
	$(TALOSCTL) gen secrets --output-file "$@"
kustomize:
	mkdir -p out
	kubectl kustomize ./infra/argocd > $(OUTPUT_DIR)/infra-argocd.yaml
	kubectl kustomize --enable-helm ./infra/traefik > $(OUTPUT_DIR)/infra-traefik.yaml

talos-config: bin/talosctl $(OUTPUT_DIR)/talos-secrets.yaml kustomize
	mkdir -p $(OUTPUT_DIR)/talos
	$(TALOSCTL) gen config prod https://$(NODE_IP):6443 \
		--config-patch=@talos/talos-merge.yaml \
		--output-dir "$(OUTPUT_DIR)" \
		--with-secrets "$(OUTPUT_DIR)/talos-secrets.yaml"
	yq eval $(YQ_ARGS) '.machine.network.interfaces[0].addresses[0] = "$(NODE_IP)/24"'                       $(TALOS_NODECONF)
	yq eval $(YQ_ARGS) '.cluster.inlineManifests[0].contents = load_str("secrets/vault-secretid.yaml")' $(TALOS_NODECONF)
	yq eval $(YQ_ARGS) '.cluster.inlineManifests[1].contents = load_str("$(OUTPUT_DIR)/infra-argocd.yaml")'  $(TALOS_NODECONF)
	yq eval $(YQ_ARGS) '.cluster.inlineManifests[2].contents = load_str("$(OUTPUT_DIR)/infra-traefik.yaml")'  $(TALOS_NODECONF)
	yq eval $(YQ_ARGS) '.contexts.prod.endpoints[0] = "$(NODE_IP)"'                                          $(TALOS_CONFIG)

talos-init: talos-config
	$(TALOSCTL) apply-config --insecure --nodes $(DHCP_IP) --file $(TALOS_NODECONF)
talos-bootstrap:
	$(TALOSCTL) bootstrap --talosconfig $(TALOS_CONFIG) --nodes $(NODE_IP)
untaint: kubeconfig
	KUBECONFIG=./kubeconfig kubectl taint nodes --all node-role.kubernetes.io/control-plane-


talos-reset:
	$(TALOSCTL) reset --talosconfig $(TALOS_CONFIG) --nodes $(NODE_IP)
talos-apply: talos-config
	$(TALOSCTL) apply-config --talosconfig $(TALOS_CONFIG) --nodes $(NODE_IP) --file $(TALOS_NODECONF)

kubeconfig:
	$(TALOSCTL) kubeconfig ./kubeconfig --talosconfig $(TALOS_CONFIG) --nodes $(NODE_IP)


kubeseal:
	kubeseal --cert secrets/sealed.crt -o yaml -f secrets/secret-id.yaml > gitops/external-secrets/base/secret-id-sealed.yaml