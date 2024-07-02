#!/bin/sh

# Script Name: compile_kernel.sh
# File Path: <git_root>/scripts/compile_kernel.sh
# Description: Compile kernel images based on user selected version (REQUIRES ROOT PRIVILAGES).

# Copyright 2024 Ray Adams
# SPDX-Licence-Identifier: BSD-3-Clause

# Version: 2.3.1

src_path="/usr/local/src/"

# Check if the script was executed with root privilages.
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this shell script as root."
    exit 1
fi

# Choose available kernel version for system.
select_version() {
    if [ ! -e "${src_path}/${system}/" ]; then
        echo "The directory ${src_path}/${system} does not exist."
        exit 1
    fi

    echo "Available linux kernels:"
    ls "${src_path}/${system}/linux/"
    while true; do
        echo "Select a version:"
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

    cd ${linux_src_path}
}

# Compile the kernel without an initramfs.
compile_kernel() {
    make -j6 || { echo "Error compiling kernel ${local_version}."; exit 1; }

    cp "${linux_src_path}/arch/x86/boot/bzImage" "${src_path}/${system}/vmlinuz/vmlinuz-${local_version}.efi" || { echo "Error copying vmlinuz-${local_version}.efi to source directory."; exit 1; }

    echo "Finished creating ${local_version} kernel image."
}

# Copy the unified kernel image to the boot partition.
copy_to_boot() {
    mount /boot
    cp "${src_path}/${system}/uki/vmlinuz-${local_version}.efi" "/boot/efi/boot/bootx64.efi" || { echo "Error copying vmlinuz-${local_version}.efi to boot partition."; exit 1; }
    umount /boot

    echo "Copied ${local_version} to /boot/efi/boot/bootx64.efi."
}

# Compile and sign the unified kernel image.
compile_uki() {
    initramfs_path="${src_path}/${system}/initramfs/initramfs-${system}.cpio"

    LD_PRELOAD="" make -j6 || { echo "Error compiling kernel ${local_version}."; exit 1; }
    make modules_install || { echo "Error compiling modules to /lib/modules/${local_version}/."; exit 1; }

    dracut -f --kver=${local_version} ${initramfs_path} || { echo "Error creating dracut initramfs image for ${local_version}."; exit 1; }

    LD_PRELOAD="" make -j6 || { echo "Error compiling kernel ${local_version} with the new initramfs image."; exit 1; }
    sbsign --key "/etc/keys/efikeys/db.key" --cert "/etc/keys/efikeys/db.crt" --output "${src_path}/${system}/uki/vmlinuz-${local_version}.efi" "${linux_src_path}/arch/x86/boot/bzImage" \
        || { echo "Error signing unified kernel image vmlinuz-${local_version}.efi."; exit 1; }

    echo "Finished creating ${local_version} UKI."
}

uninstall_modules() {
    rm -r "/lib/modules/${local_version}/" || { echo "Error removing modules from /lib/modules/${local_version}/"; exit 1; }
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
