#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <git-sha>"
  echo "Example: $0 8370a8a75e88dd494b378c34326410bafdd6ddef"
  exit 1
fi

SHA="$1"
NAMESPACE="demo"
RELEASE="learning-api"
CHART="./deploy/helm/learning-api"
REPO="781530536964.dkr.ecr.us-west-2.amazonaws.com/learning-api"

helm upgrade "$RELEASE" "$CHART" -n "$NAMESPACE" --create-namespace \
  --set image.repository="$REPO" \
  --set image.tag="sha-$SHA"

kubectl rollout status deployment/"$RELEASE" -n "$NAMESPACE"
