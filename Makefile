SHELL := /bin/bash

# Load variables from .env if it exists
-include .env

# local dir with files you want to send
PRIVATE_SEND_DIR ?= data/send
# local dir where files are moved after transfer
PRIVATE_TRANSFERRED_DIR ?= data/transferred
# specific file to zip (leave empty to zip all files in PRIVATE_SEND_DIR)
PRIVATE_INPUT_FILENAME ?=

# name of the zip file to create and transfer (e.g., my_dataset.zip)
# if empty, batch transfer mode is used
PRIVATE_OUTPUT_ZIP ?=
ifneq ($(PRIVATE_OUTPUT_ZIP),)
    DATA_FILE ?= data/$(PRIVATE_OUTPUT_ZIP)
endif

REMOTE_PATH ?= ~/private-data-hosting/data/
VM_USER ?=

.PHONY: help setup-server setup-uploader up transfer zip
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

zip: ## Zip files from send directory to data/output.zip
	@mkdir -p $(PRIVATE_SEND_DIR)
	@mkdir -p $(PRIVATE_TRANSFERRED_DIR)
	@if [ -n "$(DATA_FILE)" ]; then \
		read -p "Output zip file will be $(DATA_FILE). Is this correct? (y/n): " confirm; \
		if [ "$$confirm" != "y" ]; then \
			read -p "Enter output zip filename (e.g. mydata.zip): " new_zip_name; \
			target_file="data/$$new_zip_name"; \
		else \
			target_file="$(DATA_FILE)"; \
		fi; \
	else \
		read -p "Enter output zip filename (e.g. mydata.zip): " new_zip_name; \
		target_file="data/$$new_zip_name"; \
	fi; \
	if [ -n "$(PRIVATE_INPUT_FILENAME)" ]; then \
		if [ -f "$(PRIVATE_SEND_DIR)/$(PRIVATE_INPUT_FILENAME)" ]; then \
			echo "Zipping specific file: $(PRIVATE_SEND_DIR)/$(PRIVATE_INPUT_FILENAME)"; \
			zip -j $$target_file "$(PRIVATE_SEND_DIR)/$(PRIVATE_INPUT_FILENAME)"; \
		else \
			echo "Error: File $(PRIVATE_SEND_DIR)/$(PRIVATE_INPUT_FILENAME) not found."; \
			exit 1; \
		fi \
	else \
		echo "Zipping all files in $(PRIVATE_SEND_DIR)"; \
		if [ -z "$$(ls -A $(PRIVATE_SEND_DIR))" ]; then \
		   echo "Error: $(PRIVATE_SEND_DIR) is empty."; \
		   exit 1; \
		fi; \
		zip -j $$target_file $(PRIVATE_SEND_DIR)/* -x "*.gitkeep"; \
	fi; \
	echo "Zipped data to $$target_file"
	@echo ""
	@echo "Next step: Run 'make setup-uploader' to configure your connection, then 'make transfer'."

setup-server: ## [Server Admin] Interactive setup to generate .env file on server
	@echo "Setting up server configuration..."
	@if [ -f .env ]; then \
		read -p ".env file already exists. Overwrite? (y/N): " overwrite; \
		if [ "$$overwrite" != "y" ] && [ "$$overwrite" != "Y" ]; then \
			echo "Aborting setup."; \
			exit 0; \
		fi; \
	fi
	@cp .env.sample .env
	@echo "Generating API Key..."
	@api_key=$$(openssl rand -hex 32); \
	if [[ "$$OSTYPE" == "darwin"* ]]; then \
		sed -i '' "s/^API_KEY=.*/API_KEY=$$api_key/" .env; \
	else \
		sed -i "s/^API_KEY=.*/API_KEY=$$api_key/" .env; \
	fi
	@echo "Detecting Public IP..."
	@public_ip=$$(curl -s ifconfig.me); \
	echo "Detected IP: $$public_ip"; \
	if [[ "$$OSTYPE" == "darwin"* ]]; then \
		sed -i '' "s/^PRIVATE_DOWNLOAD_IP=.*/PRIVATE_DOWNLOAD_IP=$$public_ip/" .env; \
	else \
		sed -i "s/^PRIVATE_DOWNLOAD_IP=.*/PRIVATE_DOWNLOAD_IP=$$public_ip/" .env; \
	fi
	@echo ".env file created successfully."
	@echo "API_KEY set."
	@echo "PRIVATE_DOWNLOAD_IP set to $$public_ip"

