#!/bin/sh

# Script Name: kernel_nfs_install.sh
# File Path: <git_root>/scripts/kernel_nfs_install.sh
# Description: Install kernel and modules on target system through nfs (REQUIRES ROOT PRIVILAGES).

# Copyright 2024 Ray Adams
# SPDX-Licence-Identifier: BSD-3-Clause

# Version: 2.1.0

# Default source path
src_path="/usr/local/src/"

# Default source path
system="$(hostname)"

# Colors
green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m'

# Check if the script was executed with root privilages
if [ "$(id -u)" -ne 0 ]; then
    echo "${red}Please run this shell script as root.${nc}"
    exit 1
fi

# Check if the source path exists for the current system
if [ -e "${src_path}/${system}" ]; then
    echo "${green}Installing kernel and modules for ${system}.${nc}"
    mount "${src_path}/${system}" || { echo "${red}Failed to mount nfs directory.${nc}"; exit 1; }
else
    echo "Kernel sources not found for ${system}"
    exit 1
fi

# Copy the unified kernel image to the boot partition
copy_uki_to_boot() {
    mount /boot
    cp "${src_path}/${system}/uki/vmlinuz-${local_version}.efi" "/boot/efi/boot/bootx64.efi" || { echo "${red}Error copying vmlinuz-${local_version}.efi to boot partition.${nc}"; exit 1; }
    umount /boot

    echo "${green}Copied ${local_version} to /boot/efi/boot/bootx64.efi successfully.${nc}"

    install_modules
}

# Install the kernel modules to /lib/modules
install_modules() {
    cp -r "${src_path}/${system}/modules/${local_version}" "/lib/modules/"|| { echo "${red}Error copying modules to /lib/modules/${local_version}/.${nc}"; exit 1; }
    echo "${green}Copied modules for ${local_version} to /lib/modules/ successfully.${nc}"
}

# Let user choose a kernel version to install
echo "${green}Available linux kernels:${nc}"
available_versions="$(ls "${src_path}/${system}/linux/")"
echo "${green}${available_versions}${nc}"
while true; do
    echo "${green}Please select a version:${nc}"
    read version
    if [ -d "${src_path}/${system}/linux/${version}" ]; then
        linux_src_path="${src_path}/${system}/linux/${version}/"
        break
    elif [ -d "${src_path}/${system}/linux/linux-${version}/" ]; then
        linux_src_path="${src_path}/${system}/linux/linux-${version}/"
        version="linux-${version}"
        break
    else
        echo "${red}Please choose a valid version.${nc}"
    fi
done

local_version="$(echo ${version} | sed 's/linux-//')-$(grep "^CONFIG_LOCALVERSION" "${linux_src_path}/.config" | sed 's/^CONFIG_LOCALVERSION="-//' | tr -d '"')"

# Copy UKI image to boot
copy_uki_to_boot

# Create new symlink
echo "${green}Creating new symlink to ${linux_src_path}.${nc}"
ln -s "${linux_src_path}" "/usr/src/linux"
