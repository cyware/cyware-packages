#!/usr/bin/env bash
set -euo pipefail
base_dir="$(cd "$(dirname "$BASH_SOURCE")"; pwd -P; cd - >/dev/null;)"
source "${base_dir}"/bach.sh

@setup-test {
    @ignore common_logger
}

function load-installCommon_getConfig() {
    @load_function "${base_dir}/installCommon.sh" installCommon_getConfig
}

test-ASSERT-FAIL-01-installCommon_getConfig-no-args() {
    load-installCommon_getConfig
    installCommon_getConfig
}

test-ASSERT-FAIL-02-installCommon_getConfig-one-argument() {
    load-installCommon_getConfig
    installCommon_getConfig "elasticsearch"
}

test-03-installCommon_getConfig() {
    load-installCommon_getConfig
    @mocktrue echo certificate/config_aio.yml
    @mock sed 's|/|_|g;s|.yml||' === @out "certificate_config_aio"
    @mock echo === @echo "Hello World"
    installCommon_getConfig certificate/config_aio.yml ./config.yml
}

test-03-installCommon_getConfig-assert() {
    eval "echo \"\${config_file_certificate_config_aio}\""

}

test-04-installCommon_getConfig-error() {
    load-installCommon_getConfig
    @mocktrue echo certificate/config_aio.yml
    @mock sed 's|/|_|g;s|.yml||' === @out "certificate_config_aio"
    @mock echo === @echo ""
    installCommon_getConfig certificate/config_aio.yml ./config.yml
}

test-04-installCommon_getConfig-error-assert() {
    installCommon_rollBack
    exit 1
}

function load-installCommon_installPrerequisites() {
    @load_function "${base_dir}/installCommon.sh" installCommon_installPrerequisites
}

test-05-installCommon_installPrerequisites-yum-no-openssl() {
    @mock command -v openssl === @false
    load-installCommon_installPrerequisites
    sys_type="yum"
    debug=""
    installCommon_installPrerequisites
}

test-05-installCommon_installPrerequisites-yum-no-openssl-assert() {
    yum install curl unzip wget libcap tar gnupg openssl -y
}

test-06-installCommon_installPrerequisites-yum() {
    @mock command -v openssl === @echo /usr/bin/openssl
    load-installCommon_installPrerequisites
    sys_type="yum"
    debug=""
    installCommon_installPrerequisites
}

test-06-installCommon_installPrerequisites-yum-assert() {
    yum install curl unzip wget libcap tar gnupg -y
}


test-07-installCommon_installPrerequisites-apt-no-openssl() {
    @mock command -v openssl === @false
    load-installCommon_installPrerequisites
    sys_type="apt-get"
    debug=""
    installCommon_installPrerequisites
}

test-07-installCommon_installPrerequisites-apt-no-openssl-assert() {
    apt update -q
    apt install apt-transport-https curl unzip wget libcap2-bin tar software-properties-common gnupg openssl -y
}

test-08-installCommon_installPrerequisites-apt() {
    @mock command -v openssl === @out /usr/bin/openssl
    load-installCommon_installPrerequisites
    sys_type="apt-get"
    debug=""
    installCommon_installPrerequisites
}

test-08-installCommon_installPrerequisites-apt-assert() {
    apt update -q
    apt install apt-transport-https curl unzip wget libcap2-bin tar software-properties-common gnupg -y
}

function load-installCommon_addCywareRepo() {
    @load_function "${base_dir}/installCommon.sh" installCommon_addCywareRepo
}

test-09-installCommon_addCywareRepo-yum() {
    load-installCommon_addCywareRepo
    development=1
    sys_type="yum"
    debug=""
    repogpg=""
    releasever=""
    @mocktrue echo -e '[cyware]\ngpgcheck=1\ngpgkey=\nenabled=1\nname=EL-${releasever} - Cyware\nbaseurl=/yum/\nprotect=1'
    @mocktrue tee /etc/yum.repos.d/cyware.repo
    installCommon_addCywareRepo
}

test-09-installCommon_addCywareRepo-yum-assert() {
    rm -f /etc/yum.repos.d/cyware.repo
    rpm --import
}


