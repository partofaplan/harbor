#!/usr/bin/env bash
set -euo pipefail

TARGET_CONTEXT="${KUBE_CONTEXT:-picard}"

kubectl config use-context "${TARGET_CONTEXT}"

kubectl -n harbor get pods
kubectl -n harbor get svc,pvc

kubectl -n harbor rollout status deployment/harbor-core --timeout=180s
kubectl -n harbor rollout status deployment/harbor-jobservice --timeout=180s
kubectl -n harbor rollout status deployment/harbor-nginx --timeout=180s
kubectl -n harbor rollout status deployment/harbor-portal --timeout=180s
kubectl -n harbor rollout status deployment/harbor-registry --timeout=180s
kubectl -n harbor rollout status statefulset/harbor-database --timeout=180s
kubectl -n harbor rollout status statefulset/harbor-redis --timeout=180s

PORT_FORWARD_PID="$(lsof -ti :8080 || true)"
if [[ -n "${PORT_FORWARD_PID}" ]]; then
  kill "${PORT_FORWARD_PID}" >/dev/null 2>&1 || true
fi

kubectl -n harbor port-forward svc/harbor 8080:80 >/tmp/harbor-port-forward.log 2>&1 &
PORT_FORWARD_PID=$!
trap 'kill ${PORT_FORWARD_PID} >/dev/null 2>&1 || true' EXIT

for _ in $(seq 1 30); do
  if curl -fsS http://localhost:8080 >/tmp/harbor-health.txt 2>/dev/null; then
    break
  fi
  sleep 2
done

HTTP_CODE="$(curl -sS -o /tmp/harbor-health.txt -w '%{http_code}' http://localhost:8080 || true)"
REGISTRY_CODE="$(curl -sS -o /tmp/harbor-registry.txt -w '%{http_code}' http://localhost:8080/v2/ || true)"

printf '\nHTTP status for Harbor UI: %s\n' "${HTTP_CODE}"
printf 'HTTP status for registry API: %s\n' "${REGISTRY_CODE}"
head -n 20 /tmp/harbor-health.txt
printf '\n---\n'
head -n 20 /tmp/harbor-registry.txt
