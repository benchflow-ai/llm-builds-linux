#!/bin/bash
# GRUB bootloader configuration script
# BROKEN: Multiple issues in bootloader setup

set -e

# BROKEN: Wrong grub installation device
GRUB_DEVICE="/dev/sdc"

# BROKEN: Missing grub-mkconfig command
# This script should generate /boot/grub/grub.cfg

# Install GRUB to MBR - BROKEN: typo in command
grub-instal --target=i386-pc --boot-directory=/boot $GRUB_DEVICE

# BROKEN: Missing GRUB environment block creation
# grub-editenv /boot/grub/grubenv create

# BROKEN: No default kernel parameters set
# Should include: root=UUID=xxx ro quiet

echo "GRUB installation complete"
