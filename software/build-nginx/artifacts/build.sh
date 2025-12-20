#!/bin/bash
set -e

NGINX_VERSION="1.25.3"
echo "=== Building Nginx $NGINX_VERSION with custom modules ==="

cd /build

echo "[1/6] Downloading Nginx..."
wget -q https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
tar -xzf nginx-${NGINX_VERSION}.tar.gz

echo "[2/6] Cloning headers-more-nginx-module..."
git clone --depth 1 https://github.com/openresty/headers-more-nginx-module.git

echo "[3/6] Cloning nginx-rtmp-module..."
git clone --depth 1 https://github.com/arut/nginx-rtmp-module.git

echo "[4/6] Configuring Nginx..."
cd nginx-${NGINX_VERSION}
./configure \
    --prefix=/usr/local/nginx \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_stub_status_module \
    --with-http_v2_module \
    --with-stream \
    --with-stream_ssl_module \
    --add-module=/build/headers-more-nginx-module \
    --add-module=/build/nginx-rtmp-module

echo "[5/6] Compiling Nginx..."
make -j$(nproc)
make install

echo "[6/6] Copying to output..."
cp -r /usr/local/nginx/* /output/

echo "=== Build Complete ==="
/output/sbin/nginx -V
ls -lh /output/sbin/
