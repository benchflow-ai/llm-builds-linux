#!/bin/bash
set -ex

echo "=== Building htop from source ==="

cd /build/htop

echo "Running autogen.sh..."
./autogen.sh

echo "Running configure..."
./configure --prefix=/usr/local

echo "Running make..."
make -j$(nproc)

echo "Verifying binary..."
if [ -f ./htop ]; then
    echo "SUCCESS: htop binary created"
    ./htop --version
    if [ -d /output ]; then
        cp ./htop /output/
        echo "Binary copied to /output/htop"
    fi
else
    echo "ERROR: htop binary not found"
    exit 1
fi

echo "=== Build completed successfully! ==="
