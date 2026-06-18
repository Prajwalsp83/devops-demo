# DevOps End-to-End Platform (AWS, GitOps, Observability)

A complete, **one-command** DevOps platform: containerized app → Terraform/EKS → Helm → ArgoCD GitOps → nginx ingress → HPA → full observability (Prometheus, Grafana, Loki, Tempo), with GitHub Actions CI.

## TL;DR

```bash
cd terraform && terraform init && terraform apply && cd ..
./deploy.sh
./teardown.sh   # when done
```

`deploy.sh` does everything in order: detects your AWS account, builds + pushes the image, installs ingress-nginx + metrics-server, stands up ArgoCD, deploys the app, then brings up the full monitoring stack.

## What's included

- **app/** — Node.js app, OTel-instrumented, Dockerfile with multi-stage build
- **terraform/** — VPC + EKS (t3.large spot ×2) + ECR
- **helm/** — Deployment, Service (named port), Ingress, HPA
- **argocd/** — GitOps Application manifest
- **monitoring/** — Prometheus, Grafana, Loki, Tempo + ServiceMonitor
- **.github/workflows/** — CI: test → scan → build → push → tag bump
- **deploy.sh** — one-shot: app → ingress → ArgoCD → monitoring
- **teardown.sh** — safe shutdown (LBs first)
- **setup-cicd.sh** — GitHub OIDC + IAM role for auto-builds

## After deploy

```bash
kubectl get svc -n ingress-nginx           # app LB hostname
curl -H "Host: demo.local" http://<LB>/   # test the app
kubectl port-forward svc/kube-prom-grafana -n monitoring 3000:80  # Grafana
```

## Cost

~$0.40–0.60/hr with observability running. Tear down when done with `./teardown.sh`.

