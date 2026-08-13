#!/usr/bin/env bash

set -euo pipefail

echo "======================================"
echo " NewSQL Web Lab - START"
echo "======================================"

CRDB_VERSION="v26.2.5"

INSTALL_ROOT="$HOME/.local/cockroach"

DATA_DIR="$HOME/cockroach-data"


# ----------------------------------------------------------
# 1. Detect architecture
# ----------------------------------------------------------

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


PACKAGE="cockroach-${CRDB_VERSION}.linux-${CRDB_ARCH}"

COCKROACH_BIN="${INSTALL_ROOT}/${PACKAGE}/cockroach"


# ----------------------------------------------------------
# 2. Check CockroachDB installation
# ----------------------------------------------------------

if [ ! -x "$COCKROACH_BIN" ]; then

    echo
    echo "ERROR: CockroachDB is not installed."
    echo
    echo "Run this first:"
    echo
    echo "bash setup.sh"
    echo

    exit 1

fi


# ----------------------------------------------------------
# 3. Start CockroachDB
# ----------------------------------------------------------

echo
echo "[1/3] Checking CockroachDB..."

if "$COCKROACH_BIN" sql \
    --insecure \
    --host=127.0.0.1:26257 \
    -e "SELECT 1;" \
    >/dev/null 2>&1
then

    echo "CockroachDB is already running."

else

    echo "Starting CockroachDB..."

    mkdir -p "$DATA_DIR"

    "$COCKROACH_BIN" start-single-node \
        --insecure \
        --listen-addr=127.0.0.1:26257 \
        --http-addr=0.0.0.0:8080 \
        --store="$DATA_DIR" \
        --background

fi


# ----------------------------------------------------------
# 4. Wait until database is ready
# ----------------------------------------------------------

echo
echo "[2/3] Waiting for CockroachDB..."

DB_READY=0

for i in {1..30}
do

    if "$COCKROACH_BIN" sql \
        --insecure \
        --host=127.0.0.1:26257 \
        -e "SELECT 1;" \
        >/dev/null 2>&1
    then

        DB_READY=1
        break

    fi

    sleep 1

done


if [ "$DB_READY" -ne 1 ]; then

    echo
    echo "ERROR: CockroachDB did not start correctly."
    exit 1

fi


echo "CockroachDB is READY."

echo
echo "SQL address:"
echo "127.0.0.1:26257"

echo
echo "CockroachDB Console:"
echo "Port 8080"


# ----------------------------------------------------------
# 5. Start Streamlit
# ----------------------------------------------------------

echo
echo "[3/3] Starting Streamlit..."

echo
echo "Streamlit App:"
echo "Port 8501"

echo
echo "======================================"
echo " SYSTEM READY"
echo "======================================"
echo

python -m streamlit run app.py \
    --server.address=0.0.0.0 \
    --server.port=8501