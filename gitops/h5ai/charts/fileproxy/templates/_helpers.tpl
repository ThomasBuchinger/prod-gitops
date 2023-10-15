{{/*
Expand the name of the chart.
*/}}
{{- define "fileproxy.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "fileproxy.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "fileproxy.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}




{{/*
Common labels
*/}}
{{- define "fileproxy.labels" -}}
helm.sh/chart: {{ include "fileproxy.chart" . }}
{{ include "fileproxy.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "fileproxy.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fileproxy.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: h5ai
fileproxy/id: {{ .proxy.id }}
fileproxy/ns: {{ .proxy.namespace }}
{{- end }}

{{/*
==================== My Stuff ==========================================
*/}}


{{/*
Main namespace
*/}}
{{- define "fileproxy.mainNamespace" -}}
{{ .Values.namespaceOverride | default "h5ai" }}
{{- end }}



{{/*
VOLUMES: Configure VolumeMounts for Proxies and/or main app
*/}}
{{- define "fileproxy.proxyVolumeMounts" -}}
  {{ if .proxy.is_root }}
    {{- range .Values.proxies }}
      {{- range .mounts }}
- name: dummy
  mountPath: /h5ai/{{ .path | trimPrefix "/" }}
  readOnly: true
      {{- end }}
    {{- end }}
  {{ else }}
    {{- range .proxy.mounts }}
- name: {{ .path | trimPrefix "/" | default "root" | quote }}
  mountPath: /h5ai/{{ .path | trimPrefix "/" }}
  readOnly: true
    {{- end }}
  {{- end }}
{{- end }}

{{/*
VOLUMES: Configure Volumes for Proxies and/or main app
*/}}
{{- define "fileproxy.proxyVolumes" -}}
  {{ if .proxy.is_root }}
- name: dummy
  emptyDir: {}
  {{ else }}
    {{- range .proxy.mounts }}
- name: {{ .path | trimPrefix "/" | default "root" | quote }}
  {{- .volume | toYaml | nindent 2}}
    {{- end }}
  {{- end }}
{{- end }}


{{/*
PV ACCESS: Configure ENV variable the init-script should change to
*/}}
{{- define "fileproxy.uid_change" -}}
  {{ if (dig "fs" "uid" false .proxy) }}
- name: PUID
  value: {{ .proxy.fs.uid | quote }}
- name: PGID
  value: {{ .proxy.fs.uid | quote }}
  {{- end }}
{{- end }}



