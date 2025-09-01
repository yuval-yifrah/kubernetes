#!/bin/bash

set -e

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

