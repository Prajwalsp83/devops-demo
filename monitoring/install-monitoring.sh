#!/usr/bin/env bash
set -euo pipefail
NS=monitoring
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "==> Helm repos"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo add grafana https://grafana.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null
echo "==> Metrics: kube-prometheus-stack"
helm upgrade --install kube-prom prometheus-community/kube-prometheus-stack -n $NS --create-namespace -f "$HERE/kube-prometheus-stack-values.yaml"
echo "==> Logs: Loki + Promtail"
helm upgrade --install loki grafana/loki-stack -n $NS --set promtail.enabled=true --set loki.persistence.enabled=false --set loki.fullnameOverride=loki
echo "==> Traces: Tempo"
helm upgrade --install tempo grafana/tempo -n $NS -f "$HERE/tempo-values.yaml"
echo "==> ServiceMonitor for the app"
kubectl apply -f "$HERE/app-servicemonitor.yaml"
echo "Monitoring installed. Grafana: kubectl port-forward svc/kube-prom-grafana -n $NS 3000:80 (admin/admin)"
