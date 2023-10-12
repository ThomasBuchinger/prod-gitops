# Cluster: prod

This is the gitops repository for the production part of the homelab.

"prod" is a single-node cluster on a fairly low powered Machine, but is uses:

* Talos Linux as OS
* Vault for Secrets Management
* iSCSI for Persistent Volume
* Local-Path-Provisioner for unimportent PersistentVolumes
* "production-ready" configuration, like Namespaces and NetworkPolicies

## Instrastructure Requirements

Some instraftructure is assumed to be present in the environment.

* Hashicorp Vault
* iSCSI Volumes
* S3 Bucket

