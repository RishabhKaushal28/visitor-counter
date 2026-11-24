#!/usr/bin/env bash
# Build the BEFORE and AFTER images and print their sizes (cost-analysis input).
set -euo pipefail
cd "$(dirname "$0")/.."

docker build -t visitor-app:before -f app/Dockerfile.before app/
docker build -t visitor-app:optimized -f app/Dockerfile app/

echo
echo "== Image sizes (screenshot this) =="
docker images visitor-app --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
