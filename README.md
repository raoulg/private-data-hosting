# SURF Data Server Setup

1. Preparation on the VM
SSH into your SURF/Ubuntu VM and create the project folders:

mkdir -p ~/my-server/data
cd ~/my-server

2. Generating a Secure API Key

Run:
openssl rand -hex 32

3. Transferring Data (SCP)
Run scp <source_file> <remote_user>@<remote_ip>:<destination_path>

scp /path/to/your/local/dataset.zip ubuntu@<YOUR_VM_IP>:~/my-server/data/

then:
curl -H "x-api-key: <API_KEY>" -O http://<VM_IP>:8000/download