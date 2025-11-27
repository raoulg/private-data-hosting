# Makefile

# Variables for transfer
VM_USER ?= ubuntu
VM_IP ?= <YOUR_VM_IP>
DATA_FILE ?= data/ai_challenge.zip
REMOTE_PATH ?= ~/my-server/data/

.PHONY: setup up transfer zip

zip:
	zip -j $(DATA_FILE) data/aktes.jsonl data/README.md data/rechtsfeiten.csv
	@echo "Zipped data to $(DATA_FILE)"

setup:
	@echo "Generating .env file..."
	@echo "API_KEY=$$(openssl rand -hex 32)" > .env
	@echo "DATA_FILE_NAME=ai_challenge.zip" >> .env
	@echo ".env file created with secure API_KEY and DATA_FILE_NAME."

up:
	docker-compose up --build -d

transfer:
	@if [ "$(VM_IP)" = "<YOUR_VM_IP>" ]; then \
		echo "Error: VM_IP is not set. Please set it in the Makefile or pass it as an argument (e.g., make transfer VM_IP=1.2.3.4)"; \
		exit 1; \
	fi
	scp $(DATA_FILE) $(VM_USER)@$(VM_IP):$(REMOTE_PATH)