setup-uploader: ## [Uploader] Interactive setup for local .env
	@echo "Setting up uploader configuration..."
	@if [ ! -f .env ]; then \
		cp .env.sample .env; \
		echo "Created .env from .env.sample"; \
	fi
	@read -p "Enter Server IP: " vm_ip; \
	if [[ "$$OSTYPE" == "darwin"* ]]; then \
		sed -i '' "s/^PRIVATE_DOWNLOAD_IP=.*/PRIVATE_DOWNLOAD_IP=$$vm_ip/" .env; \
	else \
		sed -i "s/^PRIVATE_DOWNLOAD_IP=.*/PRIVATE_DOWNLOAD_IP=$$vm_ip/" .env; \
	fi
	@read -p "Enter Remote Username (check with 'whoami' on server): " vm_user; \
	if [[ "$$OSTYPE" == "darwin"* ]]; then \
		sed -i '' "s/^VM_USER=.*/VM_USER=$$vm_user/" .env; \
	else \
		sed -i "s/^VM_USER=.*/VM_USER=$$vm_user/" .env; \
	fi
	@echo "Configuration updated."

up: ## Start the server with Docker Compose
	docker compose up --build -d

transfer: ## [Uploader] Transfer data (Batch all .zips if no specific file set)
	@if [ -z "$(PRIVATE_DOWNLOAD_IP)" ]; then \
		echo "Error: PRIVATE_DOWNLOAD_IP is not set. Please run 'make setup-uploader' or set manually in .env"; \
		exit 1; \
	fi
	@vm_user="$(VM_USER)"; \
	if [ -z "$$vm_user" ]; then \
		read -p "Remote username not set. Enter remote username (run 'whoami' on server to check): " vm_user; \
	fi; \
	if [ -z "$$vm_user" ]; then \
		echo "Error: VM_USER is required."; \
		exit 1; \
	fi; \
	if [ -n "$(DATA_FILE)" ] && [ -f "$(DATA_FILE)" ]; then \
		echo "Single File Mode: Transferring $(DATA_FILE)..."; \
		scp $(DATA_FILE) $$vm_user@$(PRIVATE_DOWNLOAD_IP):$(REMOTE_PATH); \
		echo "Transfer complete."; \
		echo "Moving processed files to $(PRIVATE_TRANSFERRED_DIR)..."; \
		if [ -n "$(PRIVATE_INPUT_FILENAME)" ]; then \
			mv "$(PRIVATE_SEND_DIR)/$(PRIVATE_INPUT_FILENAME)" "$(PRIVATE_TRANSFERRED_DIR)/"; \
		else \
			mv $(PRIVATE_SEND_DIR)/* "$(PRIVATE_TRANSFERRED_DIR)/"; \
		fi; \
		echo "Files moved to $(PRIVATE_TRANSFERRED_DIR)."; \
	else \
		echo "Batch Mode: No DATA_FILE specified. Looking for .zip files in $(PRIVATE_SEND_DIR)..."; \
		if ls $(PRIVATE_SEND_DIR)/*.zip 1> /dev/null 2>&1; then \
			for file in $(PRIVATE_SEND_DIR)/*.zip; do \
				echo "-----------------------------------"; \
				echo "Found: $$file"; \
				echo "Transferring to $$vm_user@$(PRIVATE_DOWNLOAD_IP)..."; \
				scp "$$file" $$vm_user@$(PRIVATE_DOWNLOAD_IP):$(REMOTE_PATH); \
				echo "Moving $$file to $(PRIVATE_TRANSFERRED_DIR)..."; \
				mv "$$file" "$(PRIVATE_TRANSFERRED_DIR)/"; \
			done; \
			echo "-----------------------------------"; \
			echo "Batch transfer complete."; \
		else \
			echo "No .zip files found in $(PRIVATE_SEND_DIR). Nothing to transfer."; \
			exit 1; \
		fi; \
	fi