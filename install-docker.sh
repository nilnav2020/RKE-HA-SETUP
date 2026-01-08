#!/bin/bash
set -e

SSH_USER="ubuntu"
SSH_KEY="$HOME/.ssh/RKE.pem"

NODES=(
  "10.0.0.47"   # cp-01
  "10.0.0.251"  # cp-02
  "10.0.0.109"  # cp-03
  "10.0.0.63"   # wk-01
  "10.0.0.179"  # wk-02
)

echo "=== Docker Clean Install Started ==="

for NODE in "${NODES[@]}"; do
  echo
  echo ">>> Processing node: $NODE"
  echo "-----------------------------------"

  ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ${SSH_USER}@${NODE} <<'EOF'
set -e

echo "[1/8] Removing broken Docker repo BEFORE any apt operation..."
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/keyrings/docker.gpg

echo "[2/8] Removing old Docker packages..."
sudo apt remove -y docker docker-engine docker.io containerd runc || true
sudo apt autoremove -y

echo "[3/8] Installing prerequisites..."
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

echo "[4/8] Adding Docker GPG key (non-interactive)..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor --batch --yes -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "[5/8] Adding Docker repository..."
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu noble stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "[6/8] Installing Docker CE..."
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

echo "[7/8] Enabling Docker and permissions..."
sudo systemctl enable docker
sudo systemctl restart docker
sudo usermod -aG docker ubuntu

echo "[8/8] Docker version check:"
docker version | grep -E 'Version|API'

echo "Node completed successfully."
EOF

done

echo
echo "=== Docker Clean Install Completed ==="
echo "IMPORTANT: Reboot or log out/log in on all nodes to apply docker group changes."
