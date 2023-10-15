{{/*
Create one ExternalSecret in each Namespace
*/}}
{{- define "fileproxy.ns_resources" -}}

{{/* Find all the namespaces */}}
{{- $namespaces := list -}}
{{- range $item := . -}}
{{- $namespaces = append $namespaces $item.namespace -}}
{{- end -}}

{{- range  $namespaces | uniq }}



---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: fileproxy-cert-ns-{{ . }}
  namespace: {{ .proxy.namespace }}
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-approle-cluster
    kind: ClusterSecretStore
  target:
    name: cert-files-buc-sh
    creationPolicy: Owner
  dataFrom:
  - extract:
      conversionStrategy: Default
      decodingStrategy: None
      key: cert/cert-files-buc-sh




{{- end }}

{{- end -}}
