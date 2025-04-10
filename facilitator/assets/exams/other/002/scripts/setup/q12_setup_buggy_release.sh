#!/bin/bash
# Setup script for Question 12: Create a buggy Helm release

# Create exam directory
mkdir -p /tmp/exam/q12

# Create a simple chart with an intentional issue
mkdir -p /tmp/buggy-chart/templates

# Create Chart.yaml
cat <<EOF > /tmp/buggy-chart/Chart.yaml
apiVersion: v2
name: buggy-app
description: A buggy Helm chart for demonstration
version: 0.1.0
appVersion: 1.0.0
EOF

# Create values.yaml with an incorrect image reference
cat <<EOF > /tmp/buggy-chart/values.yaml
replicaCount: 1

image:
  repository: nginx
  # Intentionally using a non-existent tag
  tag: nonexistenttag
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80
EOF

# Create a deployment template with an issue
cat <<EOF > /tmp/buggy-chart/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
  labels:
    app.kubernetes.io/name: {{ .Release.Name }}
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ .Release.Name }}
      app.kubernetes.io/instance: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ .Release.Name }}
        app.kubernetes.io/instance: {{ .Release.Name }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
EOF

# Create a service template
cat <<EOF > /tmp/buggy-chart/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}
  labels:
    app.kubernetes.io/name: {{ .Release.Name }}
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app.kubernetes.io/name: {{ .Release.Name }}
    app.kubernetes.io/instance: {{ .Release.Name }}
EOF

# Install the buggy chart
helm install buggy-app /tmp/buggy-chart

# Clean up the temporary chart directory
rm -rf /tmp/buggy-chart

echo "Buggy Helm release 'buggy-app' has been created"
exit 0 