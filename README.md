# SURF Data Server Setup

### 1. [VM ADMIN] Server Setup
This section is for the person setting up the VM.

### 1.1 Preparation
SSH into the VM you want to use for private data hosting.

**Multi-uploader Setup (Optional)**:
If multiple users need to transfer files to the server, you can set up a shared directory with group permissions. See [GROUP_SETUP.md](GROUP_SETUP.md) for detailed instructions.

### 1.2 Installation
1.  **Clone the Repository**:
    Go to the directory you want to use (e.g., `~` or `/srv/shared`).
    ```bash
    git clone https://github.com/raoulg/private-data-hosting.git
    cd private-data-hosting
    ```
2.  **Install Docker**:
    ```bash
    curl -sSL https://raw.githubusercontent.com/raoulg/serverinstall/refs/heads/master/install-docker.sh | bash
    ```

### 1.3 Configuration & Start
1.  **Run Setup**:
    ```bash
    make setup-server
    ```
    This generates an `.env` file with a secure `API_KEY`.
2.  **Start the Server**:
    ```bash
    make up
    ```
    The server is now running on port 80.

## 2. [UPLOADER] Sending Data
This section is for anyone who needs to upload files to the server.

> **Windows Users**: If you don't have `make`, see [WINDOWS_UPLOADER.md](WINDOWS_UPLOADER.md).

1.  **Local Setup**:
    ```bash
    make setup-uploader
    ```
    Enter the Server IP and your remote username when prompted.
2.  **Prepare Data**:
    - Place files in `data/send` (or modify your `PRIVATE_SEND_DIR` and `PRIVATE_TRANSFERRED_DIR` in `.env`)
    - Run `make zip` (follow prompts).
3.  **Transfer Data**:
    ```bash
    make transfer
    ```
    This uploads the zip and moves source files to `data/transferred`.

## 3. [DOWNLOADER] Getting Data
This section is for students/users downloading data.

### Interactive Download (Recommended)
1.  **Configure `.env`** (optional):
    Copy `.env.sample` to `.env` and fill in `PRIVATE_DOWNLOAD_API_KEY`, `PRIVATE_DOWNLOAD_IP`, etc.
2.  **Run the Script**:
    ```bash
    ./download_data.sh
    ```
    Select the file you want to download.

### Manual Download
```bash
curl -o my_data.zip "http://<PRIVATE_DOWNLOAD_IP>/download?api_key=<API_KEY>&user_email=<EMAIL>&filename=<FILENAME>"
```
