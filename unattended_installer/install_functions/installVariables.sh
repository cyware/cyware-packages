# Cyware installer - variables
# Copyright (C) 2015, KhulnaSoft Ltd.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

## Package vars
readonly cyware_major="4.9"
readonly cyware_version="4.9.0"
readonly filebeat_version="7.10.2"
readonly cyware_install_vesion="0.1"
readonly source_branch="v${cyware_version}"

## Links and paths to resources
readonly resources="https://${bucket}/${cyware_major}"
readonly base_url="https://${bucket}/${repository}"
base_path="$(dirname "$(readlink -f "$0")")"
readonly base_path
config_file="${base_path}/config.yml"
readonly tar_file_name="cyware-install-files.tar"
tar_file="${base_path}/${tar_file_name}"

readonly filebeat_cyware_template="https://raw.githubusercontent.com/cyware/cyware/${source_branch}/extensions/elasticsearch/7.x/cyware-template.json"

readonly dashboard_cert_path="/etc/cyware-dashboard/certs"
readonly filebeat_cert_path="/etc/filebeat/certs"
readonly indexer_cert_path="/etc/cyware-indexer/certs"

readonly logfile="/var/log/cyware-install.log"
debug=">> ${logfile} 2>&1"
readonly yum_lockfile="/var/run/yum.pid"
readonly apt_lockfile="/var/lib/dpkg/lock"

## Offline Installation vars
readonly base_dest_folder="cyware-offline"
readonly manager_deb_base_url="${base_url}/apt/pool/main/w/cyware-manager"
readonly filebeat_deb_base_url="${base_url}/apt/pool/main/f/filebeat"
readonly filebeat_deb_package="filebeat-oss-${filebeat_version}-amd64.deb"
readonly indexer_deb_base_url="${base_url}/apt/pool/main/w/cyware-indexer"
readonly dashboard_deb_base_url="${base_url}/apt/pool/main/w/cyware-dashboard"
readonly manager_rpm_base_url="${base_url}/yum"
readonly filebeat_rpm_base_url="${base_url}/yum"
readonly filebeat_rpm_package="filebeat-oss-${filebeat_version}-x86_64.rpm"
readonly indexer_rpm_base_url="${base_url}/yum"
readonly dashboard_rpm_base_url="${base_url}/yum"
readonly cyware_gpg_key="https://${bucket}/key/GPG-KEY-CYWARE"
readonly filebeat_config_file="${resources}/tpl/cyware/filebeat/filebeat.yml"

adminUser="cyware"
adminPassword="cyware"

http_port=443
cyware_aio_ports=( 9200 9300 1514 1515 1516 55000 "${http_port}")
readonly cyware_indexer_ports=( 9200 9300 )
readonly cyware_manager_ports=( 1514 1515 1516 55000 )
cyware_dashboard_port="${http_port}"
