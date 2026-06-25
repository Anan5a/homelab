#!/usr/bin/env bash
set -e

mkdir -p volumes/db/data
mkdir -p volumes/db/init
mkdir -p volumes/storage
mkdir -p volumes/kong
mkdir -p volumes/analytics
mkdir -p volumes/logs
mkdir -p volumes/functions/main

# Minimal vector config so the analytics pipeline has something to ship
cat > volumes/logs/vector.yml <<'EOF'
api:
  enabled: true
  address: 0.0.0.0:9001

sources:
  docker_logs:
    type: docker_logs
    docker_host: unix:///var/run/docker.sock

sinks:
  console:
    type: console
    inputs:
      - docker_logs
    encoding:
      codec: json
EOF

# Minimal placeholder edge function so the functions container has something to serve
cat > volumes/functions/main/index.ts <<'EOF'
Deno.serve(() => new Response("Edge functions are running"));
EOF

echo "Volume directories created."
echo "Next: drop your kong.yml into volumes/kong/kong.yml and fill in .env"