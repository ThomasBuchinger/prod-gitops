
MANIFEST_DIR=/var/lib/rancher/k3s/server/manifests

manual-manifest-deploy: gen-secrets
	@[ -d $(MANIFEST_DIR) ] || echo "$(MANIFEST_DIR) does not exist"
	@echo "Generating manual Manifests to be deployed via k3s"
	cp -rf argocd/install/* $(MANIFEST_DIR)
	cp -f secrets/secrets.yaml $(MANIFEST_DIR)

gen-secrets:
	kubectl kustomize secrets/ > secrets/secrets.yaml