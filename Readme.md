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
