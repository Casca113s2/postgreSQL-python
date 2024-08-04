#!/bin/bash

# Enable debugging
set -x

# Variables
DOMAIN="dev-app.cascabase.online"
ROOT_URL="https://dev-app.cascabase.online/grafana/"

# Create directory and set privilages
sudo mkdir /home/$(whoami)/grafana_config_volumes
sudo mkdir /home/$(whoami)/grafana_config_volumes/loki
sudo mkdir /home/$(whoami)/grafana_config_volumes/promtail
sudo mkdir /home/$(whoami)/grafana_config_volumes/grafana
sudo mkdir /home/$(whoami)/grafana_config_volumes/grafana_config
sudo chmod -R 777 /home/$(whoami)/grafana_config_volumes/grafana

# Create The docker-compose.yml
sudo bash -c "cat > /home/$(whoami)/grafana_config_volumes/docker-compose.yml <<EOF
version: \"3\"

services:
  loki:
    image: grafana/loki:latest
    volumes:
      - /home/$(whoami)/grafana_config_volumes/loki:/etc/loki
    ports:
      - \"3100:3100\"
    restart: unless-stopped
    command: -config.file=/etc/loki/loki-config.yml
    networks:
      - loki

  promtail:
    image: grafana/promtail:latest
    volumes:
      - /var/log:/var/log
      - /home/$(whoami)/grafana_config_volumes/promtail:/etc/promtail
    command: -config.file=/etc/promtail/promtail-config.yml
    networks:
      - loki

  grafana:
    image: grafana/grafana:latest
    user: \"1000\"
    volumes:
      - /home/$(whoami)/grafana_config_volumes/grafana_config:/etc/grafana_config
      - /home/$(whoami)/grafana_config_volumes/grafana:/var/lib/grafana
    command: --config /etc/grafana_config/grafana.custom
    ports:
      - \"3000:3000\"
    restart: unless-stopped
    networks:
      - loki

networks:
  loki:
EOF"

# Create The Loki Config
sudo bash -c "cat > /home/$(whoami)/grafana_config_volumes/loki/loki-config.yml <<EOF
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  path_prefix: /tmp/loki
  storage:
    filesystem:
      chunks_directory: /tmp/loki/chunks
      rules_directory: /tmp/loki/rules
  replication_factor: 1
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

ruler:
  alertmanager_url: http://localhost:9093
EOF"

# Create The Promtail Config
sudo bash -c "cat > /home/$(whoami)/grafana_config_volumes/promtail/promtail-config.yml <<EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: docker 
    pipeline_stages:
     - docker: {}
    static_configs:
     - labels:
         job: docker
         __path__: /var/lib/docker/containers/*/*-json.log
EOF"

# Create The Grafana Config
sudo bash -c "cat > /home/$(whoami)/grafana_config_volumes/grafana_config/grafana.custom <<EOF
[server]
protocol = http
domain = $DOMAIN
root_url = $ROOT_URL
EOF"

# Install Loki Docker Drive
docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions

DAEMON_CONFIG='{
    "log-driver": "loki",
    "log-opts": {
        "loki-url": "http://localhost:3100/loki/api/v1/push",
        "loki-batch-size": "400"
    }
}'

echo "$DAEMON_CONFIG" | sudo tee /etc/docker/daemon.json > /dev/null

sudo systemctl restart docker

# Running the container
docker compose -f /home/$(whoami)/grafana_config_volumes/docker-compose.yml up -d --force-recreate