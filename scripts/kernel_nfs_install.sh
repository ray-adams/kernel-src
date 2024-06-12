#!/bin/sh

# kernel_nfs_install.sh - Install kernel and modules on target system through nfs (REQUIRES ROOT PRIVILAGES).

# Copyright 2024 Ray Adams
# SPDX-Licence-Identifier: BSD-3-Clause

# Version: 1.1.3

src_path="/usr/local/src/"
system="$(hostname)"

# Check if the script was executed with root privilages.
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this shell script as root."
    exit 1
fi

# Check if the source path exists for the current system.
if [ -e "${src_path}/${system}" ]; then
    echo "Installing kernel and modules for ${system}..."
    mount "${src_path}/${system}" || { echo "Failed to mount nfs directory."; exit 1; }
else
    echo "Kernel sources not found for ${system}"
    exit 1
fi

# Copy the unified kernel image to the boot partition.
copy_uki_to_boot() {
    mount /boot
    cp "${src_path}/${system}/uki/vmlinuz-${local_version}.efi" "/boot/efi/boot/bootx64.efi" || { echo "Error copying vmlinuz-${local_version}.efi to boot partition."; exit 1; }
    umount /boot

    echo "Copied ${local_version} to /boot/efi/boot/bootx64.efi."

    install_modules
}

# Install the kernel modules to /lib/modules.
install_modules() {
    make modules_install || { echo "Error installing modules to /lib/modules/${local_version}/."; exit 1; }
}

# Let user choose a kernel version to install.
echo "Available linux kernels:"
ls "${src_path}/${system}/linux/"
while true; do
    echo "Please select a version:"
    read version
    if [ -d "${src_path}/${system}/linux/${version}" ]; then
        linux_src_path="${src_path}/${system}/linux/${version}/"
        break
    elif [ -d "${src_path}/${system}/linux/linux-${version}/" ]; then
        linux_src_path="${src_path}/${system}/linux/linux-${version}/"
        break
    else
        echo "Please choose a valid version."
    fi
done

local_version="$(echo ${version} | sed 's/linux-//')-$(grep "^CONFIG_LOCALVERSION" "${linux_src_path}/.config" | sed 's/^CONFIG_LOCALVERSION="-//' | tr -d '"')"

# Make sure we are in the correct directory before copying the uki.
cd "${linux_src_path}" && copy_uki_to_boot

# Create new symlink.
ln -s "${linux_src_path}" "/usr/src/linux"
