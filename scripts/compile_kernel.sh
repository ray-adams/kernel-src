#!/bin/sh

# compile_kernel.sh - Compile Kernel Images (REQUIRES ROOT PRIVILAGES).

# Copyright 2024 Ray Adams
# SPDX-Licence-Identifier: BSD-3-Clause

# Version: 1.0.0

src_path="/usr/local/src/"

# Check if the script was executed with root privilages.
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this shell script as root."
    exit 1
fi

# Choose available kernel version for system.
select_version() {
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

# Install modules.
install_modules() {
    make modules_install || { echo "Error installing modules to /lib/modules/${local_version}/."; exit 1; }
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

    make -j6 || { echo "Error compiling kernel ${local_version}."; exit 1; }
    make modules_install || { echo "Error installing modules to /lib/modules/${local_version}/."; exit 1; }

    dracut -f --kver=${local_version} ${initramfs_path} || { echo "Error creating dracut initramfs image for ${local_version}."; exit 1; }

    make -j6 || { echo "Error compiling kernel ${local_version} with the new initramfs image."; exit 1; }
    sbsign --key "/etc/keys/efikeys/db.key" --cert "/etc/keys/efikeys/db.crt" --output "${src_path}/${system}/uki/vmlinuz-${local_version}.efi" "${linux_src_path}/arch/x86/boot/bzImage" \
        || { echo "Error signing unified kernel image vmlinuz-${local_version}.efi."; exit 1; }

    echo "Finished creating ${local_version} UKI."
}

# Allow the user to select which system to compile a kernel for.
case ${1} in
    angelica)
        system="angelica"
        select_version && compile_uki
    ;;

    kotori)
        system="kotori"
        select_version && compile_uki && install_modules && copy_to_boot
    ;;

    *)
        echo "Unkown option."
    ;;
esac
