#!/usr/bin/env bash
set -euo pipefail

for port in 8080 8081; do
  curl --fail --silent --show-error --max-time 15 "http://127.0.0.1:${port}/health" |
    jq -e '.status == "ok"' >/dev/null
  curl --fail --silent --show-error --max-time 15 "http://127.0.0.1:${port}/api/products" |
    jq -e 'type == "array" and length > 0' >/dev/null
done

status=$(curl --silent --show-error --max-time 15 --output /dev/null \
  --write-out '%{http_code}' --request POST http://127.0.0.1:8080/api/products)
test "$status" = 403
