#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Load .env file if it exists
if [[ -f .env ]]; then
    export $(grep -v '^#' .env | xargs)
fi

# Check for Python
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo -e "${RED}Python is required to run this script but was not found.${NC}"
    echo "We recommend installing 'uv' to manage Python easily:"
    echo -e "${CYAN}curl -LsSf https://astral.sh/uv/install.sh | sh${NC}"
    echo "After installing uv, you can install python with: uv python install"
    exit 1
fi

# Header
print_header() {
    clear
    echo -e "${CYAN}"
    echo "  ____  _       _          _    _           _   _             "
    echo " |  _ \(_)     | |        | |  | |         | | (_)            "
    echo " | |_) |_  __ _| |  ______| |__| | ___  ___| |_ _ _ __   __ _ "
    echo " |  _ <| |/ _\` | | |______|  __  |/ _ \/ __| __| | '_ \ / _\` |"
    echo " | |_) | | (_| | |        | |  | | (_) \__ \ |_| | | | | (_| |"
    echo " |____/|_|\__, |_|        |_|  |_|\___/|___/\__|_|_| |_|\__, |"
    echo "           __/ |                                         __/ |"
    echo "          |___/                                         |___/ "
    echo -e "${NC}"
    echo -e "${BLUE}Welcome to the Private Data Hosting Downloader${NC}"
    echo "=================================================================="
}

print_header

# --- Phase 1: Terms of Service ---
TOS_FILE=".agreed_to_tos"

if [[ ! -f "$TOS_FILE" ]]; then
    echo -e "${YELLOW}Phase 1: Terms of Service${NC}"
    echo "=================================================================="
    echo "By downloading this dataset, you agree to the following:"
    echo "1. You will use this data ONLY for the purpose of the hackathon."
    echo "2. You promise to DESTROY the data at the end of the hackathon."
    echo "=================================================================="
    echo ""
    
    while true; do
        read -p "Do you agree to these terms? (yes/no): " agreement < /dev/tty
        if [[ "$agreement" == "yes" ]]; then
            break
        elif [[ "$agreement" == "no" ]]; then
            echo -e "${RED}You must agree to the terms to download the data. Exiting.${NC}"
            exit 1
        else
            echo "Please answer 'yes' or 'no'."
        fi
    done
else
    echo -e "${GREEN}Terms of Service already accepted.${NC}"
fi

# --- Phase 2: Credentials ---
echo ""
echo -e "${YELLOW}Phase 2: Credentials${NC}"

# Email
if [[ -n "$PRIVATE_DOWNLOAD_EMAIL" ]]; then
    USER_EMAIL="$PRIVATE_DOWNLOAD_EMAIL"
    echo -e "Email loaded from .env: ${GREEN}$USER_EMAIL${NC}"
else
    read -p "Enter your email address: " USER_EMAIL < /dev/tty
    while [[ -z "$USER_EMAIL" ]]; do
        echo -e "${RED}Email address is required.${NC}"
        read -p "Enter your email address: " USER_EMAIL < /dev/tty
    done
fi

# API Key
if [[ -n "$PRIVATE_DOWNLOAD_API_KEY" ]]; then
    API_KEY="$PRIVATE_DOWNLOAD_API_KEY"
    echo -e "API Key loaded from .env: ${GREEN}******${NC}"
else
    read -p "Enter the API Key: " API_KEY < /dev/tty
    while [[ -z "$API_KEY" ]]; do
        echo -e "${RED}API Key is required.${NC}"
        read -p "Enter the API Key: " API_KEY < /dev/tty
    done
fi

# Server IP
if [[ -n "$PRIVATE_DOWNLOAD_IP" ]]; then
    SERVER_IP="$PRIVATE_DOWNLOAD_IP"
    echo -e "Server IP loaded from .env: ${GREEN}$SERVER_IP${NC}"
else
    read -p "Enter the Server IP (press Enter for localhost): " SERVER_IP < /dev/tty
    SERVER_IP=${SERVER_IP:-127.0.0.1}
fi

# Save TOS agreement if not already saved
if [[ ! -f "$TOS_FILE" ]]; then
    echo "Agreed to TOS on $(date) by $USER_EMAIL" > "$TOS_FILE"
    echo "TOS agreement saved to $TOS_FILE"
