#!/bin/bash

# Define your Helm chart name and version
CHART_NAME="musicbrainz-helm-chart"
CHART_VERSION="0.1.0"

# Create the Helm chart directory
mkdir -p $CHART_NAME/templates

# Create a values.yaml file
cat <<EOL > $CHART_NAME/values.yaml
image:
  repository: ghcr.io/linuxserver/musicbrainz
  tag: latest

containerName: musicbrainz

environment:
  PUID: 1000
  PGID: 1000
  TZ: Europe/London
  BRAINZCODE: <code from MusicBrainz>
  WEBADDRESS: <ip of host>
  NPROC: <parameter>

volumes:
  configVolume:
    hostPath: </path/to/appdata/config>
  dataVolume:
    hostPath: </path/to/appdata/data>

ports:
  - name: http
    containerPort: 5000

restartPolicy: unless-stopped
EOL

# Create a deployment.yaml file
cat <<EOL > $CHART_NAME/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-musicbrainz
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{ .Release.Name }}-musicbrainz
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}-musicbrainz
    spec:
      containers:
      - name: {{ .Values.containerName }}
        image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
        env:
        {{- toYaml .Values.environment | nindent 12 }}
        ports:
        - name: http
          containerPort: {{ .Values.ports.http.containerPort }}
        volumeMounts:
        - name: config-volume
          mountPath: /config
        - name: data-volume
          mountPath: /data
      volumes:
      - name: config-volume
        hostPath:
          path: {{ .Values.volumes.configVolume.hostPath }}
      - name: data-volume
        hostPath:
          path: {{ .Values.volumes.dataVolume.hostPath }}
EOL

# Create a service.yaml file
cat <<EOL > $CHART_NAME/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-musicbrainz-service
spec:
  selector:
    app: {{ .Release.Name }}-musicbrainz
  ports:
    - name: http
      port: 5000
      targetPort: http
  type: LoadBalancer # You can use NodePort or ClusterIP depending on your setup.
EOL

# Create a Chart.yaml file
cat <<EOL > $CHART_NAME/Chart.yaml
apiVersion: v2
name: $CHART_NAME
description: A Helm chart for deploying MusicBrainz with Docker
version: $CHART_VERSION
EOL

# Package the Helm chart
helm package $CHART_NAME

echo "Helm chart created and packaged as $CHART_NAME-$CHART_VERSION.tgz"
