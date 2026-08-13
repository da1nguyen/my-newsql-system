#!/usr/bin/env bash

set -e

echo "======================================"
echo " Installing Python packages"
echo "======================================"

python -m pip install --upgrade pip
python -m pip install -r requirements.txt


echo "======================================"
echo " Installing CockroachDB"
echo "======================================"

CRDB_VERSION="v26.2.5"

ARCH="$(uname -m)"

case "$ARCH" in

    x86_64)
        CRDB_ARCH="amd64"
        ;;

    aarch64|arm64)
        CRDB_ARCH="arm64"
        ;;

    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;

esac


PACKAGE="cockroach-${CRDB_VERSION}.linux-${CRDB_ARCH}"

INSTALL_DIR="$HOME/.local/cockroach"

mkdir -p "$INSTALL_DIR"


if [ ! -f "$INSTALL_DIR/$PACKAGE/cockroach" ]; then

    curl -fsSL \
      "https://binaries.cockroachdb.com/${PACKAGE}.tgz" \
      -o /tmp/cockroach.tgz

    tar -xzf \
      /tmp/cockroach.tgz \
      -C "$INSTALL_DIR"

fi


"$INSTALL_DIR/$PACKAGE/cockroach" version

echo
echo "CockroachDB installed successfully."