#!/usr/bin/env bash
# Create the private + (simulated) public kind clusters and deploy the app on both.
set -euo pipefail
cd "$(dirname "$0")/.."

METRICS_URL="https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"

for name in private public; do
  if ! kind get clusters | grep -qx "$name"; then
    kind create cluster --name "$name" --config "kind-$name.yaml"
  fi
  ctx="kind-$name"

  kind load docker-image visitor-app:optimized visitor-app:before --name "$name"

  kubectl --context "$ctx" apply -f k8s/redis-deployment.yaml -f k8s/redis-service.yaml
  kubectl --context "$ctx" apply -f k8s/web-deployment.yaml -f k8s/web-service.yaml
  kubectl --context "$ctx" set env deployment/web CLUSTER_NAME="$name"

  # metrics-server (needed by the HPA); kind needs --kubelet-insecure-tls
  kubectl --context "$ctx" apply -f "$METRICS_URL"
  kubectl --context "$ctx" -n kube-system patch deployment metrics-server --type=json \
    -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

  kubectl --context "$ctx" apply -f k8s/hpa.yaml
  kubectl --context "$ctx" rollout status deployment/web --timeout=120s
done

echo
echo "== Private cluster =="; kubectl --context kind-private get pods,svc,hpa
echo "== Public cluster  =="; kubectl --context kind-public  get pods,svc,hpa
echo
echo "Private: http://localhost:8081   Public: http://localhost:8082"
