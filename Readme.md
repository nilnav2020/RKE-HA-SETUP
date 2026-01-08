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
10.0.0.47   lb-01
10.0.0.55   cp-01
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
# we complete the mandatory kernel and networking preparation required for Kubernetes.



# Load Kernel Modules Required by Kubernetes

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
