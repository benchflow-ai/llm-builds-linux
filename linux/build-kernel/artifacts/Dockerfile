# Dockerfile for Linux Kernel Build Environment
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && apt-get install -y \
    build-essential bc bison flex libelf-dev libssl-dev libncurses-dev \
    wget curl ca-certificates xz-utils zstd gzip bzip2 \
    kmod cpio rsync git qemu-system-x86 vim \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /kernel-build
CMD ["/bin/bash"]
