#!/bin/bash
set -euo pipefail

SSH_USER=ubuntu
WK_NODES=("wk-01" "wk-02")

LB_HOST=lb-01
TOKEN_FILE=/tmp/rke2-node-token

if [[ ! -f ${TOKEN_FILE} ]]; then
  echo "[ERROR] Token file not found. Run control-plane bootstrap first."
  exit 1
fi

RKE2_TOKEN=$(cat ${TOKEN_FILE})

for NODE in "${WK_NODES[@]}"; do
  echo "[INFO] Joining worker ${NODE}"

  ssh ${SSH_USER}@${NODE} bash <<EOF
set -e
curl -sfL https://get.rke2.io | sudo sh -

sudo mkdir -p /etc/rancher/rke2

cat <<CFG | sudo tee /etc/rancher/rke2/config.yaml
server: https://${LB_HOST}:9345
token: ${RKE2_TOKEN}
CFG

sudo systemctl enable rke2-agent
sudo systemctl start rke2-agent
EOF

done

echo "[SUCCESS] Workers joined"
