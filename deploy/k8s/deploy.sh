#!/bin/bash

# Totem de Pedidos - Kubernetes Deployment Script
# This script deploys the complete Totem de Pedidos application to Kubernetes

set -e

echo "🚀 Starting Totem de Pedidos deployment..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we can connect to Kubernetes cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    exit 1
fi

echo "✅ Kubernetes cluster connection verified"

# Apply manifests in the correct order
# echo "📦 Creating namespace..."
# kubectl apply -f namespace.yaml

echo "🔧 Creating ConfigMaps..."
kubectl apply -f configmap.yaml

echo "🔐 Creating Secrets..."
kubectl apply -f secret.yaml

echo "🚀 Deploying application..."
kubectl apply -f app-deployment.yaml
kubectl apply -f app-service.yaml

echo "⏳ Waiting for application to be ready..."
kubectl wait --for=condition=Available deployment/totem-pedidos-app -n totem-pedidos --timeout=300s

echo "🌐 Creating Ingress..."
kubectl apply -f ingress.yaml

echo "📊 Creating HPA..."
kubectl apply -f hpa.yaml

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "   • Namespace: totem-pedidos"
echo "   • Application: totem-pedidos-app (3 replicas)"
echo "   • Database: External PostgreSQL (configure in configmap.yaml)"
echo "   • Autoscaling: 2-10 replicas based on CPU/Memory"
echo "   • Access: http://totem-pedidos.local"
echo ""
echo "📊 Useful commands:"
echo "   • Check pods: kubectl get pods -n totem-pedidos"
echo "   • Check services: kubectl get svc -n totem-pedidos"
echo "   • Check ingress: kubectl get ingress -n totem-pedidos"
echo "   • View logs: kubectl logs -f deployment/totem-pedidos-app -n totem-pedidos"
echo "   • Check HPA: kubectl get hpa -n totem-pedidos"
echo ""
echo "⚠️  Note: Make sure to:"
echo "   1. Build and push your Docker image: 'totem-pedidos:latest'"
echo "   2. Update the image tag in app-deployment.yaml if needed"
echo "   3. Configure DNS or /etc/hosts for 'totem-pedidos.local'"
echo "   4. Update MP_NOTIFICATION_URL in secret.yaml with your actual domain"