test-10-installCommon_addCywareRepo-apt() {
    load-installCommon_addCywareRepo
    development=1
    sys_type="apt-get"
    debug=""
    repogpg=""
    releasever=""
    @rm /etc/yum.repos.d/cyware.repo
    @rm /etc/zypp/repos.d/cyware.repo
    @rm /etc/apt/sources.list.d/cyware.list
    @mocktrue curl -s --max-time 300
    @mocktrue apt-key add -
    @mocktrue echo "deb /apt/  main"
    @mocktrue tee /etc/apt/sources.list.d/cyware.list
    installCommon_addCywareRepo
}

test-10-installCommon_addCywareRepo-apt-assert() {
    rm -f /etc/apt/sources.list.d/cyware.list
    apt-get update -q
}

test-11-installCommon_addCywareRepo-apt-file-present() {
    load-installCommon_addCywareRepo
    development=""
    @mkdir -p /etc/yum.repos.d
    @touch /etc/yum.repos.d/cyware.repo
    installCommon_addCywareRepo
    @assert-success
    @rm /etc/yum.repos.d/cyware.repo
}

test-12-installCommon_addCywareRepo-yum-file-present() {
    load-installCommon_addCywareRepo
    development=""
    @mkdir -p /etc/apt/sources.list.d/
    @touch /etc/apt/sources.list.d/cyware.list
    installCommon_addCywareRepo
    @assert-success
    @rm /etc/apt/sources.list.d/cyware.list
}

function load-installCommon_restoreCywarerepo() {
    @load_function "${base_dir}/installCommon.sh" installCommon_restoreCywarerepo
}

test-13-installCommon_restoreCywarerepo-no-dev() {
    load-installCommon_restoreCywarerepo
    development=""
    installCommon_restoreCywarerepo
    @assert-success
}

test-14-installCommon_restoreCywarerepo-yum() {
    load-installCommon_restoreCywarerepo
    development="1"
    sys_type="yum"
    @mkdir -p /etc/yum.repos.d
    @touch /etc/yum.repos.d/cyware.repo
    installCommon_restoreCywarerepo
    @rm /etc/yum.repos.d/cyware.repo
}

test-14-installCommon_restoreCywarerepo-yum-assert() {
    sed -i 's/-dev//g' /etc/yum.repos.d/cyware.repo
    sed -i 's/pre-release/4.x/g' /etc/yum.repos.d/cyware.repo
    sed -i 's/unstable/stable/g' /etc/yum.repos.d/cyware.repo
}

test-15-installCommon_restoreCywarerepo-apt() {
    load-installCommon_restoreCywarerepo
    development="1"
    sys_type="apt-get"
    @mkdir -p /etc/apt/sources.list.d/
    @touch /etc/apt/sources.list.d/cyware.list
    installCommon_restoreCywarerepo
    @rm /etc/apt/sources.list.d/cyware.list
}

test-15-installCommon_restoreCywarerepo-apt-assert() {
    sed -i 's/-dev//g' /etc/apt/sources.list.d/cyware.list
    sed -i 's/pre-release/4.x/g' /etc/apt/sources.list.d/cyware.list
    sed -i 's/unstable/stable/g' /etc/apt/sources.list.d/cyware.list
}


test-16-installCommon_restoreCywarerepo-yum-no-file() {
    load-installCommon_restoreCywarerepo
    development="1"
    sys_type="yum"
    installCommon_restoreCywarerepo
}

test-16-installCommon_restoreCywarerepo-yum-no-file-assert() {
    sed -i 's/-dev//g'
    sed -i 's/pre-release/4.x/g'
    sed -i 's/unstable/stable/g'
}

test-17-installCommon_restoreCywarerepo-apt-no-file() {
    load-installCommon_restoreCywarerepo
    development="1"
    sys_type="yum"
    installCommon_restoreCywarerepo
}

test-17-installCommon_restoreCywarerepo-apt-no-file-assert() {
    sed -i 's/-dev//g'
    sed -i 's/pre-release/4.x/g'
    sed -i 's/unstable/stable/g'
}

function load-installCommon_createClusterKey {
    @load_function "${base_dir}/installCommon.sh" installCommon_createClusterKey
}

test-18-installCommon_createClusterKey() {
    load-installCommon_createClusterKey
    base_path=/tmp
    @mkdir -p /tmp/certs
    @touch /tmp/certs/clusterkey
    @mocktrue openssl rand -hex 16
    installCommon_createClusterKey
    @assert-success
    @rm /tmp/certs/clusterkey
}

function load-installCommon_rollBack {
    @load_function "${base_dir}/installCommon.sh" installCommon_rollBack
}

