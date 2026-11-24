#!/usr/bin/env bash
cd "$(dirname "$0")/.."
docker compose down -v 2>/dev/null
(cd failover && docker compose down 2>/dev/null)
kind delete cluster --name private
kind delete cluster --name public
