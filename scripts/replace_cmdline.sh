#!/bin/sh

# Script Name: replace_cmdline.sh
# File Path: <git_root>/scripts/replace_cmdline.sh
# Description: Replace kernel cmdline parameters.

# Copyright 2024 Ray Adams
# SPDX-Licence-Identifier: BSD-3-Clause

# Version: 2.1.1

working_dir="$(git rev-parse --show-toplevel)"

angelica_cmd_line="rootfstype=bcachefs root=UUID=<root_uuid> nosmt=force intel_iommu=on"
eleanore_cmd_line="root=PARTUUID=<root_partuuid> nosmt=force"
kotori_cmd_line="rootfs_type=bcachefs root=UUID=<root_uuid> nosmt=force intel_iommu=on"

find "${working_dir}/configs/angelica/" -type f -exec sed -i "s/^CONFIG_CMDLINE=.*/CONFIG_CMDLINE=\"${angelica_cmd_line}\"/" {} + \
    || { echo "Error replacing angelica command line parameters."; exit 1; }
find "${working_dir}/configs/eleanore/" -type f -exec sed -i "s/^CONFIG_CMDLINE=.*/CONFIG_CMDLINE=\"${eleanore_cmd_line}\"/" {} + \
    || { echo "Error replacing eleanore command line parameters."; exit 1; }
find "${working_dir}/configs/kotori/" -type f -exec sed -i "s/^CONFIG_CMDLINE=.*/CONFIG_CMDLINE=\"${kotori_cmd_line}\"/" {} + \
    || { echo "Error replacing kotori command line parameters."; exit 1; }

echo "Finished replacing command line parameters."