test-19-installCommon_rollBack-aio-all-installed-yum() {
    load-installCommon_rollBack
    indexer_installed=1
    cyware_installed=1
    dashboard_installed=1
    filebeat_installed=1
    cyware_remaining_files=1
    indexer_remaining_files=1
    dashboard_remaining_files=1
    filebeat_remaining_files=1
    sys_type="yum"
    debug=
    AIO=1
    installCommon_rollBack
}

test-19-installCommon_rollBack-aio-all-installed-yum-assert() {

    yum remove cyware-manager -y

    rm -rf /var/ossec/

    yum remove cyware-indexer -y

    rm -rf /var/lib/cyware-indexer/
    rm -rf /usr/share/cyware-indexer/
    rm -rf /etc/cyware-indexer/

    yum remove filebeat -y

    rm -rf /var/lib/filebeat/
    rm -rf /usr/share/filebeat/
    rm -rf /etc/filebeat/

    yum remove cyware-dashboard -y

    rm -rf /var/lib/cyware-dashboard/
    rm -rf /usr/share/cyware-dashboard/
    rm -rf /etc/cyware-dashboard/
    rm -rf /run/cyware-dashboard/

    rm  -rf /var/log/cyware-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/cyware-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/cyware-dashboard.service /etc/systemd/system/cyware-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-20-installCommon_rollBack-aio-all-installed-apt() {
    load-installCommon_rollBack
    indexer_installed=1
    cyware_installed=1
    dashboard_installed=1
    filebeat_installed=1
    cyware_remaining_files=1
    indexer_remaining_files=1
    dashboard_remaining_files=1
    filebeat_remaining_files=1
    sys_type="apt-get"
    debug=
    AIO=1
    installCommon_rollBack
}

test-20-installCommon_rollBack-aio-all-installed-apt-assert() {
    apt remove --purge cyware-manager -y

    rm -rf /var/ossec/

    apt remove --purge ^cyware-indexer -y

    rm -rf /var/lib/cyware-indexer/
    rm -rf /usr/share/cyware-indexer/
    rm -rf /etc/cyware-indexer/

    apt remove --purge filebeat -y

    rm -rf /var/lib/filebeat/
    rm -rf /usr/share/filebeat/
    rm -rf /etc/filebeat/

    apt remove --purge cyware-dashboard -y

    rm -rf /var/lib/cyware-dashboard/
    rm -rf /usr/share/cyware-dashboard/
    rm -rf /etc/cyware-dashboard/
    rm -rf /run/cyware-dashboard/

    rm  -rf /var/log/cyware-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/cyware-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/cyware-dashboard.service /etc/systemd/system/cyware-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-21-installCommon_rollBack-indexer-installation-all-installed-yum() {
    load-installCommon_rollBack
    indexer_installed=1
    cyware_installed=1
    dashboard_installed=1
    filebeat_installed=1
    cyware_remaining_files=1
    indexer_remaining_files=1
    dashboard_remaining_files=1
    filebeat_remaining_files=1
    sys_type="yum"
    debug=
    indexer=1
    installCommon_rollBack
}

test-21-installCommon_rollBack-indexer-installation-all-installed-yum-assert() {
    yum remove cyware-indexer -y

    rm -rf /var/lib/cyware-indexer/
    rm -rf /usr/share/cyware-indexer/
    rm -rf /etc/cyware-indexer/

    rm  -rf /var/log/cyware-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/cyware-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/cyware-dashboard.service /etc/systemd/system/cyware-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-22-installCommon_rollBack-indexer-installation-all-installed-apt() {
    load-installCommon_rollBack
    indexer_installed=1
    cyware_installed=1
    dashboard_installed=1
    filebeat_installed=1
    cyware_remaining_files=1
    indexer_remaining_files=1
    dashboard_remaining_files=1
    filebeat_remaining_files=1
    sys_type="apt-get"
    debug=
    indexer=1
    installCommon_rollBack
}

test-22-installCommon_rollBack-indexer-installation-all-installed-apt-assert() {
    apt remove --purge ^cyware-indexer -y

    rm -rf /var/lib/cyware-indexer/
    rm -rf /usr/share/cyware-indexer/
    rm -rf /etc/cyware-indexer/

    rm  -rf /var/log/cyware-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/cyware-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/cyware-dashboard.service /etc/systemd/system/cyware-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-23-installCommon_rollBack-cyware-installation-all-installed-yum() {
    load-installCommon_rollBack
    indexer_installed=1
    cyware_installed=1
    dashboard_installed=1
    filebeat_installed=1
    cyware_remaining_files=1
    indexer_remaining_files=1
    dashboard_remaining_files=1
    filebeat_remaining_files=1
    sys_type="yum"
    debug=
    cyware=1
    installCommon_rollBack
}

test-23-installCommon_rollBack-cyware-installation-all-installed-yum-assert() {
    yum remove cyware-manager -y

    rm -rf /var/ossec/

    yum remove filebeat -y

    rm -rf /var/lib/filebeat/
    rm -rf /usr/share/filebeat/
    rm -rf /etc/filebeat/

    rm  -rf /var/log/cyware-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/cyware-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/cyware-dashboard.service /etc/systemd/system/cyware-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-24-installCommon_rollBack-cyware-installation-all-installed-apt() {
    load-installCommon_rollBack
    indexer_installed=1
    cyware_installed=1
    dashboard_installed=1
    filebeat_installed=1
    cyware_remaining_files=1
    indexer_remaining_files=1
    dashboard_remaining_files=1
    filebeat_remaining_files=1
    sys_type="apt-get"
    debug=
    cyware=1
    installCommon_rollBack
}

test-24-installCommon_rollBack-cyware-installation-all-installed-apt-assert() {
    apt remove --purge cyware-manager -y

    rm -rf /var/ossec/

    apt remove --purge filebeat -y

    rm -rf /var/lib/filebeat/
    rm -rf /usr/share/filebeat/
    rm -rf /etc/filebeat/

    rm  -rf /var/log/cyware-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/cyware-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/cyware-dashboard.service /etc/systemd/system/cyware-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-25-installCommon_rollBack-dashboard-installation-all-installed-yum() {
    load-installCommon_rollBack
    indexer_installed=1
    cyware_installed=1
    dashboard_installed=1
    filebeat_installed=1
    cyware_remaining_files=1
    indexer_remaining_files=1
    dashboard_remaining_files=1
    filebeat_remaining_files=1
    sys_type="yum"
    debug=
    dashboard=1
    installCommon_rollBack
}

test-25-installCommon_rollBack-dashboard-installation-all-installed-yum-assert() {
    yum remove cyware-dashboard -y

    rm -rf /var/lib/cyware-dashboard/
    rm -rf /usr/share/cyware-dashboard/
    rm -rf /etc/cyware-dashboard/
    rm -rf /run/cyware-dashboard/

    rm  -rf /var/log/cyware-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/cyware-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/cyware-dashboard.service /etc/systemd/system/cyware-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-26-installCommon_rollBack-dashboard-installation-all-installed-apt() {
    load-installCommon_rollBack
    indexer_installed=1
    cyware_installed=1
    dashboard_installed=1
    filebeat_installed=1
    cyware_remaining_files=1
    indexer_remaining_files=1
    dashboard_remaining_files=1
    filebeat_remaining_files=1
    sys_type="apt-get"
    debug=
    dashboard=1
    installCommon_rollBack
}

test-26-installCommon_rollBack-dashboard-installation-all-installed-apt-assert() {
    apt remove --purge cyware-dashboard -y

    rm -rf /var/lib/cyware-dashboard/
    rm -rf /usr/share/cyware-dashboard/
    rm -rf /etc/cyware-dashboard/
    rm -rf /run/cyware-dashboard/

    rm  -rf /var/log/cyware-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/cyware-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/cyware-dashboard.service /etc/systemd/system/cyware-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-27-installCommon_rollBack-aio-nothing-installed() {
    load-installCommon_rollBack
    indexer_installed=
    cyware_installed=
    dashboard_installed=
    filebeat_installed=
    cyware_remaining_files=
    indexer_remaining_files=
    dashboard_remaining_files=
    filebeat_remaining_files=
    sys_type="yum"
    debug=
    AIO=1
    installCommon_rollBack
    @assert-success
}

test-28-installCommon_rollBack-aio-all-remaining-files-yum() {
    load-installCommon_rollBack
    indexer_installed=
    cyware_installed=
    dashboard_installed=
    filebeat_installed=
    cyware_remaining_files=1
    indexer_remaining_files=1
    dashboard_remaining_files=1
    filebeat_remaining_files=1
    sys_type="yum"
    debug=
    AIO=1
    installCommon_rollBack
}

test-28-installCommon_rollBack-aio-all-remaining-files-yum-assert() {
    rm -rf /var/ossec/

    rm -rf /var/lib/cyware-indexer/
    rm -rf /usr/share/cyware-indexer/
    rm -rf /etc/cyware-indexer/

    rm -rf /var/lib/filebeat/
    rm -rf /usr/share/filebeat/
    rm -rf /etc/filebeat/

    rm -rf /var/lib/cyware-dashboard/
    rm -rf /usr/share/cyware-dashboard/
    rm -rf /etc/cyware-dashboard/
    rm -rf /run/cyware-dashboard/

    rm  -rf /var/log/cyware-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/cyware-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/cyware-dashboard.service /etc/systemd/system/cyware-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-29-installCommon_rollBack-aio-all-remaining-files-apt() {
    load-installCommon_rollBack
    indexer_installed=
    cyware_installed=
    dashboard_installed=
    filebeat_installed=
    cyware_remaining_files=1
    indexer_remaining_files=1
    dashboard_remaining_files=1
    filebeat_remaining_files=1
    sys_type="apt-get"
    debug=
    AIO=1
    installCommon_rollBack
}

test-29-installCommon_rollBack-aio-all-remaining-files-apt-assert() {
    rm -rf /var/ossec/

    rm -rf /var/lib/cyware-indexer/
    rm -rf /usr/share/cyware-indexer/
    rm -rf /etc/cyware-indexer/

    rm -rf /var/lib/filebeat/
    rm -rf /usr/share/filebeat/
    rm -rf /etc/filebeat/

    rm -rf /var/lib/cyware-dashboard/
    rm -rf /usr/share/cyware-dashboard/
    rm -rf /etc/cyware-dashboard/
    rm -rf /run/cyware-dashboard/

    rm  -rf /var/log/cyware-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/cyware-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/cyware-dashboard.service /etc/systemd/system/cyware-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-30-installCommon_rollBack-nothing-installed-remove-yum-repo() {
    load-installCommon_rollBack
    @mkdir -p /etc/yum.repos.d
    @touch /etc/yum.repos.d/cyware.repo
    installCommon_rollBack
    @rm /etc/yum.repos.d/cyware.repo
}

test-30-installCommon_rollBack-nothing-installed-remove-yum-repo-assert() {
    rm /etc/yum.repos.d/cyware.repo

    rm  -rf /var/log/cyware-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/cyware-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/cyware-dashboard.service /etc/systemd/system/cyware-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-31-installCommon_rollBack-nothing-installed-remove-apt-repo() {
    load-installCommon_rollBack
    @mkdir -p /etc/apt/sources.list.d
    @touch /etc/apt/sources.list.d/cyware.list
    installCommon_rollBack
    @rm /etc/apt/sources.list.d/cyware.list
}

test-31-installCommon_rollBack-nothing-installed-remove-apt-repo-assert() {
    rm /etc/apt/sources.list.d/cyware.list

    rm  -rf /var/log/cyware-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/cyware-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/cyware-dashboard.service /etc/systemd/system/cyware-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-32-installCommon_rollBack-nothing-installed-remove-files() {
    load-installCommon_rollBack
    @mkdir -p /var/log/elasticsearch/
    installCommon_rollBack
    @rmdir /var/log/elasticsearch
}

test-32-installCommon_rollBack-nothing-installed-remove-files-assert() {
    rm  -rf /var/log/cyware-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/cyware-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/cyware-dashboard.service /etc/systemd/system/cyware-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

function load-installCommon_createCertificates() {
    @load_function "${base_dir}/installCommon.sh" installCommon_createCertificates
}

test-33-installCommon_createCertificates-aio() {
    load-installCommon_createCertificates
    AIO=1
    base_path=/tmp
    installCommon_createCertificates
}

test-33-installCommon_createCertificates-aio-assert() {
    installCommon_getConfig certificate/config_aio.yml /tmp/config.yml

    cert_readConfig

    mkdir /tmp/certs

    cert_generateRootCAcertificate
    cert_generateAdmincertificate
    cert_generateIndexercertificates
    cert_generateFilebeatcertificates
    cert_generateDashboardcertificates
    cert_cleanFiles
}

test-34-installCommon_createCertificates-no-aio() {
    load-installCommon_createCertificates
    base_path=/tmp
    installCommon_createCertificates
}

test-34-installCommon_createCertificates-no-aio-assert() {

    cert_readConfig

    mkdir /tmp/certs

    cert_generateRootCAcertificate
    cert_generateAdmincertificate
    cert_generateIndexercertificates
    cert_generateFilebeatcertificates
    cert_generateDashboardcertificates
    cert_cleanFiles
}

function load-installCommon_changePasswords() {
    @load_function "${base_dir}/installCommon.sh" installCommon_changePasswords
}

test-ASSERT-FAIL-35-installCommon_changePasswords-no-tarfile() {
    load-installCommon_changePasswords
    tar_file=
    installCommon_changePasswords
}

test-36-installCommon_changePasswords-with-tarfile() {
    load-installCommon_changePasswords
    tar_file=tarfile.tar
    base_path=/tmp
    @touch $tar_file
    @mock tar -xf tarfile.tar -C /tmp cyware-install-files/cyware-passwords.txt === @touch /tmp/cyware-passwords.txt
    installCommon_changePasswords
    @echo $changeall
    @rm /tmp/cyware-passwords.txt
}

test-36-installCommon_changePasswords-with-tarfile-assert() {
    common_checkInstalled
    installCommon_readPasswordFileUsers
    passwords_changePassword
    rm -rf /tmp/cyware-passwords.txt
    @echo
}

test-37-installCommon_changePasswords-with-tarfile-aio() {
    load-installCommon_changePasswords
    tar_file=tarfile.tar
    base_path=/tmp
    AIO=1
    @touch $tar_file
    @mock tar -xf tarfile.tar -C /tmp cyware-install-files/cyware-passwords.txt === @touch /tmp/cyware-passwords.txt
    installCommon_changePasswords
    @echo $changeall
    @rm /tmp/cyware-passwords.txt
}

test-37-installCommon_changePasswords-with-tarfile-aio-assert() {
    common_checkInstalled
    passwords_readUsers
    installCommon_readPasswordFileUsers
    passwords_getNetworkHost
    passwords_createBackUp
    passwords_generateHash
    passwords_changePassword
    passwords_runSecurityAdmin
    rm -rf /tmp/cyware-passwords.txt
    @echo 1
}

test-38-installCommon_changePasswords-with-tarfile-start-elastic-cluster() {
    load-installCommon_changePasswords
    tar_file=tarfile.tar
    base_path=/tmp
    AIO=1
    @touch $tar_file
    @mock tar -xf tarfile.tar -C /tmp cyware-install-files/cyware-passwords.txt === @touch /tmp/cyware-passwords.txt
    installCommon_changePasswords
    @echo $changeall
    @rm /tmp/cyware-passwords.txt
}

test-38-installCommon_changePasswords-with-tarfile-start-elastic-cluster-assert() {
    common_checkInstalled
    passwords_readUsers
    installCommon_readPasswordFileUsers
    passwords_getNetworkHost
    passwords_createBackUp
    passwords_generateHash
    passwords_changePassword
    passwords_runSecurityAdmin
    rm -rf /tmp/cyware-passwords.txt
    @echo 1
}

function load-installCommon_getPass() {
    @load_function "${base_dir}/installCommon.sh" installCommon_getPass
}

test-39-installCommon_getPass-no-args() {
    load-installCommon_getPass
    users=(kibanaserver admin)
    passwords=(kibanaserver_pass admin_pass)
    installCommon_getPass
    @echo $u_pass
}

test-39-installCommon_getPass-no-args-assert() {
    @echo
}

test-40-installCommon_getPass-admin() {
    load-installCommon_getPass
    users=(kibanaserver admin)
    passwords=(kibanaserver_pass admin_pass)
    installCommon_getPass admin
    @echo $u_pass
}

test-40-installCommon_getPass-admin-assert() {
    @echo admin_pass
}

function load-installCommon_startService() {
    @load_function "${base_dir}/installCommon.sh" installCommon_startService
}

test-ASSERT-FAIL-41-installCommon_startService-no-args() {
    load-installCommon_startService
    installCommon_startService
}

test-ASSERT-FAIL-42-installCommon_startService-no-service-manager() {
    load-installCommon_startService
    @mockfalse ps -e
    @mockfalse grep -E -q "^\ *1\ .*systemd$"
    @mockfalse grep -E -q "^\ *1\ .*init$"
    @rm /etc/init.d/cyware
    installCommon_startService cyware-manager
}

test-43-installCommon_startService-systemd() {
    load-installCommon_startService
    @mockfalse ps -e === @out
    @mocktrue grep -E -q "^\ *1\ .*systemd$"
    @mockfalse grep -E -q "^\ *1\ .*init$"
    installCommon_startService cyware-manager
}

test-43-installCommon_startService-systemd-assert() {
    systemctl daemon-reload
    systemctl enable cyware-manager.service
    systemctl start cyware-manager.service
}

test-44-installCommon_startService-systemd-error() {
    load-installCommon_startService
    @mock ps -e === @out
    @mocktrue grep -E -q "^\ *1\ .*systemd$"
    @mockfalse grep -E -q "^\ *1\ .*init$"
    @mockfalse systemctl start cyware-manager.service
    installCommon_startService cyware-manager
}

test-44-installCommon_startService-systemd-error-assert() {
    systemctl daemon-reload
    systemctl enable cyware-manager.service
    installCommon_rollBack
    exit 1
}

test-45-installCommon_startService-initd() {
    load-installCommon_startService
    @mock ps -e === @out
    @mockfalse grep -E -q "^\ *1\ .*systemd$"
    @mocktrue grep -E -q "^\ *1\ .*init$"
    @mkdir -p /etc/init.d
    @touch /etc/init.d/cyware-manager
    @chmod +x /etc/init.d/cyware-manager
    installCommon_startService cyware-manager
    @rm /etc/init.d/cyware-manager
}

test-45-installCommon_startService-initd-assert() {
    @mkdir -p /etc/init.d
    @touch /etc/init.d/cyware-manager
    chkconfig cyware-manager on
    service cyware-manager start
    /etc/init.d/cyware-manager start
    @rm /etc/init.d/cyware-manager
}

test-46-installCommon_startService-initd-error() {
    load-installCommon_startService
    @mock ps -e === @out
    @mockfalse grep -E -q "^\ *1\ .*systemd$"
    @mocktrue grep -E -q "^\ *1\ .*init$"
    @mkdir -p /etc/init.d
    @touch /etc/init.d/cyware-manager
    #/etc/init.d/cyware-manager is not executable -> It will fail
    installCommon_startService cyware-manager
    @rm /etc/init.d/cyware-manager
}

test-46-installCommon_startService-initd-error-assert() {
    @mkdir -p /etc/init.d
    @touch /etc/init.d/cyware-manager
    @chmod +x /etc/init.d/cyware-manager
    chkconfig cyware-manager on
    service cyware-manager start
    /etc/init.d/cyware-manager start
    installCommon_rollBack
    exit 1
    @rm /etc/init.d/cyware-manager
}

test-47-installCommon_startService-rc.d/init.d() {
    load-installCommon_startService
    @mock ps -e === @out
    @mockfalse grep -E -q "^\ *1\ .*systemd$"
    @mockfalse grep -E -q "^\ *1\ .*init$"

    @mkdir -p /etc/rc.d/init.d
    @touch /etc/rc.d/init.d/cyware-manager
    @chmod +x /etc/rc.d/init.d/cyware-manager

    installCommon_startService cyware-manager
    @rm /etc/rc.d/init.d/cyware-manager
}

test-47-installCommon_startService-rc.d/init.d-assert() {
    @mkdir -p /etc/rc.d/init.d
    @touch /etc/rc.d/init.d/cyware-manager
    @chmod +x /etc/rc.d/init.d/cyware-manager
    /etc/rc.d/init.d/cyware-manager start
    @rm /etc/rc.d/init.d/cyware-manager
}

function load-installCommon_readPasswordFileUsers() {
    @load_function "${base_dir}/installCommon.sh" installCommon_readPasswordFileUsers
}

test-ASSERT-FAIL-48-installCommon_readPasswordFileUsers-file-incorrect() {
    load-installCommon_readPasswordFileUsers
    p_file=/tmp/passfile.yml
    @mock grep -Pzc '\A(User:\s*name:\s*\w+\s*password:\s*[A-Za-z0-9_\-]+\s*)+\Z' /tmp/passfile.yml === @echo 0
    installCommon_readPasswordFileUsers
}

test-49-installCommon_readPasswordFileUsers-changeall-correct() {
    load-installCommon_readPasswordFileUsers
    p_file=/tmp/passfile.yml
    @mock grep -Pzc '\A(User:\s*name:\s*\w+\s*password:\s*[A-Za-z0-9_\-]+\s*)+\Z' /tmp/passfile.yml === @echo 1
    @mock grep name: /tmp/passfile.yml === @echo cyware kibanaserver
    @mock awk '{ print substr( $2, 1, length($2) ) }'
    @mock grep password: /tmp/passfile.yml === @echo cywarepassword kibanaserverpassword
    @mock awk '{ print substr( $2, 1, length($2) ) }'
    changeall=1
    users=( cyware kibanaserver )
    installCommon_readPasswordFileUsers
    @echo ${fileusers[*]}
    @echo ${filepasswords[*]}
    @echo ${users[*]}
    @echo ${passwords[*]}
}

test-49-installCommon_readPasswordFileUsers-changeall-correct-assert() {
    @echo cyware kibanaserver
    @echo cywarepassword kibanaserverpassword
    @echo cyware kibanaserver
    @echo cywarepassword kibanaserverpassword
}

test-50-installCommon_readPasswordFileUsers-changeall-user-doesnt-exist() {
    load-installCommon_readPasswordFileUsers
    p_file=/tmp/passfile.yml
    @mock grep -Pzc '\A(User:\s*name:\s*\w+\s*password:\s*[A-Za-z0-9_\-]+\s*)+\Z' /tmp/passfile.yml === @echo 1
    @mock grep name: /tmp/passfile.yml === @out cyware kibanaserver admin
    @mock awk '{ print substr( $2, 1, length($2) ) }'
    @mock grep password: /tmp/passfile.yml === @out cywarepassword kibanaserverpassword
    @mock awk '{ print substr( $2, 1, length($2) ) }'
    changeall=1
    users=( cyware kibanaserver )
    installCommon_readPasswordFileUsers
    @echo ${fileusers[*]}
    @echo ${filepasswords[*]}
    @echo ${users[*]}
    @echo ${passwords[*]}
}

test-50-installCommon_readPasswordFileUsers-changeall-user-doesnt-exist-assert() {
    @echo cyware kibanaserver admin
    @echo cywarepassword kibanaserverpassword
    @echo cyware kibanaserver
    @echo cywarepassword kibanaserverpassword
}

test-51-installCommon_readPasswordFileUsers-no-changeall-kibana-correct() {
    load-installCommon_readPasswordFileUsers
    p_file=/tmp/passfile.yml
    @mock grep -Pzc '\A(User:\s*name:\s*\w+\s*password:\s*[A-Za-z0-9_\-]+\s*)+\Z' /tmp/passfile.yml === @echo 1
    @mock grep name: /tmp/passfile.yml === @out cyware kibanaserver admin
    @mock awk '{ print substr( $2, 1, length($2) ) }'
    @mock grep password: /tmp/passfile.yml === @out cywarepassword kibanaserverpassword adminpassword
    @mock awk '{ print substr( $2, 1, length($2) ) }'
    changeall=
    dashboard_installed=1
    dashboard=1
    installCommon_readPasswordFileUsers
    @echo ${fileusers[*]}
    @echo ${filepasswords[*]}
    @echo ${users[*]}
    @echo ${passwords[*]}
}

test-51-installCommon_readPasswordFileUsers-no-changeall-kibana-correct-assert() {
    @echo cyware kibanaserver admin
    @echo cywarepassword kibanaserverpassword adminpassword
    @echo kibanaserver admin
    @echo kibanaserverpassword adminpassword
}

test-52-installCommon_readPasswordFileUsers-no-changeall-filebeat-correct() {
    load-installCommon_readPasswordFileUsers
    p_file=/tmp/passfile.yml
    @mock grep -Pzc '\A(User:\s*name:\s*\w+\s*password:\s*[A-Za-z0-9_\-]+\s*)+\Z' /tmp/passfile.yml === @echo 1
    @mock grep name: /tmp/passfile.yml === @out cyware kibanaserver admin
    @mock awk '{ print substr( $2, 1, length($2) ) }'
    @mock grep password: /tmp/passfile.yml === @out cywarepassword kibanaserverpassword adminpassword
    @mock awk '{ print substr( $2, 1, length($2) ) }'
    changeall=
    filebeat_installed=1
    cyware=1
    installCommon_readPasswordFileUsers
    @echo ${fileusers[*]}
    @echo ${filepasswords[*]}
    @echo ${users[*]}
    @echo ${passwords[*]}
}

test-52-installCommon_readPasswordFileUsers-no-changeall-filebeat-correct-assert() {
    @echo cyware kibanaserver admin
    @echo cywarepassword kibanaserverpassword adminpassword
    @echo admin
    @echo adminpassword
}

