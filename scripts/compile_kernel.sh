#!/bin/sh

# Script Name: compile_kernel.sh
# File Path: <git_root>/scripts/compile_kernel.sh
# Description: Compile kernel images based on user selected version (REQUIRES ROOT PRIVILAGES).

# Copyright 2024 Ray Adams
# SPDX-Licence-Identifier: BSD-3-Clause

# Version: 2.4.1

# Default source path
src_path="/usr/local/src/"

# Colors
green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m'

# Check if the script was executed with root privilages.
if [ "$(id -u)" -ne 0 ]; then
    echo "${red}Please run this shell script as root.${nc}"
    exit 1
fi

# Choose available kernel version for system.
select_version() {
    if [ ! -e "${src_path}/${system}/" ]; then
        echo "${red}The directory ${src_path}/${system} does not exist.${nc}"
        exit 1
    fi

    echo "${green}Available linux kernels:${nc}"
    available_versions="$(ls "${src_path}/${system}/linux/")"
    echo "${green}${available_versions}${nc}"
    while true; do
        echo "${green}Select a version:${nc}"
        read version
        if [ -d "${src_path}/${system}/linux/${version}" ]; then
            linux_src_path="${src_path}/${system}/linux/${version}/"
            break
        elif [ -d "${src_path}/${system}/linux/linux-${version}/" ]; then
            linux_src_path="${src_path}/${system}/linux/linux-${version}/"
            break
        else
            echo "${red}Please choose a valid version.${nc}"
        fi
    done

    local_version="$(echo ${version} | sed 's/linux-//')-$(grep "^CONFIG_LOCALVERSION" "${linux_src_path}/.config" | sed 's/^CONFIG_LOCALVERSION="-//' | tr -d '"')"

    cd ${linux_src_path}
}

# Compile the kernel without an initramfs.
compile_kernel() {
    make -j6 || { echo "${red}Error compiling kernel ${local_version}.${nc}"; exit 1; }

    cp "${linux_src_path}/arch/x86/boot/bzImage" "${src_path}/${system}/vmlinuz/vmlinuz-${local_version}.efi" || { echo "${red}Error copying vmlinuz-${local_version}.efi to source directory.${nc}"; exit 1; }

    echo "${green}Finished creating ${local_version} kernel image.${nc}"
}

# Copy the unified kernel image to the boot partition.
copy_to_boot() {
    mount /boot
    cp "${src_path}/${system}/uki/vmlinuz-${local_version}.efi" "/boot/efi/boot/bootx64.efi" || { echo "${red}Error copying vmlinuz-${local_version}.efi to boot partition.${nc}"; exit 1; }
    umount /boot

    echo "${red}Copied ${local_version} to /boot/efi/boot/bootx64.efi.${nc}"
}

# Compile and sign the unified kernel image.
compile_uki() {
    initramfs_path="${src_path}/${system}/initramfs/initramfs-${system}.cpio"

    LD_PRELOAD="" make -j6 || { echo "${red}Error compiling kernel ${local_version}.${nc}"; exit 1; }
    make modules_install || { echo "${red}Error compiling modules to /lib/modules/${local_version}/.${nc}"; exit 1; }

    dracut -f --kver=${local_version} ${initramfs_path} || { echo "${red}Error creating dracut initramfs image for ${local_version}.${nc}"; exit 1; }

    LD_PRELOAD="" make -j6 || { echo "${red}Error compiling kernel ${local_version} with the new initramfs image.${nc}"; exit 1; }
    sbsign --key "/etc/keys/efikeys/db.key" --cert "/etc/keys/efikeys/db.crt" --output "${src_path}/${system}/uki/vmlinuz-${local_version}.efi" "${linux_src_path}/arch/x86/boot/bzImage" \
        || { echo "${red}Error signing unified kernel image vmlinuz-${local_version}.efi.${nc}"; exit 1; }

    echo "${green}Finished creating ${local_version} UKI.${nc}"
}

uninstall_modules() {
    rm -r "/lib/modules/${local_version}/" || { echo "${red}Error removing modules from /lib/modules/${local_version}/.${nc}"; exit 1; }
}

# Allow the user to select which system to compile a kernel for.
case ${1} in
    angelica)
        system="angelica"
        select_version && compile_uki && uninstall_modules
    ;;

    kotori)
        system="kotori"
        select_version && compile_uki && copy_to_boot
    ;;

    *)
        echo "Unkown option: \"${1}\""
        echo "Correct Usuage: ${0} [SYSTEM]"
        echo "Available systems: angelica, kotori"
    ;;
esac
