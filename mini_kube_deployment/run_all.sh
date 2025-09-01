#!/bin/bash
set -e

echo "kill all old portforward"
# Kill existing port-forwards first
pkill -f "kubectl port-forward" || true
sleep 2

# Delete old pods
echo "Deleting old namespaces"
kubectl delete namespace wordpress monitoring --ignore-not-found=true
kubectl wait --for=delete namespace wordpress --timeout=180s 2>/dev/null || true
kubectl wait --for=delete namespace monitoring --timeout=180s 2>/dev/null || true

echo "creating namespaces"
# create new Namespaces
kubectl apply -f wordpress/namespace.yml
kubectl apply -f monitoring/namespace.yml

echo "create ecr secret"
#create ecr secret
PASSWORD=$(aws ecr get-login-password --region us-east-1)
kubectl create secret docker-registry ecr-secret \
  --docker-server=992382545251.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$PASSWORD \
  -n wordpress

echo "dowload helm"
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod +x get_helm.sh
./get_helm.sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

echo "deploying WordPress"
# WordPress
kubectl apply -f wordpress/secret.yml
kubectl apply -f wordpress/pvc.yml
kubectl apply -f wordpress/stateful_mysql.yml
kubectl apply -f wordpress/dep_wordpress.yml
kubectl apply -f wordpress/wordpress_service.yml
kubectl apply -f wordpress/mysql_service.yml
kubectl apply -f wordpress/wordpress_ingress.yml

echo "deploying monitoring"
# Monitoring
kubectl apply -f monitoring/prometheus-rbac.yml
kubectl apply -f monitoring/prometheus-config.yml
kubectl apply -f monitoring/kube-state-metrics.yml
kubectl apply -f monitoring/grafana_pvc.yml
kubectl apply -f monitoring/dep_grafana.yml
kubectl apply -f monitoring/grafana_service.yml
kubectl apply -f monitoring/grafana_ingress.yml
kubectl apply -f monitoring/prometheus_pvc.yml
kubectl apply -f monitoring/dep_prometheus.yml
kubectl apply -f monitoring/prometheus_service.yml
kubectl apply -f monitoring/prometheus_ingress.yml

echo "All resources applied successfully"

echo "Waiting for pods to be ready"
# Wait for pods to be ready with better error handling
kubectl wait --for=condition=ready pod -l app=kube-state-metrics -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod -l app=mysql -n wordpress --timeout=300s
kubectl wait --for=condition=ready pod -l app=wordpress -n wordpress --timeout=300s
kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=300s

echo "Starting port-forwarding"
# Port forwarding with PID tracking
kubectl port-forward -n wordpress svc/wordpress-service 8080:80 --address=0.0.0.0 &
WORDPRESS_PID=$!

kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 --address=0.0.0.0 &
GRAFANA_PID=$!

kubectl port-forward -n monitoring svc/prometheus-service 9090:9090 --address=0.0.0.0 &
PROMETHEUS_PID=$!

# Wait for port-forwards to establish
sleep 5

echo "Services are available at:"
echo "   WordPress:  http://$(curl -s ifconfig.me):8080"
echo "   Grafana:    http://$(curl -s ifconfig.me):3000"
echo "   Prometheus: http://$(curl -s ifconfig.me):9090"

wait
