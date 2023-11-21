#!/usr/bin/env bash
set -euo pipefail
base_dir="$(cd "$(dirname "$BASH_SOURCE")"; pwd -P; cd - >/dev/null;)"
source "${base_dir}"/bach.sh

@setup-test {
    @ignore common_logger
    k_certs_path="/etc/cyware-dashboard/certs/"
    cyware_version="4.9.0"
    elasticsearch_oss_version="7.10.2"
    cyware_kibana_plugin_revision="1"
    repobaseurl="https://packages.cyware.khulnasoft.com/4.x"
    kibana_cyware_plugin="${repobaseurl}/ui/kibana/cyware_kibana-${cyware_version}_${elasticsearch_oss_version}-${cyware_kibana_plugin_revision}.zip"
}

function load-dashboard_copyCertificates() {
    @load_function "${base_dir}/dashboard.sh" dashboard_copyCertificates
    dashboard_cert_path="/etc/cyware-dashboard/certs/"
}

test-ASSERT-FAIL-01-dashboard_copyCertificates-no-tarfile() {
    load-dashboard_copyCertificates
    tar_file=/tmp/tarfile.tar
    if [ -f ${tar_file} ]; then
        @rm ${tar_file}
    fi
    dashboard_copyCertificates
}

test-02-dashboard_copyCertificates() {
    load-dashboard_copyCertificates
    tar_file=/tmp/tarfile.tar
    @touch ${tar_file}
    pos=0
    dashboard_node_names=("dashboard1" "dashboard2")
    debug=
    dashboard_copyCertificates
}

