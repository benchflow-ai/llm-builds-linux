FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git vim make gcc libncurses-dev flex bison bc cpio \
    libelf-dev libssl-dev syslinux isolinux dosfstools \
    xorriso mtools grub-pc-bin grub-efi-amd64-bin bzip2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY build.sh /build/
RUN chmod +x /build/build.sh

CMD ["/build/build.sh"]
