# Nginx Build Environment with Custom Modules
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev \
    libssl-dev libgd-dev libgeoip-dev libxml2 libxml2-dev libxslt1-dev \
    wget git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY build.sh /build/build.sh
RUN chmod +x /build/build.sh

RUN mkdir -p /output
CMD ["/build/build.sh"]
