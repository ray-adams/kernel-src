#!/bin/sh

# create_backup_kernel.sh - Copy current kernel to backup. (REQUIRES ROOT PRIVILAGES).

# Copyright 2024 Ray Adams
# SPDX-Licence-Identifier: BSD-3-Clause

# Version: 1.0.0

# Check if the script was executed with root privilages.
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this shell script as root."
    exit 1
fi

# Copy current kernel to backup location.
mount /boot
cp "/boot/efi/boot/bootx64.efi" "/boot/efi/boot/backup.efi" || { echo "Error copying current kernel to backup.efi"; exit 1; }
umount /boot

echo "Copied $(uname -r) to /boot/efi/boot/backup.efi."
