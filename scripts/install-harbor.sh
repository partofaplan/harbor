#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_CONTEXT="${KUBE_CONTEXT:-picard}"

if ! kubectl config get-contexts "${TARGET_CONTEXT}" >/dev/null 2>&1; then
  if kubectl config get-contexts "k3d-picard" >/dev/null 2>&1; then
    kubectl config rename-context k3d-picard "${TARGET_CONTEXT}"
  else
    echo "Target context '${TARGET_CONTEXT}' was not found. Available contexts:" >&2
    kubectl config get-contexts >&2
    exit 1
  fi
fi

kubectl config use-context "${TARGET_CONTEXT}"

kubectl create namespace harbor --dry-run=client -o yaml | kubectl apply -f -

helm repo add goharbor https://helm.goharbor.io >/dev/null 2>&1 || true
helm repo update

helm upgrade --install harbor goharbor/harbor \
  --namespace harbor \
  --create-namespace \
  --values "${REPO_ROOT}/deploy/harbor/values.yaml" \
  --wait \
  --timeout 10m

echo
printf 'Harbor installed successfully in namespace harbor.\n'
printf 'Use: kubectl -n harbor get pods\n'
printf 'Use: kubectl -n harbor port-forward svc/harbor 8080:80\n'
