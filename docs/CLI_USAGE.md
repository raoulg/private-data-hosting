# CLI Usage Guide

This guide covers the command-line interface (CLI) methods for uploading and downloading data. These are alternative methods to the Web GUI.

## 1. [UPLOADER] Sending Data via CLI

1.  **Local Setup**:
    ```bash
    make setup-uploader
    ```
    Enter the Server IP and your remote username when prompted.

2.  **Prepare Data**:
    - Place files in `data/send` (or modify your `PRIVATE_SEND_DIR` and `PRIVATE_TRANSFERRED_DIR` in `.env`).
    - Run `make zip` (follow prompts).

3.  **Transfer Data**:
    ```bash
    make transfer
    ```
    This uploads the zip and moves source files to `data/transferred`.

## 2. [DOWNLOADER] Getting Data via CLI

### Interactive Download Script
1.  **Configure `.env`** (optional):
    Copy `.env.sample` to `.env` and fill in `PRIVATE_DOWNLOAD_API_KEY`, `PRIVATE_DOWNLOAD_IP`, etc.
2.  **Run the Script**:
    ```bash
    ./download_data.sh
    ```
    Follow the prompts to select and download files.

### Manual Download via Curl
You can download files directly using `curl`:

```bash
curl -o my_data.zip "http://<SERVER_IP>/download?api_key=<API_KEY>&user_email=<EMAIL>&filename=<FILENAME>"
```