fi

# --- Phase 3: File Selection ---
echo ""
echo -e "${YELLOW}Phase 3: File Selection${NC}"
echo "Fetching file list from server..."

# Fetch file list
RESPONSE=$(curl -s -f -H "x-api-key: $API_KEY" "http://$SERVER_IP/list_files")
CURL_EXIT_CODE=$?

if [[ $CURL_EXIT_CODE -ne 0 ]]; then
    echo -e "${RED}Failed to fetch file list. Please check your API Key and Server IP.${NC}"
    exit 1
fi

# Parse JSON using Python (standard on most systems)
# We expect {"files": [{"name": "file1", "size": 123}, ...]}
FILES_JSON=$(echo "$RESPONSE" | $PYTHON_CMD -c "import sys, json; print(json.dumps(json.load(sys.stdin)['files']))" 2>/dev/null)

if [[ -z "$FILES_JSON" || "$FILES_JSON" == "[]" ]]; then
    echo -e "${RED}No files found or invalid response from server.${NC}"
    echo "Response: $RESPONSE"
    exit 1
fi

# Display files
echo "Available files:"
i=1
declare -a FILE_NAMES
declare -a FILE_SIZES

# Read files into arrays using a loop
while IFS= read -r line; do
    name=$(echo "$line" | $PYTHON_CMD -c "import sys, json; print(json.load(sys.stdin)['name'])")
    size=$(echo "$line" | $PYTHON_CMD -c "import sys, json; print(json.load(sys.stdin)['size'])")
    
    # Format size
    if (( size > 1024 * 1024 )); then
        size_str="$(echo "scale=2; $size/1024/1024" | bc) MB"
    elif (( size > 1024 )); then
        size_str="$(echo "scale=2; $size/1024" | bc) KB"
    else
        size_str="$size B"
    fi
    
    echo -e "  [$i] ${CYAN}$name${NC} ($size_str)"
    FILE_NAMES[$i]="$name"
    ((i++))
done < <(echo "$FILES_JSON" | $PYTHON_CMD -c "import sys, json; [print(json.dumps(x)) for x in json.load(sys.stdin)]")

TOTAL_FILES=$((i-1))

echo ""
echo -e "Enter the numbers of the files you want to download (separated by space),"
echo -e "or type '${GREEN}all${NC}' to download all files."
read -p "Selection: " SELECTION < /dev/tty

SELECTED_INDICES=()

if [[ "$SELECTION" == "all" ]]; then
    for ((j=1; j<=TOTAL_FILES; j++)); do
        SELECTED_INDICES+=($j)
    done
else
    for idx in $SELECTION; do
        if [[ "$idx" =~ ^[0-9]+$ ]] && (( idx >= 1 && idx <= TOTAL_FILES )); then
            SELECTED_INDICES+=($idx)
        else
            echo -e "${RED}Invalid selection: $idx${NC}"
        fi
    done
fi

if [[ ${#SELECTED_INDICES[@]} -eq 0 ]]; then
    echo -e "${RED}No valid files selected. Exiting.${NC}"
    exit 1
fi

# --- Phase 4: Download ---
echo ""
echo -e "${YELLOW}Phase 4: Download${NC}"
echo "Downloading to $OUTPUT_DIR..."

# Create output directory
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR" || exit

for idx in "${SELECTED_INDICES[@]}"; do
    FILENAME="${FILE_NAMES[$idx]}"
    echo -e "Downloading ${CYAN}$FILENAME${NC}..."
    
    curl -J -O -f -H "x-api-key: $API_KEY" "http://$SERVER_IP/download?user_email=$USER_EMAIL&filename=$FILENAME"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Successfully downloaded $FILENAME${NC}"
        
        # Unzip if needed
        if [[ "$FILENAME" == *.zip ]]; then
            echo "Unzipping $FILENAME..."
            if command -v unzip &> /dev/null; then
                unzip -o "$FILENAME"
                echo "Unzip complete."
            else
                echo -e "${YELLOW}Warning: 'unzip' command not found. Please unzip manually.${NC}"
            fi
        fi
    else
        echo -e "${RED}Failed to download $FILENAME${NC}"
    fi
done

echo ""
echo -e "${GREEN}All operations complete!${NC}"
