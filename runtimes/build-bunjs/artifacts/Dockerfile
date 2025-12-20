# Dockerfile for building Bun from source
# Based on official Bun contributing documentation
# https://bun.sh/docs/project/contributing

FROM ubuntu:24.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    wget \
    lsb-release \
    software-properties-common \
    git \
    cmake \
    ninja-build \
    pkg-config \
    libtool \
    xz-utils \
    unzip \
    python3 \
    python3-pip \
    golang \
    ruby-full \
    ccache \
    gnupg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install GCC 11+ for C++20 support (required for 'span' header)
RUN apt-get update && apt-get install -y gcc-11 g++-11 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 100 && \
    rm -rf /var/lib/apt/lists/*

# Install LLVM 19 (MUST match WebKit version)
RUN wget https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh 19 all && \
    rm llvm.sh && \
    rm -rf /var/lib/apt/lists/*

# Add LLVM 19 to PATH
ENV PATH="/usr/lib/llvm-19/bin:${PATH}"
ENV CC=clang-19
ENV CXX=clang++-19

# Install Rust via rustup (needed for lolhtml and other Rust dependencies)
# The default Ubuntu rustc is too old for some Cargo.lock files
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Bun (required for bootstrapping - you can't build Bun without Bun)
RUN curl -fsSL https://bun.com/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

# Create work directory
WORKDIR /build

# Clone Bun repository with full history (needed for submodules and cargo lock files)
# Note: This is a large clone (~1GB+), but shallow clones break submodule dependencies
RUN git clone https://github.com/oven-sh/bun.git bun

WORKDIR /build/bun

# Initialize submodules - needed for dependencies like lolhtml
RUN git submodule update --init --recursive

# Setup environment
ENV BUN_INSTALL="/root/.bun"
ENV PATH="${BUN_INSTALL}/bin:${PATH}"

# Pre-install dependencies to avoid EEXIST errors during parallel build
RUN bun install --frozen-lockfile || bun install

# Build script
COPY build.sh /build/build.sh
RUN chmod +x /build/build.sh

# Default command - run the build
CMD ["/build/build.sh"]
