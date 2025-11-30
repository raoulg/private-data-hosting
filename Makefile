# Makefile

# Load variables from .env if it exists
-include .env

# Default values (can be overridden by .env or command line)
DATA_FILE ?= data/ai_challenge.zip
REMOTE_PATH ?= ~/private-data-hosting/data/

.PHONY: help setup up transfer zip
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

zip: ## Zip the data files in the data/ folder
	@read -p "Zipping to $(DATA_FILE). Is this correct? (y/n): " confirm; \
	if [ "$$confirm" != "y" ]; then \
		read -p "Enter output filename: " new_file; \
		zip -j $$new_file data/* -x "*.zip" -x "*.gitkeep"; \
		echo "Zipped data to $$new_file"; \
	else \
		zip -j $(DATA_FILE) data/* -x "*.zip" -x "*.gitkeep"; \
		echo "Zipped data to $(DATA_FILE)"; \
	fi

setup: ## Interactive setup to generate .env file
	@echo "Setting up configuration..."
	@if [ -f .env ]; then \
		read -p ".env file already exists. Overwrite? (y/N): " overwrite; \
		if [ "$$overwrite" != "y" ] && [ "$$overwrite" != "Y" ]; then \
			echo "Aborting setup."; \
			exit 0; \
		fi; \
	fi
	@read -p "Enter VM User [ubuntu]: " vm_user; \
	vm_user=$${vm_user:-ubuntu}; \
	read -p "Enter VM IP: " vm_ip; \
	echo "Generating API Key..."; \
	api_key=$$(openssl rand -hex 32); \
	echo "VM_USER=$$vm_user" > .env; \
	echo "VM_IP=$$vm_ip" >> .env; \
	echo "API_KEY=$$api_key" >> .env; \
	echo ".env file created successfully."

up: ## Start the server with Docker Compose
	docker compose up --build -d

transfer: ## Transfer data to the VM
	@if [ -z "$(VM_IP)" ]; then \
		echo "Error: VM_IP is not set. Please run 'make setup' or set it in .env"; \
		exit 1; \
	fi
	@if [ -f "$(DATA_FILE)" ]; then \
		read -p "Found $(DATA_FILE). Is this what you want to transfer? (y/n): " confirm; \
		if [ "$$confirm" != "y" ]; then \
			read -p "Enter filename to transfer: " new_file; \
			scp $$new_file $(VM_USER)@$(VM_IP):$(REMOTE_PATH); \
		else \
			scp $(DATA_FILE) $(VM_USER)@$(VM_IP):$(REMOTE_PATH); \
		fi \
	else \
		echo "File $(DATA_FILE) not found."; \
		read -p "Enter filename to transfer: " new_file; \
		scp $$new_file $(VM_USER)@$(VM_IP):$(REMOTE_PATH); \
	fi
