# Private Data Hosting

A simple, secure, and user-friendly solution for hosting and sharing private datasets.

## Features
-   **Web GUI**: Browse, upload, and download files directly from your browser.
-   **Secure**: API Key authentication and Terms of Service agreement logging.
-   **Bulk Operations**: Upload multiple files and download selected files as a zip archive.
-   **CLI Support**: Scripts for automated or command-line based workflows.

## 1. [VM ADMIN] Server Setup

This section is for the administrator setting up the server.

### 1.1 Installation
1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/raoulg/private-data-hosting.git
    cd private-data-hosting
    ```
2.  **Install Docker**:
    ```bash
    curl -sSL https://raw.githubusercontent.com/raoulg/serverinstall/refs/heads/master/install-docker.sh | bash
    ```

### 1.2 Configuration & Start
1.  **Run Setup**:
    ```bash
    make setup-server
    ```
    ```bash
    make setup-server
    ```
    This generates an `.env` file with a secure `API_KEY` and detects the server IP.

    share the API_KEY with anyone you want to give access to the server.
    use `cat .env` to see the API_KEY

2.  **Configure Uploads (Optional)**:
    By default, file uploads via the Web GUI are **disabled**. To enable them:
    -   Open `.env` with `nano .env` or `vim .env`
    -   Set `ALLOW_UPLOAD=true`. (with vim you need to type `i` to enter insert mode and type.
    -   Save and exit the editor: with nano press `Ctrl+X`, then `Y` to confirm, then `Enter` to save. With vim press `Esc`, then `:wq` to save and quit.

3.  **Start the Server**:
    ```bash
    make up
    ```
    The server is now running on port 80.

## 2. How to Use (Web GUI)

Once the server is running, anyone with the **API Key** can access the data.

1.  **Access**: Open your browser and go to `http://<SERVER_IP>` (or `http://localhost` if running locally).
2.  **Login**: Enter your Email and the API Key.
3.  **Browse & Download**: View available files and download them individually or select multiple to download as a zip.
4.  **Upload** (if enabled): Switch to the "Upload Files" tab to upload data to the server.

## 3. Advanced / CLI Usage

For users who prefer the command line or need to automate transfers, see [docs/CLI_USAGE.md](docs/CLI_USAGE.md).
