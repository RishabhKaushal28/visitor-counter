#!/usr/bin/env bash
# Self-healing demo: delete one web pod, watch Kubernetes replace it.
set -euo pipefail
CTX=${CTX:-kind-private}

echo "== Before =="
kubectl --context "$CTX" get pods -l app=web
POD=$(kubectl --context "$CTX" get pods -l app=web -o jsonpath='{.items[0].metadata.name}')
echo "Deleting $POD ..."
kubectl --context "$CTX" delete pod "$POD" --wait=false
sleep 2
echo "== After (new pod appears) =="
kubectl --context "$CTX" get pods -l app=web
kubectl --context "$CTX" rollout status deployment/web
kubectl --context "$CTX" get pods -l app=web
