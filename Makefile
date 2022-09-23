
MANIFEST_DIR=/var/lib/rancher/k3s/server/manifests

manual-manifest-deploy:
	[ -f $(MANIFEST_DIR) ]
	echo "Generating manual Manifests to be deployed via k3s"
	cp -rf argocd/install $(MANIFEST_DIR) 

