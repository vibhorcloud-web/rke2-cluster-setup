# rke2-cluster-setup

A self-contained **RKE2 + Cilium + ArgoCD GitOps** Kubernetes lab that runs natively on macOS using **Multipass**.

One control-plane node and two workers are automatically provisioned. Once the cluster is bootstrapped, **ArgoCD** is deployed to take over cluster configuration and automatically deploys **Cilium, Longhorn, Ingress-Nginx, and OpenBao** using the App of Apps GitOps pattern.

## What you get

- **RKE2** (Rancher's hardened upstream Kubernetes) on the `stable` channel
- **Multipass VMs** running Ubuntu 24.04 with dynamically assigned IPs
- **ArgoCD GitOps** built-in for declarative cluster management
- **Cilium** CNI managed by ArgoCD (`kubeProxyReplacement: true`)
- **Longhorn** for distributed block storage
- **Ingress-Nginx** as the Ingress controller
- **OpenBao** for secrets management
- A few examples to run SLURM in the `slurm-examples` folder

## Requirements

- **macOS** host
- Homebrew installed
- ~50 GiB free disk, ~32 GiB free RAM at the default sizing

## Quickstart

```bash
git clone https://github.com/vibhorcloud-web/rke2-cluster-setup.git
cd rke2-cluster-setup
make all
```

That runs, in order:

| Step              | What it does                                              |
| ----------------- | --------------------------------------------------------- |
| `make prereqs`    | Install `multipass` and `kubectl` via brew, create SSH key|
| `make vms`        | Create + boot 3 VMs via `multipass launch`                |
| `make cluster`    | Install RKE2 server, then 2 RKE2 agents                   |
| `make kubeconfig` | Pull kubeconfig and rewrite the server URL                |
| `make argocd`     | Install ArgoCD and apply the GitOps Bootstrap App         |
| `make verify`     | `kubectl get nodes / pods` from the host                  |

When it's done:

```bash
export KUBECONFIG=$PWD/.state/kubeconfig
kubectl get nodes -o wide
kubectl -n argocd get applications
```

> **Note on GitOps**: The ArgoCD App of Apps (`argo-apps/bootstrap/app-of-apps.yaml`) is configured to pull directly from your GitHub repository. You **must push your branch to GitHub** before ArgoCD can successfully deploy Longhorn, Nginx, OpenBao, and Cilium updates.

## Tunables

All knobs live in [`settings.env`](./settings.env). Edit before `make all`. Common changes:

```bash
# VM definitions
VM_LIST=(
  "cp1     4  8G  60G server"
  "worker1 6 16G  80G agent"
  "worker2 6 16G  80G agent"
)

# Pin a specific RKE2 version instead of "stable"
RKE2_VERSION="v1.35.4+rke2r1"
```

## Operations

```bash
make status              # multipass instance status + k8s nodes
make ssh-cp1             # ssh into the control plane
make ssh-w1 / ssh-w2     # ssh into a worker
make destroy             # rip the lab down using multipass delete
make all                 # rebuild from scratch
```

## Repository layout

```
.
├── Makefile                # all the entry points
├── settings.env            # tunables (sizes, RKE2 channel)
├── argo-apps/              # GitOps Definitions
│   ├── bootstrap/          # App of Apps root
│   └── apps/               # Cilium, Longhorn, Ingress-Nginx, OpenBao
├── provisioning/           # Core Bash Scripts
│   ├── common.sh           # logging, dynamic IP helpers
│   ├── prep_host.sh
│   ├── launch_vms.sh
│   ├── bootstrap_cluster.sh
│   ├── get_kubeconfig.sh
│   ├── deploy_argocd.sh
│   ├── test_cluster.sh
│   └── teardown.sh
├── k8s-manifests/
│   └── rke2-cilium-config.yaml   # Initial Cilium HelmChartConfig for RKE2
└── .state/                 # generated, gitignored: ssh_key, kubeconfig
```

## Troubleshooting

**A VM never reaches SSH.** Run `multipass shell <name>` or check `multipass info <name>` to see if the VM is hung during cloud-init.

**ArgoCD Apps aren't syncing.** Check that you pushed your local changes to the remote repository that ArgoCD is watching (`https://github.com/vibhorcloud-web/rke2-cluster-setup.git`).

**Tear down completely:**
```bash
make destroy
```

## Security note

This is a **lab**. The control plane writes its kubeconfig at mode `0644` so the host can grab it. Cilium runs with permissive defaults and Hubble UI is unauthenticated. Don't expose any of this to a network you don't fully trust.
