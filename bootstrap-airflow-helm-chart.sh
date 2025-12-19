#!/usr/bin/env bash
set -euo pipefail

CHART_DIR="chart"

echo "🚀 Bootstrapping minimal Airflow Helm chart in ./${CHART_DIR}"

# -------------------------------------------------------------------
# Create directory structure
# -------------------------------------------------------------------
mkdir -p ${CHART_DIR}/templates

# -------------------------------------------------------------------
# Chart.yaml
# -------------------------------------------------------------------
cat > ${CHART_DIR}/Chart.yaml <<'EOF'
apiVersion: v2
name: airflow-prototype
description: Minimal Airflow (standalone) Helm chart for prototype deployments
type: application
version: 0.1.0
appVersion: "2.9.3"
EOF

# -------------------------------------------------------------------
# values.yaml
# -------------------------------------------------------------------
cat > ${CHART_DIR}/values.yaml <<'EOF'
image:
  repository: dennishbb/airflow-prototype
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 8080

airflow:
  executor: SequentialExecutor
  loadExamples: "False"

  admin:
    username: admin
    password: admin
    email: admin@example.com
    firstname: Admin
    lastname: User

resources: {}
nodeSelector: {}
tolerations: []
affinity: {}
EOF

# -------------------------------------------------------------------
# templates/_helpers.tpl
# -------------------------------------------------------------------
cat > ${CHART_DIR}/templates/_helpers.tpl <<'EOF'
{{- define "airflow-prototype.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "airflow-prototype.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" (include "airflow-prototype.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "airflow-prototype.labels" -}}
app.kubernetes.io/name: {{ include "airflow-prototype.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | quote }}
{{- end -}}
EOF

# -------------------------------------------------------------------
# templates/secret.yaml
# -------------------------------------------------------------------
cat > ${CHART_DIR}/templates/secret.yaml <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "airflow-prototype.fullname" . }}-secret
  labels:
    {{- include "airflow-prototype.labels" . | nindent 4 }}
type: Opaque
stringData:
  AIRFLOW__CORE__FERNET_KEY: "THIS_IS_NOT_SECURE_CHANGE_ME"
  AIRFLOW__WEBSERVER__SECRET_KEY: "THIS_IS_NOT_SECURE_CHANGE_ME"
  _AIRFLOW_WWW_USER_USERNAME: {{ .Values.airflow.admin.username | quote }}
  _AIRFLOW_WWW_USER_PASSWORD: {{ .Values.airflow.admin.password | quote }}
  _AIRFLOW_WWW_USER_EMAIL: {{ .Values.airflow.admin.email | quote }}
  _AIRFLOW_WWW_USER_FIRSTNAME: {{ .Values.airflow.admin.firstname | quote }}
  _AIRFLOW_WWW_USER_LASTNAME: {{ .Values.airflow.admin.lastname | quote }}
EOF

# -------------------------------------------------------------------
# templates/deployment.yaml
# -------------------------------------------------------------------
cat > ${CHART_DIR}/templates/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "airflow-prototype.fullname" . }}
  labels:
    {{- include "airflow-prototype.labels" . | nindent 4 }}
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ include "airflow-prototype.name" . }}
      app.kubernetes.io/instance: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ include "airflow-prototype.name" . }}
        app.kubernetes.io/instance: {{ .Release.Name }}
    spec:
      containers:
        - name: airflow
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: 8080
              name: http
          env:
            - name: AIRFLOW__CORE__EXECUTOR
              value: {{ .Values.airflow.executor | quote }}
            - name: AIRFLOW__CORE__LOAD_EXAMPLES
              value: {{ .Values.airflow.loadExamples | quote }}
            - name: AIRFLOW_HOME
              value: /opt/airflow
          envFrom:
            - secretRef:
                name: {{ include "airflow-prototype.fullname" . }}-secret
          command: ["/bin/bash", "-lc"]
          args:
            - |
              set -euo pipefail
              echo "Starting Airflow standalone..."
              airflow standalone
          readinessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 60
            periodSeconds: 20
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
      nodeSelector:
        {{- toYaml .Values.nodeSelector | nindent 8 }}
      tolerations:
        {{- toYaml .Values.tolerations | nindent 8 }}
      affinity:
        {{- toYaml .Values.affinity | nindent 8 }}
EOF

# -------------------------------------------------------------------
# templates/service.yaml
# -------------------------------------------------------------------
cat > ${CHART_DIR}/templates/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: {{ include "airflow-prototype.fullname" . }}
  labels:
    {{- include "airflow-prototype.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  selector:
    app.kubernetes.io/name: {{ include "airflow-prototype.name" . }}
    app.kubernetes.io/instance: {{ .Release.Name }}
  ports:
    - name: http
      port: {{ .Values.service.port }}
      targetPort: http
EOF

echo "✅ Helm chart bootstrapped successfully"
echo "➡️ Next steps:"
echo "   helm lint ./chart"
echo "   helm template airflow ./chart"
echo "   helm upgrade --install airflow ./chart -n airflow-dev --create-namespace"

