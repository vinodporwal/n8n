#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
NODE="$DIR/nodejs/linux/bin/node"
N8N="$DIR/n8n/node_modules/.bin/n8n"

# Background (simple)
nohup "$NODE" "$N8N" start > "$DIR/n8n.log" 2>&1 &

# Optionally: Install as systemd service (if root)
if [ "$EUID" -eq 0 ]; then
    cp "$DIR/n8n.service_linux" /etc/systemd/system/n8n.service
    systemctl daemon-reexec
    systemctl enable n8n
    systemctl start n8n
fi
