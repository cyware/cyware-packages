#!/bin/bash

PACKAGES_REPOSITORY=$1
DEBUG=$2

RESOURCES_PATH="/tmp/unattended_installer"
BUILDER="builder.sh"
INSTALLER="cyware-install.sh"
SYSTEM_USER="cyware-user"
HOSTNAME="cyware-server"

CURRENT_PATH="$( cd $(dirname $0) ; pwd -P )"
ASSETS_PATH="${CURRENT_PATH}/assets"
CUSTOM_PATH="${ASSETS_PATH}/custom"
BUILDER_ARGS="-i"
INSTALL_ARGS="-a"

if [[ "${PACKAGES_REPOSITORY}" == "dev" ]]; then
  BUILDER_ARGS+=" -d"
elif [[ "${PACKAGES_REPOSITORY}" == "staging" ]]; then
  BUILDER_ARGS+=" -d staging"
fi

if [[ "${DEBUG}" = "yes" ]]; then
  INSTALL_ARGS+=" -v"
fi

echo "Using ${PACKAGES_REPOSITORY} packages"

. ${ASSETS_PATH}/steps.sh

# Build install script
bash ${RESOURCES_PATH}/${BUILDER} ${BUILDER_ARGS}
CYWARE_VERSION=$(cat ${RESOURCES_PATH}/${INSTALLER} | grep "cyware_version=" | cut -d "\"" -f 2)

# System configuration
systemConfig

# Edit installation script
preInstall

# Install
bash ${RESOURCES_PATH}/${INSTALLER} ${INSTALL_ARGS}

systemctl stop cyware-dashboard filebeat cyware-indexer cyware-manager
systemctl enable cyware-manager
rm -f /var/log/cyware-indexer/*
rm -f /var/log/filebeat/*

clean
