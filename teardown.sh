#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
read -r -p "This destroys the whole cluster + infra. Type 'yes' to continue: " ans
[ "$ans" = "yes" ] || { echo "Aborted."; exit 1; }
echo "==> Removing load-balancer-backed resources first"
kubectl delete ingress --all -A --ignore-not-found 2>/dev/null || true
helm uninstall ingress-nginx -n ingress-nginx 2>/dev/null || true
helm uninstall kube-prom -n monitoring 2>/dev/null || true
helm uninstall loki -n monitoring 2>/dev/null || true
helm uninstall tempo -n monitoring 2>/dev/null || true
kubectl delete -f argocd/application.yaml --ignore-not-found 2>/dev/null || true
echo "==> Waiting 40s for cloud load balancers to delete..."
sleep 40
echo "==> Destroying infrastructure"
cd terraform && terraform destroy -auto-approve
echo "Done. Verify in the AWS console: EC2 instances / Load Balancers / NAT Gateways are empty."
