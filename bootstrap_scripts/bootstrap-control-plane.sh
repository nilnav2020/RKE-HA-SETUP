#!/bin/bash
set -euo pipefail

SSH_USER=ubuntu
CP_INIT=cp-01
CP_JOIN=("cp-02" "cp-03")

LB_HOST=lb-01
TOKEN_FILE=/tmp/rke2-node-token

echo "[INFO] Bootstrapping initial control plane: ${CP_INIT}"

ssh ${SSH_USER}@${CP_INIT} bash <<'EOF'
set -e
curl -sfL https://get.rke2.io | sudo sh -

sudo mkdir -p /etc/rancher/rke2

cat <<CFG | sudo tee /etc/rancher/rke2/config.yaml
tls-san:
  - lb-01
write-kubeconfig-mode: "0644"
disable:
  - rke2-ingress-nginx
CFG

sudo systemctl enable rke2-server
sudo systemctl start rke2-server
EOF

echo "[INFO] Waiting for node-token to be generated"
sleep 60

echo "[INFO] Fetching RKE2 token from ${CP_INIT}"
ssh ${SSH_USER}@${CP_INIT} sudo cat /var/lib/rancher/rke2/server/node-token > ${TOKEN_FILE}

RKE2_TOKEN=$(cat ${TOKEN_FILE})

echo "[INFO] Joining remaining control planes"

for NODE in "${CP_JOIN[@]}"; do
  echo "[INFO] Joining ${NODE}"

  ssh ${SSH_USER}@${NODE} bash <<EOF
set -e
curl -sfL https://get.rke2.io | sudo sh -

sudo mkdir -p /etc/rancher/rke2

cat <<CFG | sudo tee /etc/rancher/rke2/config.yaml
server: https://${LB_HOST}:9345
token: ${RKE2_TOKEN}
tls-san:
  - ${LB_HOST}
write-kubeconfig-mode: "0644"
disable:
  - rke2-ingress-nginx
CFG

sudo systemctl enable rke2-server
sudo systemctl start rke2-server
EOF

done

echo "[SUCCESS] Control plane fully bootstrapped"
