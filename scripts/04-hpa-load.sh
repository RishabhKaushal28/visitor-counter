#!/usr/bin/env bash
# HPA demo. Run this in terminal 1, and `kubectl get hpa -w` in terminal 2 for screenshots.
set -euo pipefail
CTX=${CTX:-kind-private}
LOG=hpa-log.txt

echo "Start in another terminal:  kubectl --context $CTX get hpa -w"
echo "Generating load for 5 minutes (4 parallel clients on /load) ..."

kubectl --context "$CTX" delete pod load --ignore-not-found
kubectl --context "$CTX" run load --image=busybox:1.36 --restart=Never -- /bin/sh -c \
  'for i in 1 2 3 4; do (while true; do wget -q -O- http://web-service/load >/dev/null; done) & done; wait'

: > "$LOG"
echo "time | cpu/target | replicas" | tee -a "$LOG"
for i in $(seq 1 30); do   # 30 x 10s = 5 min
  line=$(kubectl --context "$CTX" get hpa web-hpa --no-headers | awk '{print $3" | replicas="$6}')
  echo "$(date +%H:%M:%S) | $line" | tee -a "$LOG"
  sleep 10
done

echo "Stopping load; watch scale-down (takes ~5 min stabilization)."
kubectl --context "$CTX" delete pod load --wait=false
for i in $(seq 1 36); do   # 36 x 10s = 6 min
  line=$(kubectl --context "$CTX" get hpa web-hpa --no-headers | awk '{print $3" | replicas="$6}')
  echo "$(date +%H:%M:%S) | $line" | tee -a "$LOG"
  sleep 10
done
echo "Replica timeline saved to $LOG"
