# SURF Data Server Setup

## 1. Preparation on the VM

SSH into your VM and create the project folders:

```bash
mkdir -p ~/my-server/data
cd ~/my-server
```

## 2. Setup

We use a `Makefile` to automate the setup.

### Generate API Key and Configuration
Run the following command on the VM to generate an `.env` file with a secure `API_KEY` and the data filename:

```bash
make setup
```

This will create an `.env` file.

### Start the Server
To build and start the server using Docker Compose:

```bash
make up
```

## 3. Prepare Data
Before transferring, zip the data file:

```bash
make zip
```

## 4. Transferring Data

You can transfer the data file (`data/ai_challenge.zip`) to your VM using the `make transfer` command.

You need to provide your VM's IP address. You can do this in two ways:

**Option A: Pass IP as an argument**
```bash
make transfer VM_IP=123.45.67.89
```

**Option B: Edit the Makefile**
Open `Makefile` and set `VM_IP` to your VM's IP address. Then run:
```bash
make transfer
```

## 5. Download Data

To download the data, you can use the provided script `download_data.sh`. This script will ask for your agreement to the terms, your email, and the API key.
 
 ```bash
 ./download_data.sh
 ```
 
 You will be prompted for:
 1.  **Agreement**: Type `yes` to agree to the terms (use data only for hackathon, destroy afterwards).
 2.  **Email**: Your email address.
 3.  **API Key**: The key provided to you.
 4.  **Server IP**: The IP address of the server (press Enter for localhost).