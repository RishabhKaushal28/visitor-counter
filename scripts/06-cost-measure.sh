#!/usr/bin/env bash
# Measure BEFORE vs AFTER values for the cost table. Uses the private cluster.
set -euo pipefail
cd "$(dirname "$0")/.."
CTX=kind-private
OUT=cost-measurements.txt

# Assumed unit prices (edit and state in your report)
CPU_PRICE=0.04      # USD per vCPU-hour
MEM_PRICE=0.005     # USD per GB-hour

measure() {
  label=$1
  echo "===== $label =====" | tee -a "$OUT"
  echo "Image size:" | tee -a "$OUT"
  docker images visitor-app --format '{{.Tag}} {{.Size}}' | tee -a "$OUT"
  echo "Pods:" | tee -a "$OUT"
  kubectl --context $CTX get pods -l app=web --no-headers | tee -a "$OUT"
  echo "Actual usage (kubectl top):" | tee -a "$OUT"
  kubectl --context $CTX top pods -l app=web | tee -a "$OUT"

  # Sum requested CPU (m) and memory (Mi) across web pods
  kubectl --context $CTX get pods -l app=web -o json | python3 -c "
import json,sys
cpu=mem=0
for p in json.load(sys.stdin)['items']:
    r=p['spec']['containers'][0]['resources']['requests']
    c=r['cpu']; cpu+= int(c[:-1]) if c.endswith('m') else int(float(c)*1000)
    m=r['memory']; mem+= int(m[:-2]) if m.endswith('Mi') else int(m[:-2])*1024
cph=cpu/1000*$CPU_PRICE; mph=mem/1024*$MEM_PRICE
print(f'Total requested: {cpu}m CPU, {mem}Mi memory')
print(f'Est. cost: \${cph+mph:.4f}/hr  (\${(cph+mph)*730:.2f}/month)')
" | tee -a "$OUT"
}

: > "$OUT"

echo "### Deploying BEFORE configuration (6 fixed replicas, big image, big requests)"
kubectl --context $CTX delete hpa web-hpa --ignore-not-found
kubectl --context $CTX apply -f k8s-before/web-deployment-before.yaml
kubectl --context $CTX rollout status deployment/web --timeout=180s
sleep 60   # let metrics-server collect
measure "BEFORE"

echo "### Deploying AFTER configuration (optimized image, right-sized, HPA min 2)"
kubectl --context $CTX apply -f k8s/web-deployment.yaml
kubectl --context $CTX set env deployment/web CLUSTER_NAME=private
kubectl --context $CTX apply -f k8s/hpa.yaml
kubectl --context $CTX rollout status deployment/web --timeout=180s
sleep 60
measure "AFTER"

echo "Saved to $OUT - copy the numbers into cost-analysis.md"
