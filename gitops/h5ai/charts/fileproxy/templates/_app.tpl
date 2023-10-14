{{/*
H5ai Namespaced Deployment
*/}}
{{- define "fileproxy.h5ai" -}}

{{ if .proxy.is_big }}
{{- include "fileproxy.bigShareConfig" . }}
{{ end }}

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "fileproxy.fullname" . }}-{{ .proxy.id }}
  namespace: {{ .proxy.namespace }}
  labels:
    {{- include "fileproxy.labels" .  | nindent 4 }}
spec:
  replicas: 1
  selector:
    matchLabels:
      {{- include "fileproxy.selectorLabels" .  | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "fileproxy.selectorLabels" .  | nindent 8 }}
    spec:
      containers:
      - name: h5ai
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default "latest" }}"
        imagePullPolicy: IfNotPresent
        {{- if .proxy.is_big }}
        command:
        - bash
        - -c
        - 'cp -f /custom-config/options.json /usr/share/h5ai/_h5ai/private/conf && exec /init.sh'
        {{- end }}
        {{- include "fileproxy.uid_change" . | nindent 8 }}
        ports:
        - name: http
          containerPort: 80
        livenessProbe:
          failureThreshold: 3
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
          httpGet:
            path: /
            port: http
        readinessProbe:
          failureThreshold: 3
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
          httpGet:
            path: /
            port: http
        resources:
          requests:
            cpu: 5m
            memory: 64Mi
          limits: {}
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            add:
            - CHOWN
            - SETUID
            - SETGID
            - NET_BIND_SERVICE
            drop:
            - ALL
          seccompProfile:
            type: RuntimeDefault
        volumeMounts:
        {{- include "fileproxy.proxyVolumeMounts" . | nindent 8 }}
        {{- if .proxy.is_big }}
        - name: h5ai-cusom-config
          mountPath: /custom-config
        {{- end }}
      securityContext: {}
      volumes:
      {{- include "fileproxy.proxyVolumes" . | nindent 6 }}
      {{- if .proxy.is_big }}
      - name: h5ai-cusom-config
        configMap:
          name: {{ include "fileproxy.fullname" . }}-{{ .proxy.id }}-config
      {{- end }}

---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "fileproxy.fullname" . }}-{{ .proxy.id }}
  namespace: {{ .proxy.namespace }}
  labels:
    {{- include "fileproxy.labels" .  | nindent 4 }}
spec:
  selector:
    {{- include "fileproxy.selectorLabels" .  | nindent 4 }}
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: http


---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "fileproxy.fullname" . }}-{{ .proxy.id }}
  namespace: {{ .proxy.namespace }}
  labels:
    {{- include "fileproxy.labels" .  | nindent 4 }}
spec:
  rules:
  - host: {{ .Values.ingress.host }}
    http:
      paths:
      {{- $id := .proxy.id -}}
      {{- $svc_name := include "fileproxy.fullname" . -}}
      {{ if .proxy.is_root }}
      - path: /
        pathType: Prefix
        backend:
          service:
            name: {{ $svc_name }}-{{ $id }}
            port:
              name: http
      {{ else }}
      {{- range .proxy.mounts }}
      - path: {{ .path }}
        pathType: Prefix
        backend:
          service:
            name: {{ $svc_name }}-{{ $id }}
            port:
              name: http
      {{- end }}
      {{- end }}



{{- end }}
