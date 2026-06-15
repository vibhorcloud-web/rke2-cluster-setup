SHELL := /usr/bin/env bash
S := provisioning

.PHONY: help all prereqs vms cluster kubeconfig verify destroy status \
        ssh-cp1 ssh-w1 ssh-w2

help:
	@echo "rke2-cluster-setup — RKE2 + Cilium on Multipass (macOS)"
	@echo
	@echo "  make all         End-to-end: prereqs → vms → cluster → kubeconfig → verify"
	@echo "  make prereqs     Install multipass/kubectl via brew, set up SSH key"
	@echo "  make vms         Create + boot 3 VMs via Multipass cloud-init"
	@echo "  make cluster     Bootstrap RKE2 server, agents, and Cilium"
	@echo "  make kubeconfig  Pull kubeconfig to .state/kubeconfig and print it"
	@echo "  make argocd      Deploy ArgoCD and bootstrap GitOps"
	@echo "  make verify      kubectl get nodes / pods / cilium"
	@echo "  make destroy     Tear down VMs and lab state"
	@echo "  make status      Show multipass instances + node status"
	@echo "  make ssh-cp1 / ssh-w1 / ssh-w2   SSH to a VM"
	@echo
	@echo "  Optional extras: see ./slurm-operator/ for SLURM-on-Kubernetes examples (run manually)"

all: prereqs vms cluster kubeconfig argocd verify

prereqs:
	$(S)/prep_host.sh

vms:
	$(S)/launch_vms.sh

cluster:
	$(S)/bootstrap_cluster.sh

kubeconfig:
	$(S)/get_kubeconfig.sh --print

argocd:
	chmod +x $(S)/deploy_argocd.sh
	$(S)/deploy_argocd.sh

verify:
	$(S)/test_cluster.sh

destroy:
	$(S)/teardown.sh

status:
	@multipass list
	@echo
	@if [ -f .state/kubeconfig ]; then \
	  KUBECONFIG=$$PWD/.state/kubeconfig kubectl get nodes -o wide; \
	else \
	  echo '(no kubeconfig yet — run "make kubeconfig")'; \
	fi

ssh-cp1:
	@multipass shell cp1

ssh-w1:
	@multipass shell worker1

ssh-w2:
	@multipass shell worker2