test-02-dashboard_copyCertificates-assert() {
    rm -f /etc/cyware-dashboard/certs/*
    tar -xf /tmp/tarfile.tar -C /etc/cyware-dashboard/certs/ ./dashboard1.pem  && mv /etc/cyware-dashboard/certs/dashboard1.pem /etc/cyware-dashboard/certs/dashboard.pem
    tar -xf /tmp/tarfile.tar -C /etc/cyware-dashboard/certs/ ./dashboard1-key.pem  && mv /etc/cyware-dashboard/certs/dashboard1-key.pem /etc/cyware-dashboard/certs/dashboard-key.pem
    tar -xf /tmp/tarfile.tar -C /etc/cyware-dashboard/certs/ ./root-ca.pem
    chown -R cyware-dashboard:cyware-dashboard /etc/cyware-dashboard/
    chmod -R 500 /etc/cyware-dashboard/certs/
    chmod 440 /etc/cyware-dashboard/certs/*
}

function load-dashboard_install() {
    @load_function "${base_dir}/dashboard.sh" dashboard_install
}

test-03-dashboard_install-yum() {
    load-dashboard_install
    sys_type="yum"
    sep="-"
    cyware_version="4.9.0"
    cyware_revision="1"
    dashboard_install
}

test-03-dashboard_install-yum-assert() {
    yum install cyware-dashboard-1.13.2-1 -y
}

test-ASSERT-FAIL-04-dashboard_install-yum-error() {
    load-dashboard_install
    sys_type="yum"
    sep="-"
    cyware_version="4.9.0"
    cyware_revision="1"
    @mockfalse yum install cyware-dashboard-1.13.2-1 -y
    dashboard_install
}

test-05-dashboard_install-apt() {
    load-dashboard_install
    sys_type="apt-get"
    sep="="
    cyware_version="4.9.0"
    cyware_revision="1"
    dashboard_install
}

test-05-dashboard_install-apt-assert() {
    apt install cyware-dashboard=1.13.2-1 -y
}

test-ASSERT-FAIL-06-dashboard_install-apt-error() {
    load-dashboard_install
    sys_type="apt-get"
    sep="="
    cyware_version="4.9.0"
    cyware_revision="1"
    @mockfalse apt install cyware-dashboard=1.13.2-1 -y
    dashboard_install
}

function load-dashboard_configure() {
    @load_function "${base_dir}/dashboard.sh" dashboard_configure
}

test-07-dashboard_configure-dist-one-kibana-node-one-elastic-node() {
    load-dashboard_configure
    dashboard_node_names=("kibana1")
    dashboard_node_ips=("1.1.1.1")
    indexer_node_names=("elastic1")
    indexer_node_ips=("1.1.1.1")
    dashboard_configure
}

test-07-dashboard_configure-dist-one-kibana-node-one-elastic-node-assert() {
    dashboard_copyCertificates
    installCommon_getConfig dashboard/dashboard_unattended_distributed.yml /etc/cyware-dashboard/opensearch_dashboards.yml
}

test-08-dashboard_configure-dist-two-kibana-nodes-two-elastic-nodes() {
    load-dashboard_configure
    kiname="kibana2"
    dashboard_node_names=("kibana1" "kibana2")
    dashboard_node_ips=("1.1.1.1" "2.2.2.2")
    indexer_node_names=("elastic1" "elastic2")
    indexer_node_ips=("1.1.1.1" "2.2.2.2")
    dashboard_configure
}

test-08-dashboard_configure-dist-two-kibana-nodes-two-elastic-nodes-assert() {
    dashboard_copyCertificates
    installCommon_getConfig dashboard/dashboard_unattended_distributed.yml /etc/cyware-dashboard/opensearch_dashboards.yml
}

test-09-dashboard_configure-AIO() {
    load-dashboard_configure
    dashboard_node_names=("kibana1")
    dashboard_node_ips=("1.1.1.1")
    indexer_node_names=("elastic1")
    indexer_node_ips=("1.1.1.1")
    AIO=1
    dashboard_configure
}

test-09-dashboard_configure-AIO-assert() {
    dashboard_copyCertificates
    installCommon_getConfig dashboard/dashboard_unattended.yml /etc/cyware-dashboard/opensearch_dashboards.yml
}

function load-dashboard_initialize() {
    @load_function "${base_dir}/dashboard.sh" dashboard_initialize
}

test-10-dashboard_initialize-distributed-one-kibana-node-one-cyware-node-curl-correct() {
    load-dashboard_initialize
    dashboard_node_names=("kibana1")
    dashboard_node_ips=("1.1.1.1")
    u_pass="user_password"
    @mock curl -XGET https://1.1.1.1/status -uadmin:user_password -k -w %{http_code} -s -o /dev/null === @out "200"
    server_node_names=("cyware1")
    server_node_ips=("2.2.2.2")
    dashboard_initialize
}

test-10-dashboard_initialize-distributed-one-kibana-node-one-cyware-node-curl-correct-assert() {
    installCommon_getPass "admin"
    sed -i 's,url: https://localhost,url: https://2.2.2.2,g' /usr/share/cyware-dashboard/data/cyware/config/cyware.yml
}

test-ASSERT-FAIL-11-dashboard_initialize-distributed-one-kibana-node-one-cyware-node-curl-error() {
    load-dashboard_initialize
    dashboard_node_names=("kibana1")
    dashboard_node_ips=("1.1.1.1")
    u_pass="user_password"
    @mock curl -XGET https://1.1.1.1/status -uadmin:user_password -k -w %{http_code} -s -o /dev/null === @out "0"
    server_node_names=("cyware1")
    server_node_ips=("2.2.2.2")
    dashboard_initialize
}

test-12-dashboard_initialize-distributed-two-kibana-nodes-two-cyware-nodes-curl-correct() {
    load-dashboard_initialize
    dashboard_node_names=("kibana1" "kibana2")
    dashboard_node_ips=("1.1.1.1" "1.1.1.2")
    u_pass="user_password"
    @mock curl -XGET https://1.1.1.1/status -uadmin:user_password -k -w %{http_code} -s -o /dev/null === @out "200"
    server_node_names=("cyware1" "cyware2")
    server_node_types=("worker" "master")
    server_node_ips=("1.1.2.1" "1.1.2.2")
    dashboard_initialize
}

test-12-dashboard_initialize-distributed-two-kibana-nodes-two-cyware-nodes-curl-correct-assert() {
    installCommon_getPass "admin"
    sed -i 's,url: https://localhost,url: https://1.1.2.2,g' /usr/share/cyware-dashboard/data/cyware/config/cyware.yml
}

test-ASSERT-FAIL-13-dashboard_initialize-distributed-two-kibana-nodes-two-cyware-nodes-curl-error() {
    load-dashboard_initialize
    dashboard_node_names=("kibana1" "kibana2")
    dashboard_node_ips=("1.1.1.1" "1.1.1.2")
    u_pass="user_password"
    force=
    @mock curl -XGET https://1.1.1.1/status -uadmin:user_password -k -w %{http_code} -s -o /dev/null === @out "0"
    server_node_names=("cyware1" "cyware2")
    server_node_types=("worker" "master")
    server_node_ips=("1.1.2.1" "1.1.2.2")
    dashboard_initialize
}

test-14-dashboard_initialize-distributed-two-kibana-nodes-two-cyware-nodes-curl-error-force() {
    load-dashboard_initialize
    dashboard_node_names=("kibana1" "kibana2")
    dashboard_node_ips=("1.1.1.1" "1.1.1.2")
    u_pass="user_password"
    force=1
    @mock curl -XGET https://1.1.1.1/status -uadmin:user_password -k -w %{http_code} -s -o /dev/null === @out "0"
    server_node_names=("cyware1" "cyware2")
    server_node_types=("worker" "master")
    server_node_ips=("1.1.2.1" "1.1.2.2")
    dashboard_initialize
}

test-14-dashboard_initialize-distributed-two-kibana-nodes-two-cyware-nodes-curl-error-force-assert() {
    installCommon_getPass  admin
    sleep  10
    sleep  10
    sleep  10
    sleep  10
    sleep  10
    sleep  10
    sleep  10
    sleep  10
    sleep  10
    sleep  10
    sleep  10
    sleep  10
    sed  -i  's,url: https://localhost,url: https://1.1.2.2,g'  /usr/share/cyware-dashboard/data/cyware/config/cyware.yml
}

function load-dashboard_initializeAIO() {
    @load_function "${base_dir}/dashboard.sh" dashboard_initializeAIO
}

test-15-dashboard_initializeAIO-curl-correct() {
    load-dashboard_initializeAIO
    dashboard_node_names=("kibana1")
    dashboard_node_ips=("1.1.1.1")
    u_pass="user_password"
    @mock curl -XGET https://localhost/status -uadmin:user_password -k -w %{http_code} -s -o /dev/null === @out "200"
    dashboard_initializeAIO
}

test-15-dashboard_initializeAIO-curl-correct-assert() {
    installCommon_getPass "admin"
}


test-ASSERT-FAIL-16-dashboard_initializeAIO-curl-error() {
    load-dashboard_initializeAIO
    u_pass="user_password"
    @mock curl -XGET https://localhost/status -uadmin:user_password -k -w %{http_code} -s -o /dev/null === @out "0"
    dashboard_initializeAIO
}
