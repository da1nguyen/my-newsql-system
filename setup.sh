#!/usr/bin/env bash

set -euo pipefail

echo "======================================"
echo " NewSQL Web Lab - SETUP"
echo "======================================"

CRDB_VERSION="v26.2.5"
INSTALL_ROOT="$HOME/.local/cockroach"

# ----------------------------------------------------------
# 1. Install Python packages
# ----------------------------------------------------------

echo
echo "[1/3] Installing Python packages..."

python -m pip install --upgrade pip
python -m pip install -r requirements.txt


# ----------------------------------------------------------
# 2. Detect CPU architecture
# ----------------------------------------------------------

echo
echo "[2/3] Detecting system architecture..."

ARCH="$(uname -m)"

case "$ARCH" in

    x86_64)
        CRDB_ARCH="amd64"
        ;;

    aarch64|arm64)
        CRDB_ARCH="arm64"
        ;;

    *)
        echo "ERROR: Unsupported architecture: $ARCH"
        exit 1
        ;;

esac

echo "Architecture: $CRDB_ARCH"


# ----------------------------------------------------------
# 3. Download CockroachDB
# ----------------------------------------------------------

echo
echo "[3/3] Installing CockroachDB ${CRDB_VERSION}..."

PACKAGE="cockroach-${CRDB_VERSION}.linux-${CRDB_ARCH}"

COCKROACH_DIR="${INSTALL_ROOT}/${PACKAGE}"

COCKROACH_BIN="${COCKROACH_DIR}/cockroach"

DOWNLOAD_URL="https://binaries.cockroachdb.com/${PACKAGE}.tgz"


mkdir -p "$INSTALL_ROOT"


if [ -x "$COCKROACH_BIN" ]; then

    echo "CockroachDB is already installed."

else

    echo "Downloading:"
    echo "$DOWNLOAD_URL"

    curl -fL \
        "$DOWNLOAD_URL" \
        -o /tmp/cockroach.tgz

    tar -xzf \
        /tmp/cockroach.tgz \
        -C "$INSTALL_ROOT"

    rm -f /tmp/cockroach.tgz

fi


echo
echo "======================================"
echo " CockroachDB Version"
echo "======================================"

"$COCKROACH_BIN" version


echo
echo "======================================"
echo " SETUP COMPLETED SUCCESSFULLY"
echo "======================================"

echo
echo "Next command:"
echo
echo "bash start.sh"
echo