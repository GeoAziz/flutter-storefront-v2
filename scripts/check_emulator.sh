#!/usr/bin/env bash
# Quick check whether the Firestore emulator is running on the default port
set -euo pipefail
PORT=${1:-8080}
HOST=${2:-127.0.0.1}

echo "Checking emulator at ${HOST}:${PORT}..."
if command -v ss >/dev/null 2>&1; then
  ss -ltnp | grep -q ":${PORT} " && echo "OK: port ${PORT} is listening" || echo "WARN: port ${PORT} not listening"
elif command -v lsof >/dev/null 2>&1; then
  lsof -i :${PORT} | grep -q LISTEN && echo "OK: port ${PORT} is listening" || echo "WARN: port ${PORT} not listening"
else
  echo "No ss/lsof available to check listening ports; try curl below."
fi

echo "Probe Firestore REST endpoint..."
curl -fsS "http://${HOST}:${PORT}/v1/projects/demo-project/databases/(default)/documents/products?pageSize=1" || echo "Probe failed (connection error)"
