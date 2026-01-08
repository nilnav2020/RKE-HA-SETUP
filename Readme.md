# at last we need one touch setup deployment 

```bash
              ┌──────────────────────┐
              │   NGINX Load Balancer │
              │   (API VIP :6443)    │
              └──────────┬───────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ Control +   │  │ Control +   │  │ Control +   │
│ etcd node 1 │  │ etcd node 2 │  │ etcd node 3 │
└─────────────┘  └─────────────┘  └─────────────┘

        ┌────────────────────────────────┐
        │          Worker Nodes           │
        │      (apps run here)            │
        └────────────────────────────────┘

```
# provision 7 servers -- 1 bastian , 6 machine for RKE

```bash
| Private IP | Hostname | Role                   |
| ---------- | -------- | ---------------------- |
| 10.0.0.47  | cp-01    | Control Plane + etcd   |
| 10.0.0.251 | cp-02    | Control Plane + etcd   |
| 10.0.0.109 | cp-03    | Control Plane + etcd   |
| 10.0.0.55  | lb-01    | External Load Balancer |
| 10.0.0.63  | wk-01    | Worker                 |
| 10.0.0.179 | wk-02    | Worker                 |

```

```bash
| Port        | Protocol | Source      | Purpose       |
| ----------- | -------- | ----------- | ------------- |
| 22          | TCP      | Your IP     | SSH           |
| 6443        | TCP      | Subnet CIDR | K8s API       |
| 2379–2380   | TCP      | Subnet CIDR | etcd          |
| 10250       | TCP      | Subnet CIDR | kubelet       |
| 10251–10252 | TCP      | Subnet CIDR | control plane |
| 30000–32767 | TCP      | Subnet CIDR | NodePort      |
| ALL         | ICMP     | Subnet CIDR | Debug         |
```


# on bastian host
confirgure ssh -- passswordless to other 6 nodes and also update hostname on all the 6 servers and then uodate the host entry on bastian host
```bash
sudo nano /etc/hosts
10.0.0.47   cp-01
10.0.0.55   lb-01
10.0.0.251  cp-02
10.0.0.109  cp-03
10.0.0.63   wk-01
10.0.0.179  wk-02

# — Edit SSH config on bastion
nano ~/.ssh/config
# make the following entry
Host 10.0.0.* cp-* wk-* lb-*
  User ubuntu
  IdentityFile ~/.ssh/RKE.pem
  IdentitiesOnly yes
  StrictHostKeyChecking no

```

# PHASE 2 — OS PREPARATION
we will now complete the mandatory kernel and networking preparation required for Kubernetes.
Swap should disabled on all machines
# These modules are required for:

1.Container networking

2.kube-proxy

3.CNI plugins (Calico/Canal)

# on ALL 6 cluster nodes

# Load modules immediately
```bash
sudo modprobe overlay
sudo modprobe br_netfilter
#Persist modules across reboots
sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
# verify
lsmod | grep -E 'overlay|br_netfilter'
#Apply sysctl Settings for Kubernetes Networking
# 1. Create sysctl config
sudo tee /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                = 1
EOF
 Create sysctl config
sudo sysctl --system
#verify
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.ipv4.ip_forward

```
# install docker on all the  machines except lb-01 and bastian host
```bash
sudo su
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release
#adding GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
# adding official repo
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# install docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
# allow user access to docker
sudo usermod -aG docker ubuntu
# verify
docker version
docker ps
```
# you can use the script install --> intall-docker.sh to install it on all machines (just update it with correct ip)

# NGINX TCP Load Balancer for Kubernetes API (HA)

Target Node --> lb-01
Role: External Load Balancer

```bash
sudo apt update
sudo apt install -y nginx
nginx -v
systemctl status nginx

# Install NGINX Stream Module
sudo apt install -y libnginx-mod-stream
ls /usr/lib/nginx/modules | grep stream
# — Verify Stream Module Is Enabled
ls -l /etc/nginx/modules-enabled/ | grep stream
```
# — Create Stream Configuration Directory and conf file
```bash
sudo mkdir -p /etc/nginx/stream.d

sudo nano /etc/nginx/stream.d/k8s-api.conf
```
add the following lines in the above file
```bash
upstream k8s_api {
    least_conn;
    server 10.0.0.47:6443;   # cp-01
    server 10.0.0.251:6443;  # cp-02
    server 10.0.0.109:6443;  # cp-03
}

server {
    listen 6443;
    proxy_pass k8s_api;
    proxy_timeout 10m;
    proxy_connect_timeout 5s;
}
```
# Register Stream Context in nginx.conf
file --> sudo nano /etc/nginx/nginx.conf
Locate this line -- include /etc/nginx/modules-enabled/*.conf;
Immediately after it, add:
```bash
stream {
    include /etc/nginx/stream.d/*.conf;
}
```
verify -->
sudo nginx -t























