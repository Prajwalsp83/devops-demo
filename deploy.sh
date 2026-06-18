#!/usr/bin/env bash
set -euo pipefail
REGION="${REGION:-ap-south-1}"
CLUSTER="${CLUSTER:-devops-demo}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REPO="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/devops-demo-app"
echo "==> Account ${ACCOUNT_ID}, repo ${REPO}"
echo "==> [1/7] kubeconfig"
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER"
echo "==> [2/7] build + push app image to ECR"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REPO"
docker build --platform linux/amd64 -t "${REPO}:latest" ./app
docker push "${REPO}:latest"
echo "==> [3/7] point Helm values at this account's ECR and push"
sed -i.bak "s|repository:.*|repository: ${REPO}|" helm/values.yaml && rm -f helm/values.yaml.bak
if ! git diff --quiet helm/values.yaml 2>/dev/null || [ ! -d .git ]; then
  git init && git add . && git commit -m "chore: set ECR repo [skip ci]" 2>/dev/null || git add helm/values.yaml && git commit -m "chore: set ECR repo [skip ci]" 2>/dev/null || true
  git push 2>/dev/null || echo "Git push skipped (not a remote)"
fi
echo "==> [4/7] ingress-nginx + metrics-server"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
helm repo update >/dev/null
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type=json -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' || true
echo "==> [5/7] ArgoCD"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --server-side
kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p '{"data":{"server.insecure":"true"}}'
kubectl -n argocd rollout restart deploy/argocd-server
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s
echo "==> [6/7] deploy the app via ArgoCD"
kubectl apply -f argocd/application.yaml
echo "==> [7/7] observability stack"
./monitoring/install-monitoring.sh
echo ""
echo "============================================================"
echo "DONE. Useful commands:"
echo "  App LB:    kubectl get svc -n ingress-nginx"
echo "  App test:  curl -H 'Host: demo.local' http://<LB-HOSTNAME>/"
echo "  Grafana:   kubectl port-forward svc/kube-prom-grafana -n monitoring 3000:80  -> http://localhost:3000 (admin/admin)"
echo "  ArgoCD:    kubectl port-forward svc/argocd-server -n argocd 8080:80          -> http://localhost:8080"
echo "============================================================"
