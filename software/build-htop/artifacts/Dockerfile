# Dockerfile for building htop from source
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git build-essential autoconf automake libtool pkg-config \
    libncursesw5-dev libncurses-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git clone https://github.com/htop-dev/htop.git

WORKDIR /build/htop
COPY build.sh /build/build.sh
RUN chmod +x /build/build.sh

CMD ["/build/build.sh"]
