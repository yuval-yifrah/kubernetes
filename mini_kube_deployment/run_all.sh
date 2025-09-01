#!/bin/bash

set -e

#delete old pods
kubectl delete namespace wordpress monitoring
kubectl wait --for=delete namespace wordpress --timeout=180s
kubectl wait --for=delete namespace monitoring --timeout=180s

# --- Namespaces ---
kubectl apply -f wordpress/namespace.yml
kubectl apply -f monitoring/namespace.yml

# --- WordPress ---
kubectl apply -f wordpress/secret.yml
kubectl apply -f wordpress/pvc.yml
kubectl apply -f wordpress/stateful_mysql.yml
kubectl apply -f wordpress/dep_wordpress.yml
kubectl apply -f wordpress/wordpress_service.yml
kubectl apply -f wordpress/mysql_service.yml
kubectl apply -f wordpress/wordpress_ingress.yml

# --- Monitoring ---
kubectl apply -f monitoring/grafana_pvc.yml
kubectl apply -f monitoring/dep_grafana.yml
kubectl apply -f monitoring/grafana_service.yml
kubectl apply -f monitoring/grafana_ingress.yml

kubectl apply -f monitoring/prometheus_pvc.yml
kubectl apply -f monitoring/dep_prometheus.yml
kubectl apply -f monitoring/prometheus_service.yml
kubectl apply -f monitoring/prometheus_ingress.yml

echo "All resources applied successfully!"
#waits for the pods to be ready
kubectl wait --for=condition=ready pod -l app=wordpress -n wordpress --timeout=300s
kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=300s

#portforwarding them
kubectl port-forward -n wordpress svc/wordpress-service 8080:80 --address=0.0.0.0 &
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 --address=0.0.0.0 &
kubectl port-forward -n monitoring svc/prometheus-service 9090:9090 --address=0.0.0.0 &

