# Cluster: prod

This is the gitops repository for the production part of the homelab.

"prod" is a single-node cluster on a fairly low powered Machine, but is uses:

* Talos Linux as OS
* External Secrets Operator to fetch remote secrets from a different Kubernetes Cluster
* NFS for Persistent Volumes
* Local-Path-Provisioner for unimportent PersistentVolumes
* "production-ready" configuration, like Namespaces and NetworkPolicies

## Instrastructure Requirements

Some instraftructure is assumed to be present in the environment.

* Management Kubernetes
* NFS Server Volumes
* S3 Bucket

