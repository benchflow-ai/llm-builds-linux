# LFS Build Environment
# Based on Debian trixie (testing) for glibc 2.40 compatibility with GCC 15.x
# Use --platform to ensure correct architecture
FROM --platform=linux/arm64 debian:trixie

ENV DEBIAN_FRONTEND=noninteractive
ENV LFS=/mnt/lfs
ENV LC_ALL=POSIX
# LFS_TGT is set dynamically based on architecture
ENV LFS_TGT=aarch64-lfs-linux-gnu
ENV PATH=/mnt/lfs/tools/bin:$PATH
ENV CONFIG_SITE=/mnt/lfs/usr/share/config.site

# Install host system requirements for LFS 12.4
RUN apt-get update && apt-get install -y \
    # Core build tools
    build-essential \
    gcc \
    g++ \
    make \
    # Required utilities
    bash \
    binutils \
    bison \
    coreutils \
    diffutils \
    findutils \
    gawk \
    grep \
    gzip \
    m4 \
    patch \
    perl \
    python3 \
    sed \
    tar \
    texinfo \
    xz-utils \
    # Additional requirements
    wget \
    curl \
    file \
    git \
    bc \
    bzip2 \
    # For kernel building
    libelf-dev \
    libssl-dev \
    flex \
    # For symlink management
    symlinks \
    && rm -rf /var/lib/apt/lists/*

# Create required symlinks for LFS compatibility
RUN ln -sf /bin/bash /bin/sh && \
    ln -sf /usr/bin/gawk /usr/bin/awk && \
    ln -sf /usr/bin/bison /usr/bin/yacc

# Create LFS partition mount point
RUN mkdir -pv $LFS && \
    mkdir -pv $LFS/sources && \
    chmod -v a+wt $LFS/sources

# Create LFS tools directory
RUN mkdir -pv $LFS/tools && \
    ln -sv $LFS/tools /

# Create lfs user (will own the build)
RUN groupadd lfs && \
    useradd -s /bin/bash -g lfs -m -k /dev/null lfs && \
    chown -v lfs $LFS/{sources,tools}

# Version check script
COPY version-check.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/version-check.sh

WORKDIR /mnt/lfs

CMD ["/bin/bash"]
