#!/bin/sh

# Script Name: replace_cmdline.sh
# File Path: <git_root>/scripts/replace_cmdline.sh
# Description: Replace kernel cmdline parameters.

# Copyright 2024 Ray Adams
# SPDX-Licence-Identifier: BSD-3-Clause

# Version: 2.2.1

# Obtain the path for <git_root>
working_dir="$(git rev-parse --show-toplevel)"

# Colors
green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m'

# CMDLINE parameters
angelica_cmd_line="rootfstype=bcachefs root=UUID=<root_uuid> nosmt=force intel_iommu=on quiet"
eleanore_cmd_line="root=PARTUUID=<root_partuuid> nvidia_drm.fbdev=1 nosmt=force quiet"
kotori_cmd_line="rootfs_type=bcachefs root=UUID=<root_uuid> nosmt=force intel_iommu=on quiet"

find "${working_dir}/configs/angelica/" -type f -exec sed -i "s/^CONFIG_CMDLINE=.*/CONFIG_CMDLINE=\"${angelica_cmd_line}\"/" {} + \
    || { echo "${red}Error replacing angelica command line parameters.${nc}"; exit 1; }
find "${working_dir}/configs/eleanore-compile/" -type f -exec sed -i "s/^CONFIG_CMDLINE=.*/CONFIG_CMDLINE=\"${eleanore_cmd_line}\"/" {} + \
    || { echo "${red}Error replacing eleanore command line parameters.${nc}"; exit 1; }
find "${working_dir}/configs/kotori/" -type f -exec sed -i "s/^CONFIG_CMDLINE=.*/CONFIG_CMDLINE=\"${kotori_cmd_line}\"/" {} + \
    || { echo "${red}Error replacing kotori command line parameters.${nc}"; exit 1; }

echo "${green}Finished replacing command line parameters.${nc}"
