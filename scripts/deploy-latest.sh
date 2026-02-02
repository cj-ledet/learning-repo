#!/usr/bin/env bash
set -euo pipefail

# Deploy newest sha-* image from ECR to kind/demo via Helm.
# Requires: aws, kubectl, helm

NAMESPACE="${NAMESPACE:-demo}"
RELEASE="${RELEASE:-learning-api}"
CHART_PATH="${CHART_PATH:-./deploy/helm/learning-api}"

AWS_REGION="${AWS_REGION:-us-west-2}"
ACCOUNT_ID="${ACCOUNT_ID:-781530536964}"
ECR_REPO_NAME="${ECR_REPO_NAME:-learning-api}"

ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_REPO="${ECR_REGISTRY}/${ECR_REPO_NAME}"

# Find the most recently pushed tag that starts with "sha-"
LATEST_TAG="$(
  aws ecr describe-images \
    --region "$AWS_REGION" \
    --repository-name "$ECR_REPO_NAME" \
    --query 'sort_by(imageDetails,&imagePushedAt)[-1].imageTags[?starts_with(@, `sha-`)] | [0]' \
    --output text
)"

if [[ -z "${LATEST_TAG}" || "${LATEST_TAG}" == "None" ]]; then
  echo "ERROR: Could not find a sha-* tag in ECR repo ${ECR_REPO_NAME} (${AWS_REGION})." >&2
  echo "Try: aws ecr list-images --repository-name ${ECR_REPO_NAME} --region ${AWS_REGION}" >&2
  exit 1
fi

echo "Deploying latest image:"
echo "  image = ${IMAGE_REPO}:${LATEST_TAG}"
echo "  release = ${RELEASE}"
echo "  namespace = ${NAMESPACE}"
echo

helm upgrade "$RELEASE" "$CHART_PATH" -n "$NAMESPACE" --create-namespace \
  --set image.repository="$IMAGE_REPO" \
  --set image.tag="$LATEST_TAG" \
  --set image.pullPolicy="IfNotPresent"

kubectl rollout status "deployment/${RELEASE}" -n "$NAMESPACE"

POD="$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/instance="$RELEASE" -o jsonpath='{.items[0].metadata.name}')"
echo
echo "Running pod image:"
kubectl describe pod -n "$NAMESPACE" "$POD" | grep -E "Image:|Image ID:" || true
