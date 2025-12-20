# Yocto/Poky Build Environment
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8

RUN apt-get update && apt-get install -y \
    build-essential chrpath cpio diffstat gawk git python3 python3-pip \
    python3-pexpect python3-git python3-jinja2 python3-subunit \
    locales texinfo wget zstd lz4 xz-utils debianutils iputils-ping \
    libegl1-mesa libsdl1.2-dev pylint xterm git-lfs python3-setuptools \
    file gcc-multilib g++-multilib \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8 && update-locale

# Yocto requires non-root user
RUN useradd -m -s /bin/bash yoctouser && \
    echo "yoctouser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/yoctouser/yocto
USER yoctouser

RUN git config --global user.email "builder@yocto.local" && \
    git config --global user.name "Yocto Builder" && \
    git config --global color.ui false

CMD ["/bin/bash"]
