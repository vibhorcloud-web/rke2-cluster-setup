SHELL := /usr/bin/env bash
S := scripts

.PHONY: help all prereqs vms cluster kubeconfig verify destroy status \
        ssh-cp1 ssh-w1 ssh-w2

help:
	@echo "instant-rke2-lab — RKE2 + Cilium on Multipass (macOS)"
	@echo
	@echo "  make all         End-to-end: prereqs → vms → cluster → kubeconfig → verify"
	@echo "  make prereqs     Install multipass/kubectl via brew, set up SSH key"
	@echo "  make vms         Create + boot 3 VMs via Multipass cloud-init"
	@echo "  make cluster     Bootstrap RKE2 server, agents, and Cilium"
	@echo "  make kubeconfig  Pull kubeconfig to .state/kubeconfig and print it"
	@echo "  make verify      kubectl get nodes / pods / cilium"
	@echo "  make destroy     Tear down VMs and lab state"
	@echo "  make status      Show multipass instances + node status"
	@echo "  make ssh-cp1 / ssh-w1 / ssh-w2   SSH to a VM"
	@echo
	@echo "  Optional extras: see ./slinky/ for SLURM-on-Kubernetes examples (run manually)"

all: prereqs vms cluster kubeconfig verify

prereqs:
	$(S)/00-host-prep.sh

vms:
	$(S)/20-create-vms.sh

cluster:
	$(S)/30-bootstrap-rke2.sh

kubeconfig:
	$(S)/40-fetch-kubeconfig.sh --print

verify:
	$(S)/50-verify.sh

destroy:
	$(S)/99-destroy.sh

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
