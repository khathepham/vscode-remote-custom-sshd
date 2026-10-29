#!/bin/bash

set -e

usage() {
    echo "Usage: $0 -u <remote_user> -h <remote_host> [-p <remote_port>]"
    echo
    echo "Required:"
    echo "  -u    Remote SSH user"
    echo "  -h    Remote SSH host"
    echo
    echo "Optional:"
    echo "  -p    Remote SSH port (default: 22)"
    exit 1
}

# Defaults
REMOTE_PORT=22

# Parse arguments
while getopts "u:h:p:" opt; do
    case $opt in
        u) REMOTE_USER="$OPTARG" ;;
        h) REMOTE_HOST="$OPTARG" ;;
        p) REMOTE_PORT="$OPTARG" ;;
        *) usage ;;
    esac
done

# Validate required arguments
if [ -z "$REMOTE_USER" ] || [ -z "$REMOTE_HOST" ]; then
    usage
fi

# 1. Automatically retrieve your local VS Code Commit ID
COMMIT_ID=$(code --version 2>/dev/null | sed -n '2p')

# Fallback check if 'code' command is not in your system PATH
if [ -z "$COMMIT_ID" ]; then
    echo "❌ Error: Could not determine VS Code commit ID automatically."
    echo "Please find it in VS Code via: Help -> About -> Commit"
    read -p "Enter Commit ID manually: " COMMIT_ID
fi

if [ -z "$COMMIT_ID" ]; then
    echo "❌ No commit ID provided. Exiting."
    exit 1
fi

echo "🚀 Target VS Code Commit ID: $COMMIT_ID"

# 2. Set up paths and download URL
ARCHIVE_NAME="vscode-server-linux-x64.tar.gz"
DOWNLOAD_URL="https://update.code.visualstudio.com/commit:${COMMIT_ID}/server-linux-x64/stable"
LOCAL_TMP_DIR="/tmp/vscode-server-$COMMIT_ID"
REMOTE_BIN_DIR="~/.vscode-server/bin/${COMMIT_ID}"

mkdir -p "$LOCAL_TMP_DIR"

# 3. Download the specific server binary if not already cached locally
if [ ! -f "$LOCAL_TMP_DIR/$ARCHIVE_NAME" ]; then
    echo "📥 Downloading VS Code Server archive..."
    curl -L "$DOWNLOAD_URL" -o "$LOCAL_TMP_DIR/$ARCHIVE_NAME"
else
    echo "📦 Found cached copy of the server archive locally."
fi

# 4. Create the target directory tree on the remote server
echo "📁 Creating remote directories..."
ssh -p "$REMOTE_PORT" "${REMOTE_USER}@${REMOTE_HOST}" \
    "mkdir -p ${REMOTE_BIN_DIR}"

# 5. SCP the archive over to the remote host
echo "📤 Transferring server archive to remote host via SCP..."
scp -P "$REMOTE_PORT" \
    "$LOCAL_TMP_DIR/$ARCHIVE_NAME" \
    "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BIN_DIR}/"

# 6. Extract the server payload and clean up the archive
echo "🔧 Extracting files on the remote server..."
ssh -p "$REMOTE_PORT" "${REMOTE_USER}@${REMOTE_HOST}" "
    cd ${REMOTE_BIN_DIR} && \
    tar -xzf ${ARCHIVE_NAME} --strip-components=1 && \
    rm ${ARCHIVE_NAME} && \
    touch ~/.vscode-server/vscode-cli-${COMMIT_ID}.tar.gz.done
"

echo "✅ Success! VS Code Server manually deployed to ${REMOTE_HOST}."
echo "You can now connect seamlessly using your standard Remote-SSH extension."