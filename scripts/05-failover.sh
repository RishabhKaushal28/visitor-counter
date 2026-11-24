#!/usr/bin/env bash
# Hybrid failover demo through the nginx proxy on http://localhost:8080
set -euo pipefail
cd "$(dirname "$0")/../failover"

docker compose up -d
sleep 2

show() { curl -s --max-time 5 http://localhost:8080 | grep -o 'Cluster: <code>[a-z]*' || echo "NO RESPONSE"; }

echo "== Normal: traffic goes to the PRIVATE cluster =="
show; show

echo "== Stopping the private cluster =="
docker stop private-control-plane
sleep 3

echo "== Failover: traffic now served by the PUBLIC cluster =="
show; show

echo "== Recovery: starting the private cluster again =="
docker start private-control-plane
echo "Wait ~30-60s for the API server, then run: curl localhost:8080"
