#!/bin/bash

# Default output directory
OUTPUT_DIR="."

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -o|--output) OUTPUT_DIR="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Terms of Service
echo "=================================================================="
echo "SURF Data Download - Terms of Service"
echo "=================================================================="
echo "By downloading this dataset, you agree to the following:"
echo "1. You will use this data ONLY for the purpose of the hackathon."
echo "2. You promise to DESTROY the data at the end of the hackathon."
echo "=================================================================="
echo ""

# Ask for agreement
read -p "Do you agree to these terms? (yes/no): " agreement < /dev/tty

if [[ "$agreement" != "yes" ]]; then
    echo "You must agree to the terms to download the data. Exiting."
    exit 1
fi

# Ask for user email
read -p "Enter your email address: " user_email < /dev/tty

if [[ -z "$user_email" ]]; then
    echo "Email address is required. Exiting."
    exit 1
fi

# Ask for API Key
read -p "Enter the API Key: " api_key < /dev/tty

if [[ -z "$api_key" ]]; then
    echo "API Key is required. Exiting."
    exit 1
fi

# Define the server URL (assuming localhost for now, but should be configurable or passed as arg?)
# The user request implies this is for students, so they will likely run this against a remote IP.
# However, the previous context showed the user testing with localhost.
# To make it robust, let's ask for the IP or default to localhost if not provided?
# Or better, let's assume the user will edit the script or pass it?
# Actually, the user said "students should accept the 'voorwaarden'... then curls".
# The curl command in the README has <VM_IP>.
# Let's ask for the IP address as well, to make it fully interactive.

read -p "Enter the Server IP (press Enter for localhost): " server_ip < /dev/tty
server_ip=${server_ip:-127.0.0.1}

echo ""
echo "Downloading data to $OUTPUT_DIR..."

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Change to output directory
cd "$OUTPUT_DIR" || exit

# Run curl
# -J: Use the header-provided filename
# -O: Write output to a file named as the remote file
# -f: Fail silently (no output at all) on server errors
# -w: Write the effective filename to stdout so we can capture it
filename=$(curl -J -O -w "%{filename_effective}" -f -H "x-api-key: $api_key" "http://$server_ip/download?user_email=$user_email")
curl_exit_code=$?

if [[ $curl_exit_code -eq 0 ]]; then
    echo "Download complete! Saved to $filename"
    
    # Check if file is a zip and unzip it
    if [[ "$filename" == *.zip ]]; then
        echo "Unzipping $filename..."
        if command -v unzip &> /dev/null; then
            unzip -o "$filename"
            echo "Unzip complete."
        else
            echo "Warning: 'unzip' command not found. Please unzip '$filename' manually."
        fi
    fi
else
    echo "Download failed. Please check your API Key, Server IP, and try again."
fi
