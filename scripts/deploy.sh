#!/usr/bin/env bash
set -euo pipefail

RELEASE="${RELEASE:-learning-api}"
NAMESPACE="${NAMESPACE:-demo}"
CHART_PATH="${CHART_PATH:-./deploy/helm/learning-api}"
IMAGE_REPO="${IMAGE_REPO:-ghcr.io/cj-ledet/learning-repo}"

MODE="sha"
SHA=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --main) MODE="main"; shift ;;
    --sha) MODE="sha"; SHA="${2:-}"; shift 2 ;;
    -n|--namespace) NAMESPACE="${2:-}"; shift 2 ;;
    -r|--release) RELEASE="${2:-}"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ "$MODE" == "main" ]]; then
  TAG="main"
  PULL_POLICY="Always"
else
  if [[ -z "$SHA" ]]; then
    SHA="$(git rev-parse HEAD)"
  fi
  TAG="sha-$SHA"
  PULL_POLICY="IfNotPresent"
fi

echo "Deploying:"
echo "  release   = $RELEASE"
echo "  namespace = $NAMESPACE"
echo "  chart     = $CHART_PATH"
echo "  image     = $IMAGE_REPO:$TAG"
echo "  pullPolicy= $PULL_POLICY"
echo

helm upgrade --install "$RELEASE" "$CHART_PATH" -n "$NAMESPACE" --create-namespace \
  --set image.repository="$IMAGE_REPO" \
  --set image.tag="$TAG" \
  --set image.pullPolicy="$PULL_POLICY"

kubectl rollout status "deployment/$RELEASE" -n "$NAMESPACE"

POD="$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/instance="$RELEASE" -o jsonpath='{.items[0].metadata.name}')"
kubectl describe pod -n "$NAMESPACE" "$POD" | grep -E "Image:|Image ID:" || true
