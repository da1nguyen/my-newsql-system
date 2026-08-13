#!/usr/bin/env bash

set -e

CRDB_VERSION="v26.2.5"

ARCH="$(uname -m)"

case "$ARCH" in

    x86_64)
        CRDB_ARCH="amd64"
        ;;

    aarch64|arm64)
        CRDB_ARCH="arm64"
        ;;

esac


COCKROACH="$HOME/.local/cockroach/cockroach-${CRDB_VERSION}.linux-${CRDB_ARCH}/cockroach"

DATA_DIR="$HOME/cockroach-data"


echo "======================================"
echo " Starting CockroachDB"
echo "======================================"


if ! pgrep -f "cockroach start-single-node" > /dev/null
then

    "$COCKROACH" start-single-node \
        --insecure \
        --listen-addr=127.0.0.1:26257 \
        --http-addr=0.0.0.0:8080 \
        --store="$DATA_DIR" \
        --background

fi


echo "CockroachDB running."


echo "======================================"
echo " Starting Streamlit"
echo "======================================"


python -m streamlit run app.py \
    --server.address=0.0.0.0 \
    --server.port=8501