.PHONY: help init plan apply destroy packer-build ansible-lint ansible-run deploy clean

TERRAFORM_DIR := terraform
ANSIBLE_DIR   := ansible
PACKER_DIR    := packer/ubuntu-2404
SCRIPTS_DIR   := scripts

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ─── Packer ──────────────────────────────────────────────

packer-init: ## Initialize Packer plugins
	cd $(PACKER_DIR) && packer init .

packer-validate: ## Validate Packer template
	cd $(PACKER_DIR) && packer validate .

packer-build: ## Build the Ubuntu 24.04 golden image template
	cd $(PACKER_DIR) && packer build .

# ─── Terraform / OpenTofu ────────────────────────────────

init: ## Initialize Terraform/OpenTofu
	cd $(TERRAFORM_DIR) && tofu init

validate: ## Validate Terraform configuration
	cd $(TERRAFORM_DIR) && tofu validate

plan: ## Show Terraform execution plan
	cd $(TERRAFORM_DIR) && tofu plan

apply: ## Apply Terraform changes (provision VMs/LXC)
	cd $(TERRAFORM_DIR) && tofu apply

destroy: ## Destroy all Terraform-managed infrastructure
	cd $(TERRAFORM_DIR) && tofu destroy

# ─── Ansible ─────────────────────────────────────────────

ansible-lint: ## Lint Ansible playbooks and roles
	cd $(ANSIBLE_DIR) && ansible-lint

ansible-run: ## Run the full Ansible site playbook
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/site.yml

ansible-run-docker: ## Run only the docker-host playbook
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/docker-host.yml

ansible-run-monitoring: ## Run only the monitoring playbook
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/monitoring.yml

# ─── Full Deployment ────────────────────────────────────

deploy: ## Full deployment: Packer → Terraform → Ansible
	bash $(SCRIPTS_DIR)/deploy.sh

# ─── Utilities ───────────────────────────────────────────

clean: ## Remove Terraform state and Packer cache (use with caution)
	rm -rf $(TERRAFORM_DIR)/.terraform
	rm -rf $(TERRAFORM_DIR)/*.tfstate*
	rm -rf $(PACKER_DIR)/packer_cache
