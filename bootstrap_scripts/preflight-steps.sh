#!/bin/bash
set -euo pipefail

SSH_USER=ubuntu
ALL_NODES=("cp-01" "cp-02" "cp-03" "wk-01" "wk-02")

LB_HOST=lb-01
LB_IP=10.0.0.55

declare -A NODE_IPS=(
  [cp-01]=10.0.0.47
  [cp-02]=10.0.0.251
  [cp-03]=10.0.0.109
  [wk-01]=10.0.0.88
  [wk-02]=10.0.0.89
)

echo "[INFO] Generating SSH key if missing"
[ -f ~/.ssh/id_rsa ] || ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

for NODE in "${ALL_NODES[@]}"; do
  echo "[INFO] Preflight on $NODE"

  ssh-copy-id -o StrictHostKeyChecking=no ${SSH_USER}@${NODE}

  ssh ${SSH_USER}@${NODE} bash <<EOF
set -e

sudo hostnamectl set-hostname ${NODE}

sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

sudo modprobe br_netfilter
sudo modprobe overlay

cat <<SYS | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables=1
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-ip6tables=1
SYS

sudo sysctl --system

# /etc/hosts
sudo sed -i '/cp-|wk-|lb-/d' /etc/hosts
echo "${LB_IP} ${LB_HOST}" | sudo tee -a /etc/hosts

EOF

done

# fan out node IPs
for NODE in "${!NODE_IPS[@]}"; do
  for TARGET in "${ALL_NODES[@]}"; do
    ssh ${SSH_USER}@${TARGET} "echo '${NODE_IPS[$NODE]} $NODE' | sudo tee -a /etc/hosts"
  done
done

echo "[SUCCESS] Preflight completed on all nodes"
