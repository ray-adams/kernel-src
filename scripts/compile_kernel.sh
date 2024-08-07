#!/bin/sh

# Script Name: compile_kernel.sh
# File Path: <git_root>/scripts/compile_kernel.sh
# Description: Compile kernel images based on user selected version (REQUIRES ROOT PRIVILAGES).

# Copyright 2024 Ray Adams
# SPDX-Licence-Identifier: BSD-3-Clause

# Version: 3.2.7

# Default source path
src_path="/usr/local/src/"

# Colors
green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m'

# Check if the script was executed with root privilages
if [ "$(id -u)" -ne 0 ]; then
    echo "${red}Please run this shell script as root.${nc}"
    exit 1
fi

# Choose available kernel version for system
select_version() {
    # Check if the source directory exists for chosen system
    if [ ! -e "${src_path}/${system}/" ]; then
        echo "${red}The directory ${src_path}/${system} does not exist.${nc}"
        exit 1
    fi

    # Ask user to choose a kernel version
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
            version="linux-${version}"
            break
        else
            echo "${red}Please choose a valid version.${nc}"
        fi
    done

    # Local version for selected linux version
    local_version="$(echo ${version} | sed 's/linux-//')-$(grep "^CONFIG_LOCALVERSION" "${linux_src_path}/.config" | sed 's/^CONFIG_LOCALVERSION="-//' | tr -d '"')"
}

# Compile the kernel without an initramfs
compile_kernel() {
    compile_dir="/var/tmp/linux/${system}/"

    mkdir -p "${src_path}/${system}/vmlinuz/"

    # Check if tmpfs directory exists
    if [ ! -d "${compile_dir}" ]; then
        echo "${red}tmpfs directory ${compile_dir} not found.${nc}"
        exit 1
    fi

    # Mount tmpfs directory
    mount "${compile_dir}" || { echo "${red}Error mounting tmpfs directory ${compile_dir}.${nc}"; exit 1; }

    # Copy source directory to tmpfs
    cp -r "${linux_src_path}" "${compile_dir}" || { echo "${red}Error copying ${local_version} to tmpfs directory.${nc}"; exit 1; }

    # Compile the kernel
    cd "${compile_dir}/${version}/"
    LD_PRELOAD="" make -j6 || { echo "${red}Error compiling kernel ${local_version}.${nc}"; exit 1; }
    make modules_install || { echo "${red}Error compiling modules to /lib/modules/${local_version}/.${nc}"; exit 1; }

    cp "${compile_dir}/${version}/arch/x86/boot/bzImage" "${src_path}/${system}/vmlinuz/vmlinuz-${local_version}.efi" || { echo "${red}Error copying vmlinuz-${local_version}.efi to source directory.${nc}"; exit 1; }

    echo "${green}Finished creating ${local_version} kernel image.${nc}"
}

# Compile nvidia drivers
compile_nvidia() {
    echo "${green}Changing /usr/src/linux symlink to tmpfs.${nc}"
    rm "/usr/src/linux" || { echo "${red}Error removing symlink /usr/src/linux.${nc}"; exit 1; }
    ln -sf "${compile_dir}/${version}/" "/usr/src/linux" || { echo "${red}Error creating symlink to ${compile_dir}.${nc}"; exit 1; }

    echo "${green}Compiling nvidia drivers.${nc}"
    EMERGE_DEFAULT_OPTS="--quiet" emerge x11-drivers/nvidia-drivers || { echo "${red}Error compiling nvidia drivers.${nc}"; exit 1; }

    echo "${green}Changing /usr/src/linux symlink back to ${linux_src_path}.${nc}"
    rm "/usr/src/linux" || { echo "${red}Error removing symlink /usr/src/linux.${nc}"; exit 1; }
    ln -sf "${linux_src_path}/" "/usr/src/linux" || { echo "${red}Error creating symlink to ${linux_src_path}.${nc}"; exit 1; }

    remove_tmp_dir
}

