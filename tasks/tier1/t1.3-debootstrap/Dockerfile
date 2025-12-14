# Build environment for T1.3: Debootstrap minimal rootfs
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    debootstrap \
    qemu-user-static \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN echo '#!/bin/bash\n\
echo "=== T1.3: Create Minimal Debian Rootfs ===" \n\
echo "" \n\
echo "Your task: Use debootstrap to create a minimal Debian system" \n\
echo "" \n\
echo "Basic command:" \n\
echo "  debootstrap --arch=amd64 bookworm /rootfs http://deb.debian.org/debian" \n\
echo "" \n\
echo "For smaller system:" \n\
echo "  debootstrap --variant=minbase ..." \n\
echo "" \n\
echo "To chroot:" \n\
echo "  mount -t proc /proc /rootfs/proc" \n\
echo "  mount -t sysfs /sys /rootfs/sys" \n\
echo "  mount --bind /dev /rootfs/dev" \n\
echo "  chroot /rootfs /bin/bash" \n\
' > /usr/local/bin/task-info && chmod +x /usr/local/bin/task-info

RUN echo 'task-info' >> /root/.bashrc

CMD ["/bin/bash"]
