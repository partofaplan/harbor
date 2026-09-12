# Harbor on Kubernetes

This repository contains a minimal Harbor deployment that can run on any Kubernetes cluster, including local clusters such as k3d and kind.

## Included

- Minimal Harbor Helm values tuned for a lightweight registry
- Install helper script
- Verification helper script

## Prerequisites

- Kubernetes cluster with a working default `StorageClass`
- `kubectl` configured to the target cluster
- `helm` installed

## Target cluster naming

The local cluster in this workspace is a k3d cluster named `picard`, but the active Kubernetes context is `k3d-picard`. The install script normalizes that for convenience.

## Deploy

```bash
./scripts/install-harbor.sh
```

This creates the `harbor` namespace and installs Harbor with the values in `deploy/harbor/values.yaml` using the official `goharbor/harbor` chart.

## Verify

```bash
./scripts/check-harbor.sh
```

The verification script checks that Harbor pods are Ready, the service is available, and the registry UI is serving over a local port-forward.

## Access

After deployment, the UI can be accessed through a local port-forward:

```bash
kubectl -n harbor port-forward svc/harbor 8080:80
```

Then open:

- http://localhost:8080/
- Username: `admin`
- Password: use the generated admin password from the secret if you did not override it

## Customization

Update `deploy/harbor/values.yaml` before deployment to change:

- storage size and persistence settings
- admin password
- external URL
- whether TLS or ingress is enabled
- registry exposure mode

## Clean up

```bash
helm uninstall harbor -n harbor
kubectl delete namespace harbor
```
