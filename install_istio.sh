#!/bin/bash

# Set variables
ISTIO_VERSION="1.15.0" # You can specify the version you need
CLUSTER_NAME="side-project-cluster"
REGION="il-central-1"

# Download Istio
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
cd istio-$ISTIO_VERSION

# Add istioctl to your PATH
export PATH=$PWD/bin:$PATH

# Verify the istioctl version
istioctl version

# Create a namespace for Istio components
kubectl create namespace istio-system

# Install Istio base components
istioctl install --set profile=default -y

# Label the default namespace to automatically inject Istio sidecar proxies
kubectl label namespace default istio-injection=enabled

# Verify the installation
kubectl get pods -n istio-system

echo "Istio $ISTIO_VERSION installation is complete!"
