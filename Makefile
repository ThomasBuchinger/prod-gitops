
MANIFEST_DIR=/var/lib/rancher/k3s/server/manifests

manual-manifest-deploy:
	@[ -d $(MANIFEST_DIR) ] || echo "$(MANIFEST_DIR) does not exist"
	@[ -f secrets/secrets.yaml ] || echo "secrets.yaml does not exist. generate it with 'kubectl kustomize secrets/ > secrets/secrets.yaml'"
	@echo "Generating manual Manifests to be deployed via k3s"
	cp -rf argocd/install/* $(MANIFEST_DIR)
	cp -f secrets/secrets.yaml $(MANIFEST_DIR)