# Compile and sign the unified kernel image.
compile_uki() {
    compile_dir="/var/tmp/linux/${system}/"
    initramfs_path="${src_path}/${system}/initramfs/initramfs-${system}.cpio"

    mkdir -p "${src_path}/${system}/initramfs/"
    mkdir -p "${src_path}/${system}/uki/"

    # Check if tmpfs directory exists
    if [ ! -d "${compile_dir}" ]; then
        echo "${red}tmpfs directory ${compile_dir} not found.${nc}"
        exit 1
    fi

    # Mount tmpfs directory
    mount "${compile_dir}" || { echo "${red}Error mounting tmpfs directory ${compile_dir}.${nc}"; exit 1; }

    # Copy source directory to tmpfs
    cp -r "${linux_src_path}" "${compile_dir}" || { echo "${red}Error copying ${local_version} to tmpfs directory.${nc}"; exit 1; }

    # Compile the kernel
    cd "${compile_dir}/${version}/"

    LD_PRELOAD="" make -j6 || { echo "${red}Error compiling kernel ${local_version}.${nc}"; exit 1; }
    make modules_install || { echo "${red}Error compiling modules to /lib/modules/${local_version}/.${nc}"; exit 1; }
    dracut -f --kver=${local_version} ${initramfs_path} || { echo "${red}Error creating dracut initramfs image for ${local_version}.${nc}"; exit 1; }
    LD_PRELOAD="" make -j6 || { echo "${red}Error compiling kernel ${local_version} with the new initramfs image.${nc}"; exit 1; }

    sbsign --key "/etc/keys/efikeys/db.key" --cert "/etc/keys/efikeys/db.crt" --output "${src_path}/${system}/uki/vmlinuz-${local_version}.efi" "${compile_dir}/${version}/arch/x86/boot/bzImage" \
        || { echo "${red}Error signing unified kernel image vmlinuz-${local_version}.efi.${nc}"; exit 1; }

    remove_tmp_dir

    echo "${green}Finished creating ${local_version} UKI.${nc}"
}

# Copy the unified kernel image to the boot partition.
copy_to_boot() {
    mount /boot

    # Check if a UKI is available if not we will copy the non-UKI.
    if [ -d "${src_path}/${system}/uki/" ]; then
        cp "${src_path}/${system}/uki/vmlinuz-${local_version}.efi" "/boot/efi/boot/bootx64.efi" || { echo "${red}Error copying vmlinuz-${local_version}.efi to boot partition.${nc}"; exit 1; }
    else
        cp "${src_path}/${system}/vmlinuz/vmlinuz-${local_version}.efi" "/boot/efi/boot/bootx64.efi" || { echo "${red}Error copying vmlinuz-${local_version}.efi to boot partition.${nc}"; exit 1; }
    fi

    umount /boot

    echo "${green}Copied ${local_version} to /boot/efi/boot/bootx64.efi.${nc}"
}

move_modules() {
    mkdir -p "${src_path}/${system}/modules/"
    mv "/lib/modules/${local_version}/" "${src_path}/${system}/modules/" || { echo "${red}Error moving modules from /lib/modules/${local_version}/ to ${src_path}/${system}/modules/.${nc}"; exit 1; }
    echo "${green}Finished moving modules for ${local_version} to ${src_path}/${system}/modules/.${nc}"
}

remove_tmp_dir() {
    # Remove kernel directory from tmpfs
    cd "${src_path}/${system}/"
    rm -r "${compile_dir}/${version}/" || { echo "${red}Error removing ${local_version} from tmpfs.${nc}"; exit 1; }
    umount "${compile_dir}" || { echo "${red}Error unmounting tmpfs.${nc}"; exit 1; }
}

# Allow the user to select which system to compile a kernel for.
case ${1} in
    angelica)
        system="angelica"
        select_version && compile_uki && move_modules
    ;;

    eleanore)
        system="eleanore"
        select_version && compile_kernel && compile_nvidia && copy_to_boot
    ;;

    kotori)
        system="kotori"
        select_version && compile_uki && copy_to_boot
    ;;

    *)
        echo "Unkown option: \"${1}\""
        echo "Correct Usuage: ${0} [SYSTEM]"
        echo "Available systems: angelica, eleanore, kotori"
    ;;
esac
