#!/bin/sh

# Script Name: create_backup_kernel.sh
# File Path: <git_root>/scripts/create_backup_kernel.sh
# Description: Copy current kernel to the backup location specfied via efibootmgr (REQUIRES ROOT PRIVILAGES).

# Copyright 2024 Ray Adams
# SPDX-Licence-Identifier: BSD-3-Clause

# Version: 1.2.1

# Colors
green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m'

# Check if the script was executed with root privilages.
if [ "$(id -u)" -ne 0 ]; then
    echo "${green}Please run this shell script as root.${nc}"
    exit 1
fi

# Copy current kernel to backup location.
mount /boot
cp "/boot/efi/boot/bootx64.efi" "/boot/efi/boot/backup.efi" || { echo "${red}Error copying current kernel to backup.efi.${nc}"; exit 1; }
umount /boot

echo "${green}Copied $(uname -r) to /boot/efi/boot/backup.efi.${nc}"
