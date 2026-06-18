#!/usr/bin/env bash
set -euo pipefail
REGION="${REGION:-ap-south-1}"
REPO_SLUG="${REPO_SLUG:-Prajwalsp83/devops-demo}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
echo "==> OIDC provider"
aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com --client-id-list sts.amazonaws.com --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 || true
echo "==> IAM role scoped to ${REPO_SLUG}"
cat > /tmp/trust.json <<JSON
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"},
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {"token.actions.githubusercontent.com:aud": "sts.amazonaws.com"},
      "StringLike": {"token.actions.githubusercontent.com:sub": "repo:${REPO_SLUG}:*"}
    }
  }]
}
JSON
aws iam create-role --role-name github-actions-ecr --assume-role-policy-document file:///tmp/trust.json || true
aws iam attach-role-policy --role-name github-actions-ecr --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser || true
rm -f /tmp/trust.json
echo "==> Set the role ARN in the workflow"
sed -i.bak "s|arn:aws:iam::[0-9A-Za-z<>_]*:role/github-actions-ecr|arn:aws:iam::${ACCOUNT_ID}:role/github-actions-ecr|" .github/workflows/ci-cd.yaml && rm -f .github/workflows/ci-cd.yaml.bak
echo "Done. Commit + push the workflow change, then every push auto-builds & deploys."
