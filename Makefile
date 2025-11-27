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

zip: ## Zip the data files
	zip -j $(DATA_FILE) data/* -x "*.zip" -x "*.gitkeep"
	@echo "Zipped data to $(DATA_FILE)"

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
	echo "DATA_FILE_NAME=ai_challenge.zip" >> .env; \
	echo ".env file created successfully."

up: ## Start the server with Docker Compose
	docker compose up --build -d

transfer: ## Transfer data to the VM
	@if [ -z "$(VM_IP)" ]; then \
		echo "Error: VM_IP is not set. Please run 'make setup' or set it in .env"; \
		exit 1; \
	fi
	scp $(DATA_FILE) $(VM_USER)@$(VM_IP):$(REMOTE_PATH)
