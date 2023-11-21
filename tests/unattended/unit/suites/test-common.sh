#!/usr/bin/env bash
set -euo pipefail
base_dir="$(cd "$(dirname "$BASH_SOURCE")"; pwd -P; cd - >/dev/null;)"
source "${base_dir}"/bach.sh

@setup-test {
    @ignore common_logger
}

function load-common_checkSystem() {
    @load_function "${base_dir}/common.sh" common_checkSystem
}

test-ASSERT-FAIL-01-common_checkSystem-empty() {
    load-common_checkSystem
    @mock command -v yum === @false
    @mock command -v apt-get === @false
    common_checkSystem
}

test-02-common_checkSystem-yum() {
    load-common_checkSystem
    @mock command -v yum === @echo /usr/bin/yum
    @mock command -v apt-get === @false
    common_checkSystem
    echo "$sys_type"
    echo "$sep"
}

test-02-common_checkSystem-yum-assert() {
    sys_type="yum"
    sep="-"
    echo "$sys_type"
    echo "$sep"
}


test-03-common_checkSystem-apt() {
    load-common_checkSystem
    @mock command -v yum === @false
    @mock command -v apt-get === @echo /usr/bin/apt-get
    common_checkSystem
    echo "$sys_type"
    echo "$sep"
}

test-03-common_checkSystem-apt-assert() {
    sys_type="apt-get"
    sep="="
    echo "$sys_type"
    echo "$sep"
}

function load-common_checkInstalled() {
    @load_function "${base_dir}/common.sh" common_checkInstalled
}

test-04-common_checkInstalled-all-installed-yum() {
    load-common_checkInstalled
    sys_type="yum"

    @mocktrue yum list installed

    @mock grep cyware-manager === @echo cyware-manager.x86_64 4.9.0-1 @cyware
    @mkdir /var/ossec

    @mock grep cyware-indexer === @echo cyware-indexer.x86_64 1.13.2-1 @cyware
    @mkdir /var/lib/cyware-indexer/
    @mkdir /usr/share/cyware-indexer
    @mkdir /etc/cyware-indexer

    @mock grep filebeat === @echo filebeat.x86_64 7.10.2-1 @cyware
    @mkdir /var/lib/filebeat/
    @mkdir /usr/share/filebeat
    @mkdir /etc/filebeat

    @mock grep cyware-dashboard === @echo cyware-dashboard.x86_64
    @mkdir /var/lib/cyware-dashboard/
    @mkdir /usr/share/cyware-dashboard/
    @mkdir /etc/cyware-dashboard

    common_checkInstalled
    @echo $cyware_installed
    @echo $cyware_remaining_files
    @rmdir /var/ossec

    @echo $indexer_installed
    @echo $indexer_remaining_files
    @rmdir /var/lib/cyware-indexer/
    @rmdir /usr/share/cyware-indexer
    @rmdir /etc/cyware-indexer

    @echo $filebeat_installed
    @echo $filebeat_remaining_files
    @rmdir /var/lib/filebeat/
    @rmdir /usr/share/filebeat
    @rmdir /etc/filebeat

    @echo $dashboard_installed
    @echo $dashboard_remaining_files
    @rmdir /var/lib/cyware-dashboard/
    @rmdir /usr/share/cyware-dashboard/
    @rmdir /etc/cyware-dashboard/

}

test-05-common_checkInstalled-all-installed-yum-assert() {
    @echo "cyware-manager.x86_64 4.9.0-1 @cyware"
    @echo 1

    @echo "cyware-indexer.x86_64 4.6.0-1 @cyware"
    @echo 1

    @echo "filebeat.x86_64 7.10.2-1 @cyware"
    @echo 1

    @echo "cyware-dashboard.x86_64"
    @echo 1
}


test-05-common_checkInstalled-all-installed-apt() {
    load-common_checkInstalled
    sys_type="apt-get"

    @mocktrue apt list --installed

    @mock grep cyware-manager === @echo cyware-manager/now 4.2.5-1 amd64 [installed,local]
    @mkdir /var/ossec

    @mock grep cyware-indexer === @echo cyware-indexer/stable,now 1.13.2-1 amd64 [installed]

    @mkdir /var/lib/cyware-indexer/
    @mkdir /usr/share/cyware-indexer
    @mkdir /etc/cyware-indexer

    @mock grep filebeat === @echo filebeat/now 7.10.2 amd64 [installed,local]
    @mkdir /var/lib/filebeat/
    @mkdir /usr/share/filebeat
    @mkdir /etc/filebeat

    @mock grep cyware-dashboard === @echo cyware-dashboard/now 1.13.2 amd64 [installed,local]
    @mkdir /var/lib/cyware-dashboard/
    @mkdir /usr/share/cyware-dashboard/
    @mkdir /etc/cyware-dashboard

    common_checkInstalled
    @echo $cyware_installed
    @echo $cyware_remaining_files
    @rmdir /var/ossec

    @echo $indexer_installed
    @echo $indexer_remaining_files
    @rmdir /var/lib/cyware-indexer/
    @rmdir /usr/share/cyware-indexer
    @rmdir /etc/cyware-indexer

    @echo $filebeat_installed
    @echo $filebeat_remaining_files
    @rmdir /var/lib/filebeat/
    @rmdir /usr/share/filebeat
    @rmdir /etc/filebeat

    @echo $dashboard_installed
    @echo $dashboard_remaining_files
    @rmdir /var/lib/cyware-dashboard/
    @rmdir /usr/share/cyware-dashboard/
    @rmdir /etc/cyware-dashboard/

}

test-05-common_checkInstalled-all-installed-apt-assert() {
    @echo "cyware-manager/now 4.2.5-1 amd64 [installed,local]"
    @echo 1

    @echo "cyware-indexer/stable,now 1.13.2-1 amd64 [installed]"
    @echo 1

    @echo "filebeat/now 7.10.2 amd64 [installed,local]"
    @echo 1

    @echo "cyware-dashboard/now 1.13.2 amd64 [installed,local]"
    @echo 1
}

test-06-common_checkInstalled-nothing-installed-apt() {
    load-common_checkInstalled
    sys_type="apt-get"

    @mocktrue apt list --installed

    @mock grep cyware-manager

    @mock grep cyware-indexer


    @mock grep filebeat

    @mock grep cyware-dashboard

    common_checkInstalled
    @echo $cyware_installed
    @echo $cyware_remaining_files

    @echo $indexer_installed
    @echo $indexer_remaining_files

    @echo $filebeat_installed
    @echo $filebeat_remaining_files

    @echo $dashboard_installed
    @echo $dashboard_remaining_files
}

test-06-common_checkInstalled-nothing-installed-apt-assert() {
    @echo ""
    @echo ""

    @echo ""
    @echo ""

    @echo ""
    @echo ""

    @echo ""
    @echo ""
}

test-07-common_checkInstalled-nothing-installed-yum() {
    load-common_checkInstalled
    sys_type="yum"

    @mocktrue yum list installed

    @mock grep cyware-manager

    @mock grep cyware-indexer


    @mock grep filebeat

    @mock grep cyware-dashboard

    common_checkInstalled
    @echo $cyware_installed
    @echo $cyware_remaining_files

    @echo $indexer_installed
    @echo $indexer_remaining_files

    @echo $filebeat_installed
    @echo $filebeat_remaining_files

    @echo $dashboard_installed
    @echo $dashboard_remaining_files
}

test-07-common_checkInstalled-nothing-installed-yum-assert() {
    @echo ""
    @echo ""

    @echo ""
    @echo ""

    @echo ""
    @echo ""

    @echo ""
    @echo ""
}
