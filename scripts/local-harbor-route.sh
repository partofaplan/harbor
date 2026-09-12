#!/usr/bin/env bash
set -euo pipefail

HOSTNAME="${1:-harbor.here}"
TARGET_PORT="${2:-80}"
CONTEXT="${KUBE_CONTEXT:-picard}"

if ! kubectl config get-contexts "${CONTEXT}" >/dev/null 2>&1; then
  echo "Context '${CONTEXT}' not found. Available contexts:" >&2
  kubectl config get-contexts >&2
  exit 1
fi

kubectl config use-context "${CONTEXT}"

PORT_FORWARD_CMD=(kubectl -n kube-system port-forward svc/traefik "${TARGET_PORT}:80" --address 127.0.0.1)

printf 'Starting local Traefik forward on http://127.0.0.1:%s\n' "${TARGET_PORT}"
printf 'Route: http://%s\n' "${HOSTNAME}"

# Ensure /etc/hosts entry exists for the host
if ! grep -Eq "^[^#]*[[:space:]]${HOSTNAME}(\s|$)" /etc/hosts; then
  echo "Adding ${HOSTNAME} -> 127.0.0.1 to /etc/hosts"
  printf '\n127.0.0.1 %s\n' "${HOSTNAME}" | sudo tee -a /etc/hosts >/dev/null
fi

printf '\nOpen: http://%s/\n' "${HOSTNAME}"
printf 'To stop this forward, press Ctrl+C\n\n'

"${PORT_FORWARD_CMD[@]}"
