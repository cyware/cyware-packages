#!/usr/bin/env bash
set -euo pipefail
base_dir="$(cd "$(dirname "$BASH_SOURCE")"; pwd -P; cd - >/dev/null;)"
source "${base_dir}"/bach.sh

@setup-test {
    @ignore logger_cert
    debug_cert=
    base_path="/tmp/cyware-cert-tool"
}

function load-cert_cleanFiles() {
    @load_function "${base_dir}/cyware-cert-tool.sh" cert_cleanFiles
}

test-01-cert_cleanFiles() {
    load-cert_cleanFiles
    cert_cleanFiles
}

test-01-cert_cleanFiles-assert() {
    rm -f /tmp/cyware-cert-tool/certs/*.csr
    rm -f /tmp/cyware-cert-tool/certs/*.srl
    rm -f /tmp/cyware-cert-tool/certs/*.conf
    rm -f /tmp/cyware-cert-tool/certs/admin-key-temp.pem
}

function load-cert_checkOpenSSL() {
    @load_function "${base_dir}/cyware-cert-tool.sh" cert_checkOpenSSL
}

test-02-cert_checkOpenSSL-no-openssl() {
    load-cert_checkOpenSSL
    @mockfalse command -v openssl
    cert_checkOpenSSL
}

test-02-cert_checkOpenSSL-no-openssl-assert() {
    exit 1
}

test-03-cert_checkOpenSSL-correct() {
    load-cert_checkOpenSSL
    @mock command -v openssl === @out "/bin/openssl"
    cert_checkOpenSSL
    @assert-success
}

function load-cert_generateAdmincertificate() {
    @load_function "${base_dir}/cyware-cert-tool.sh" cert_generateAdmincertificate
}

test-04-cert_generateAdmincertificate() {
    load-cert_generateAdmincertificate
    cert_generateAdmincertificate
}

test-04-cert_generateAdmincertificate-assert() {
    openssl genrsa -out /tmp/cyware-cert-tool/certs/admin-key-temp.pem 2048
    openssl pkcs8 -inform PEM -outform PEM -in /tmp/cyware-cert-tool/certs/admin-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out /tmp/cyware-cert-tool/certs/admin-key.pem
    openssl req -new -key /tmp/cyware-cert-tool/certs/admin-key.pem -out /tmp/cyware-cert-tool/certs/admin.csr -batch -subj '/C=US/L=California/O=Cyware/OU=Docu/CN=admin'
    openssl x509 -days 3650 -req -in /tmp/cyware-cert-tool/certs/admin.csr -CA /tmp/cyware-cert-tool/certs/root-ca.pem -CAkey /tmp/cyware-cert-tool/certs/root-ca.key -CAcreateserial -sha256 -out /tmp/cyware-cert-tool/certs/admin.pem
}

function load-cert_generateCertificateconfiguration() {
    @load_function "${base_dir}/cyware-cert-tool.sh" cert_generateCertificateconfiguration
}

test-05-cert_generateCertificateconfiguration-IP() {
    load-cert_generateCertificateconfiguration
    @mkdir -p /tmp/cyware-cert-tool/certs
    @touch /tmp/cyware-cert-tool/certs/cyware1.conf
    @mock echo 1.1.1.1 === @out ""
    @mock awk '{sub("CN = cname", "CN = cyware1")}1' "/tmp/cyware-cert-tool/certs/cyware1.conf" === @out "conf"
    @mock awk "{sub(\"IP.1 = cip\", \"IP.1 = 1.1.1.1\")}1" "/tmp/cyware-cert-tool/certs/cyware1.conf" === @out "conf2"
    @mock grep -P "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" === @out "1.1.1.1"
    @mock grep -P "^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+$" === @out ""
    @mocktrue cat
    cert_generateCertificateconfiguration "cyware1" "1.1.1.1"
    @rm /tmp/cyware-cert-tool/certs/cyware1.conf
    @rmdir /tmp/cyware-cert-tool/certs
}

test-05-cert_generateCertificateconfiguration-IP-assert() {
    echo "conf"
    echo "conf2"
}

test-06-cert_generateCertificateconfiguration-DNS() {
    load-cert_generateCertificateconfiguration
    @mkdir -p /tmp/cyware-cert-tool/certs
    @touch /tmp/cyware-cert-tool/certs/cyware1.conf
    @mock echo 1.1.1.1 === @out ""
    @mock awk "{sub(\"CN = cname\", \"CN = cyware1\")}1" "/tmp/cyware-cert-tool/certs/cyware1.conf" === @out "conf"
    @mock awk "{sub(\"CN = cname\", \"CN =  1.1.1.1\")}1" "/tmp/cyware-cert-tool/certs/cyware1.conf" === @out "conf2"
    @mock awk "{sub(\"IP.1 = cip\", \"DNS.1 = 1.1.1.1\")}1" "/tmp/cyware-cert-tool/certs/cyware1.conf" === @out "conf3"
    @mock grep -P "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" === @out ""
    @mock grep -P "^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+$" === @out "1.1.1.1"
    @mocktrue cat
    cert_generateCertificateconfiguration "cyware1" "1.1.1.1"
    @rm /tmp/cyware-cert-tool/certs/cyware1.conf
    @rmdir /tmp/cyware-cert-tool/certs
}

test-06-cert_generateCertificateconfiguration-DNS-assert() {
    echo "conf"
    echo "conf2"
    echo "conf3"
}

test-07-cert_generateCertificateconfiguration-error() {
    load-cert_generateCertificateconfiguration
    @mkdir -p /tmp/cyware-cert-tool/certs
    @touch /tmp/cyware-cert-tool/certs/cyware1.conf
    @mock echo 1.1.1.1 === @out ""
    @mock awk "{sub(\"CN = cname\", \"CN = cyware1\")}1" "/tmp/cyware-cert-tool/certs/cyware1.conf" === @out "conf"
    @mock awk "{sub(\"CN = cname\", \"CN = 1.1.1.1\")}1" "/tmp/cyware-cert-tool/certs/cyware1.conf" === @out "conf2"
    @mock awk "{sub(\"IP.1 = cip\", \"DNS.1 = 1.1.1.1\")}1" "/tmp/cyware-cert-tool/certs/cyware1.conf" === @out "conf3"
    @mockfalse grep -P "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
    @mockfalse grep -P "^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+$"
    @mocktrue cat
    cert_generateCertificateconfiguration "cyware1" "1.1.1.1"
    @rm /tmp/cyware-cert-tool/certs/cyware1.conf
    @rmdir /tmp/cyware-cert-tool/certs
}

test-07-cert_generateCertificateconfiguration-error-assert() {
    echo "conf"
    exit 1
}


function load-cert_generateRootCAcertificate() {
    @load_function "${base_dir}/cyware-cert-tool.sh" cert_generateRootCAcertificate
}

test-08-cert_generateRootCAcertificate() {
    load-cert_generateRootCAcertificate
    cert_generateRootCAcertificate
}

test-08-cert_generateRootCAcertificate-assert() {
    openssl req -x509 -new -nodes -newkey rsa:2048 -keyout /tmp/cyware-cert-tool/certs/root-ca.key -out /tmp/cyware-cert-tool/certs/root-ca.pem -batch -subj '/OU=Docu/O=Cyware/L=California/' -days 3650
}

function load-generateElasticsearchcertificates() {
    @load_function "${base_dir}/cyware-cert-tool.sh" generateElasticsearchcertificates
}

test-09-generateElasticsearchcertificates-no-nodes() {
    load-generateElasticsearchcertificates
    indexer_node_names=()
    generateElasticsearchcertificates
    @assert-success
}

test-10-generateElasticsearchcertificates-two-nodes() {
    load-generateElasticsearchcertificates
    indexer_node_names=("elastic1" "elastic2")
    indexer_node_ips=("1.1.1.1" "1.1.1.2")
    generateElasticsearchcertificates
}

test-10-generateElasticsearchcertificates-two-nodes-assert() {
    cert_generateCertificateconfiguration elastic1 1.1.1.1
    openssl req -new -nodes -newkey rsa:2048 -keyout /tmp/cyware-cert-tool/certs/elastic1-key.pem -out /tmp/cyware-cert-tool/certs/elastic1.csr -config /tmp/cyware-cert-tool/certs/elastic1.conf -days 3650
    openssl x509 -req -in /tmp/cyware-cert-tool/certs/elastic1.csr -CA /tmp/cyware-cert-tool/certs/root-ca.pem -CAkey /tmp/cyware-cert-tool/certs/root-ca.key -CAcreateserial -out /tmp/cyware-cert-tool/certs/elastic1.pem -extfile /tmp/cyware-cert-tool/certs/elastic1.conf -extensions v3_req -days 3650
    chmod 444 /tmp/cyware-cert-tool/certs/elastic1-key.pem
    cert_generateCertificateconfiguration elastic2 1.1.1.2
    openssl req -new -nodes -newkey rsa:2048 -keyout /tmp/cyware-cert-tool/certs/elastic2-key.pem -out /tmp/cyware-cert-tool/certs/elastic2.csr -config /tmp/cyware-cert-tool/certs/elastic2.conf -days 3650
    openssl x509 -req -in /tmp/cyware-cert-tool/certs/elastic2.csr -CA /tmp/cyware-cert-tool/certs/root-ca.pem -CAkey /tmp/cyware-cert-tool/certs/root-ca.key -CAcreateserial -out /tmp/cyware-cert-tool/certs/elastic2.pem -extfile /tmp/cyware-cert-tool/certs/elastic2.conf -extensions v3_req -days 3650
    chmod 444 /tmp/cyware-cert-tool/certs/elastic2-key.pem

}

function load-cert_generateFilebeatcertificates() {
    @load_function "${base_dir}/cyware-cert-tool.sh" cert_generateFilebeatcertificates
}

test-11-cert_generateFilebeatcertificates-no-nodes() {
    load-cert_generateFilebeatcertificates
    server_node_names=()
    cert_generateFilebeatcertificates
    @assert-success
}

test-12-cert_generateFilebeatcertificates-two-nodes() {
    load-cert_generateFilebeatcertificates
    server_node_names=("cyware1" "cyware2")
    server_node_ips=("1.1.1.1" "1.1.1.2")
    cert_generateFilebeatcertificates
}

test-12-cert_generateFilebeatcertificates-two-nodes-assert() {
    cert_generateCertificateconfiguration "cyware1" "1.1.1.1"
    openssl req -new -nodes -newkey rsa:2048 -keyout /tmp/cyware-cert-tool/certs/cyware1-key.pem -out /tmp/cyware-cert-tool/certs/cyware1.csr -config /tmp/cyware-cert-tool/certs/cyware1.conf -days 3650
    openssl x509 -req -in /tmp/cyware-cert-tool/certs/cyware1.csr -CA /tmp/cyware-cert-tool/certs/root-ca.pem -CAkey /tmp/cyware-cert-tool/certs/root-ca.key -CAcreateserial -out /tmp/cyware-cert-tool/certs/cyware1.pem -extfile /tmp/cyware-cert-tool/certs/cyware1.conf -extensions v3_req -days 3650
    cert_generateCertificateconfiguration "cyware2" "1.1.1.2"
    openssl req -new -nodes -newkey rsa:2048 -keyout /tmp/cyware-cert-tool/certs/cyware2-key.pem -out /tmp/cyware-cert-tool/certs/cyware2.csr -config /tmp/cyware-cert-tool/certs/cyware2.conf -days 3650
    openssl x509 -req -in /tmp/cyware-cert-tool/certs/cyware2.csr -CA /tmp/cyware-cert-tool/certs/root-ca.pem -CAkey /tmp/cyware-cert-tool/certs/root-ca.key -CAcreateserial -out /tmp/cyware-cert-tool/certs/cyware2.pem -extfile /tmp/cyware-cert-tool/certs/cyware2.conf -extensions v3_req -days 3650

}

function load-generateKibanacertificates() {
    @load_function "${base_dir}/cyware-cert-tool.sh" generateKibanacertificates
}

test-13-generateKibanacertificates-no-nodes() {
    load-generateKibanacertificates
    kibana_node_names=()
    generateKibanacertificates
    @assert-success
}

test-14-generateKibanacertificates-two-nodes() {
    load-generateKibanacertificates
    kibana_node_names=("kibana1" "kibana2")
    kibana_node_ips=("1.1.1.1" "1.1.1.2")
    generateKibanacertificates
}

test-14-generateKibanacertificates-two-nodes-assert() {
    cert_generateCertificateconfiguration "kibana1" "1.1.1.1"
    openssl req -new -nodes -newkey rsa:2048 -keyout /tmp/cyware-cert-tool/certs/kibana1-key.pem -out /tmp/cyware-cert-tool/certs/kibana1.csr -config /tmp/cyware-cert-tool/certs/kibana1.conf -days 3650
    openssl x509 -req -in /tmp/cyware-cert-tool/certs/kibana1.csr -CA /tmp/cyware-cert-tool/certs/root-ca.pem -CAkey /tmp/cyware-cert-tool/certs/root-ca.key -CAcreateserial -out /tmp/cyware-cert-tool/certs/kibana1.pem -extfile /tmp/cyware-cert-tool/certs/kibana1.conf -extensions v3_req -days 3650
    chmod 444 /tmp/cyware-cert-tool/certs/kibana1-key.pem
    cert_generateCertificateconfiguration "kibana2" "1.1.1.2"
    openssl req -new -nodes -newkey rsa:2048 -keyout /tmp/cyware-cert-tool/certs/kibana2-key.pem -out /tmp/cyware-cert-tool/certs/kibana2.csr -config /tmp/cyware-cert-tool/certs/kibana2.conf -days 3650
    openssl x509 -req -in /tmp/cyware-cert-tool/certs/kibana2.csr -CA /tmp/cyware-cert-tool/certs/root-ca.pem -CAkey /tmp/cyware-cert-tool/certs/root-ca.key -CAcreateserial -out /tmp/cyware-cert-tool/certs/kibana2.pem -extfile /tmp/cyware-cert-tool/certs/kibana2.conf -extensions v3_req -days 3650
    chmod 444 /tmp/cyware-cert-tool/certs/kibana2-key.pem
}

function load-cert_readConfig() {
    @load_function "${base_dir}/cyware-cert-tool.sh" cert_readConfig
    config_file="${base_path}/config.yml"
}

test-ASSERT-FAIL-15-cert_readConfig-empty-file() {
    load-cert_readConfig
    @mkdir -p ${base_dir}
    @rm "${config_file}"
    @touch ${config_file}
    cert_readConfig
    @rm ${config_file}
}

test-ASSERT-FAIL-16-cert_readConfig-no-file() {
    load-cert_readConfig
    @rm "${config_file}"
    cert_readConfig
}

test-ASSERT-FAIL-17-cert_readConfig-duplicated-elastic-node-names() {
    load-cert_readConfig
    @mkdir -p "${base_path}"
    @touch "${config_file}"
    @echo "config_file" > "${config_file}"
    
    @mock cert_parseYaml /tmp/cyware-cert-tool/config.yml === @out
    @mock grep nodes_elasticsearch_name === @out "elastic1 elastic1 elastic2"
    @mock sed 's/nodes_elasticsearch_name=//'
    @mock grep nodes_cyware_servers_name === @out "cyware1 cyware2"
    @mock sed 's/nodes_cyware_servers_name=//'
    @mock grep nodes_kibana_name === @out "kibana1 kibana2"
    @mock sed 's/nodes_kibana_name=//'

    @mock grep nodes_elasticsearch_ip === @out "1.1.1.1 1.1.1.2 1.1.1.3"
    @mock sed 's/nodes_elasticsearch_ip=//'
    @mock grep nodes_cyware_servers_ip === @out "1.1.2.1 1.1.2.2"
    @mock sed 's/nodes_cyware_servers_ip=//'
    @mock grep nodes_kibana_ip === @out "1.1.3.1 1.1.3.2"
    @mock sed 's/nodes_kibana_ip=//'

    @mock grep nodes_cyware_servers_node_type === @out "worker master"
    @mock sed 's/nodes_cyware_servers_node_type=//'

    @mock tr ' ' '\n'
    @mock sort -u
    @mock tr '\n' ' '
    @mock echo elastic1 elastic1 elastic2 === @out "elastic1 elastic2"
    @mock echo 1.1.1.1 1.1.1.2 1.1.1.3 === @out "1.1.1.1 1.1.1.2 1.1.1.3"
    @mock echo cyware1 cyware2 === @out "cyware1 cyware2"
    @mock echo 1.1.2.1 1.1.2.2 === @out "1.1.2.1 1.1.2.2"
    @mock echo kibana1 kibana2 === @out "kibana1 kibana2"
    @mock echo 1.1.3.1 1.1.3.2 === @out "1.1.3.1 1.1.3.2"

    @mocktrue echo master
    @mocktrue echo worker
    @mocktrue grep -ioq master
    @mocktrue grep -ioq worker

    @mock wc -l
    @mock grep -io master === @out 1
    @mock grep -io worker === @out 1

    cert_readConfig
    @rm "${config_file}"
}

test-ASSERT-FAIL-18-cert_readConfig-duplicated-elastic-node-ips() {
    load-cert_readConfig
    @mkdir -p "${base_path}"
    @touch "${config_file}"
    @echo "config_file" > "${config_file}"
    
    @mock cert_parseYaml /tmp/cyware-cert-tool/config.yml === @out
    @mock grep nodes_elasticsearch_name === @out "elastic1 elastic2"
    @mock sed 's/nodes_elasticsearch_name=//'
    @mock grep nodes_cyware_servers_name === @out "cyware1 cyware2"
    @mock sed 's/nodes_cyware_servers_name=//'
    @mock grep nodes_kibana_name === @out "kibana1 kibana2"
    @mock sed 's/nodes_kibana_name=//'

    @mock grep nodes_elasticsearch_ip === @out "1.1.1.1 1.1.1.1"
    @mock sed 's/nodes_elasticsearch_ip=//'
    @mock grep nodes_cyware_servers_ip === @out "1.1.2.1 1.1.2.2"
    @mock sed 's/nodes_cyware_servers_ip=//'
    @mock grep nodes_kibana_ip === @out "1.1.3.1 1.1.3.2"
    @mock sed 's/nodes_kibana_ip=//'

    @mock grep nodes_cyware_servers_node_type === @out "worker master"
    @mock sed 's/nodes_cyware_servers_node_type=//'

    @mock tr ' ' '\n'
    @mock sort -u
    @mock tr '\n' ' '
    @mock echo elastic1 elastic2 === @out "elastic1 elastic2"
    @mock echo 1.1.1.1 1.1.1.1 === @out "1.1.1.1"
    @mock echo cyware1 cyware2 === @out "cyware1 cyware2"
    @mock echo 1.1.2.1 1.1.2.2 === @out "1.1.2.1 1.1.2.2"
    @mock echo kibana1 kibana2 === @out "kibana1 kibana2"
    @mock echo 1.1.3.1 1.1.3.2 === @out "1.1.3.1 1.1.3.2"

    @mocktrue echo master
    @mocktrue echo worker
    @mocktrue grep -ioq master
    @mocktrue grep -ioq worker

    @mock wc -l
    @mock grep -io master === @out 1
    @mock grep -io worker === @out 1
    
    cert_readConfig
    @rm "${config_file}"
}

test-ASSERT-FAIL-19-cert_readConfig-duplicated-cyware-node-names() {
    load-cert_readConfig
    @mkdir -p "${base_path}"
    @touch "${config_file}"
    @echo "config_file" > "${config_file}"
    
    @mock cert_parseYaml /tmp/cyware-cert-tool/config.yml === @out
    @mock grep nodes_elasticsearch_name === @out "elastic1 elastic2"
    @mock sed 's/nodes_elasticsearch_name=//'
    @mock grep nodes_cyware_servers_name === @out "cyware1 cyware2"
    @mock sed 's/nodes_cyware_servers_name=//'
    @mock grep nodes_kibana_name === @out "kibana1 kibana2"
    @mock sed 's/nodes_kibana_name=//'

    @mock grep nodes_elasticsearch_ip === @out "1.1.1.1 1.1.1.2"
    @mock sed 's/nodes_elasticsearch_ip=//'
    @mock grep nodes_cyware_servers_ip === @out "1.1.2.1 1.1.2.2"
    @mock sed 's/nodes_cyware_servers_ip=//'
    @mock grep nodes_kibana_ip === @out "1.1.3.1 1.1.3.2"
    @mock sed 's/nodes_kibana_ip=//'

    @mock grep nodes_cyware_servers_node_type === @out "worker master"
    @mock sed 's/nodes_cyware_servers_node_type=//'

    @mock tr ' ' '\n'
    @mock sort -u
    @mock tr '\n' ' '
    @mock echo elastic1 elastic2 === @out "elastic1 elastic2"
    @mock echo 1.1.1.1 1.1.1.2 === @out "1.1.1.1 1.1.1.2"
    @mock echo cyware1 cyware1 === @out "(cyware1)"
    @mock echo 1.1.2.1 1.1.2.2 === @out "1.1.2.1 1.1.2.2"
    @mock echo kibana1 kibana2 === @out "kibana1 kibana2"
    @mock echo 1.1.3.1 1.1.3.2 === @out "1.1.3.1 1.1.3.2"

    @mocktrue echo cyware1
    @mocktrue grep -ioq master
    @mocktrue grep -ioq worker

    @mock wc -l
    @mock grep -io master === @out 1
    @mock grep -io worker === @out 1
    
    cert_readConfig
    @rm "${config_file}"
}

test-ASSERT-FAIL-20-cert_readConfig-duplicated-cyware-node-ips() {
    load-cert_readConfig
    @mkdir -p "${base_path}"
    @touch "${config_file}"
    @echo "config_file" > "${config_file}"
    
    @mock cert_parseYaml /tmp/cyware-cert-tool/config.yml === @out
    @mock grep nodes_elasticsearch_name === @out "elastic1 elastic2"
    @mock sed 's/nodes_elasticsearch_name=//'
    @mock grep nodes_cyware_servers_name === @out "cyware1 cyware2"
    @mock sed 's/nodes_cyware_servers_name=//'
    @mock grep nodes_kibana_name === @out "kibana1 kibana2"
    @mock sed 's/nodes_kibana_name=//'

    @mock grep nodes_elasticsearch_ip === @out "1.1.1.1 1.1.1.2"
    @mock sed 's/nodes_elasticsearch_ip=//'
    @mock grep nodes_cyware_servers_ip === @out "1.1.2.1 1.1.2.1"
    @mock sed 's/nodes_cyware_servers_ip=//'
    @mock grep nodes_kibana_ip === @out "1.1.3.1 1.1.3.2"
    @mock sed 's/nodes_kibana_ip=//'

    @mock grep nodes_cyware_servers_node_type === @out "worker master"
    @mock sed 's/nodes_cyware_servers_node_type=//'

    @mock tr ' ' '\n'
    @mock sort -u
    @mock tr '\n' ' '
    @mock echo elastic1 elastic2 === @out "elastic1 elastic2"
    @mock echo 1.1.1.1 1.1.1.2 === @out "1.1.1.1 1.1.1.2"
    @mock echo cyware1 cyware2 === @out "cyware1 cyware2"
    @mock echo 1.1.2.1 1.1.2.1 === @out "1.1.2.1"
    @mock echo kibana1 kibana2 === @out "kibana1 kibana2"
    @mock echo 1.1.3.1 1.1.3.2 === @out "1.1.3.1 1.1.3.2"

    @mocktrue echo master
    @mocktrue echo worker
    @mocktrue grep -ioq master
    @mocktrue grep -ioq worker

    @mock wc -l
    @mock grep -io master === @out 1
    @mock grep -io worker === @out 1
    
    cert_readConfig
    @rm "${config_file}"
}

test-ASSERT-FAIL-21-cert_readConfig-duplicated-kibana-node-names() {
    load-cert_readConfig
    @mkdir -p "${base_path}"
    @touch "${config_file}"
    @echo "config_file" > "${config_file}"
    
    @mock cert_parseYaml /tmp/cyware-cert-tool/config.yml === @out
    @mock grep nodes_elasticsearch_name === @out "elastic1 elastic2"
    @mock sed 's/nodes_elasticsearch_name=//'
    @mock grep nodes_cyware_servers_name === @out "cyware1 cyware2"
    @mock sed 's/nodes_cyware_servers_name=//'
    @mock grep nodes_kibana_name === @out "kibana1 kibana1"
    @mock sed 's/nodes_kibana_name=//'

    @mock grep nodes_elasticsearch_ip === @out "1.1.1.1 1.1.1.2"
    @mock sed 's/nodes_elasticsearch_ip=//'
    @mock grep nodes_cyware_servers_ip === @out "1.1.2.1 1.1.2.1"
    @mock sed 's/nodes_cyware_servers_ip=//'
    @mock grep nodes_kibana_ip === @out "1.1.3.1 1.1.3.2"
    @mock sed 's/nodes_kibana_ip=//'

    @mock grep nodes_cyware_servers_node_type === @out "worker master"
    @mock sed 's/nodes_cyware_servers_node_type=//'

    @mock tr ' ' '\n'
    @mock sort -u
    @mock tr '\n' ' '
    @mock echo elastic1 elastic2 === @out "elastic1 elastic2"
    @mock echo 1.1.1.1 1.1.1.2 === @out "1.1.1.1 1.1.1.2"
    @mock echo cyware1 cyware2 === @out "cyware1 cyware2"
    @mock echo 1.1.2.1 1.1.2.1 === @out "(1.1.2.1)"
    @mock echo kibana1 kibana1 === @out "(kibana1)"
    @mock echo 1.1.3.1 1.1.3.2 === @out "1.1.3.1 1.1.3.2"

    @mocktrue echo master
    @mocktrue echo worker
    @mocktrue grep -ioq master
    @mocktrue grep -ioq worker

    @mock wc -l
    @mock grep -io master === @out 1
    @mock grep -io worker === @out 1
    
    cert_readConfig
    @rm "${config_file}"
}

test-ASSERT-FAIL-22-cert_readConfig-duplicated-kibana-node-ips() {
    load-cert_readConfig
    @mkdir -p "${base_path}"
    @touch "${config_file}"
    @echo "config_file" > "${config_file}"
    
    @mock cert_parseYaml /tmp/cyware-cert-tool/config.yml === @out
    @mock grep nodes_elasticsearch_name === @out "elastic1 elastic2"
    @mock sed 's/nodes_elasticsearch_name=//'
    @mock grep nodes_cyware_servers_name === @out "cyware1 cyware2"
    @mock sed 's/nodes_cyware_servers_name=//'
    @mock grep nodes_kibana_name === @out "kibana1 kibana2"
    @mock sed 's/nodes_kibana_name=//'

    @mock grep nodes_elasticsearch_ip === @out "1.1.1.1 1.1.1.2"
    @mock sed 's/nodes_elasticsearch_ip=//'
    @mock grep nodes_cyware_servers_ip === @out "1.1.2.1 1.1.2.1"
    @mock sed 's/nodes_cyware_servers_ip=//'
    @mock grep nodes_kibana_ip === @out "1.1.3.1 1.1.1.3.1"
    @mock sed 's/nodes_kibana_ip=//'

    @mock grep nodes_cyware_servers_node_type === @out "worker master"
    @mock sed 's/nodes_cyware_servers_node_type=//'

    @mock tr ' ' '\n'
    @mock sort -u
    @mock tr '\n' ' '
    @mock echo elastic1 elastic2 === @out "elastic1 elastic2"
    @mock echo 1.1.1.1 1.1.1.2 === @out "1.1.1.1 1.1.1.2"
    @mock echo cyware1 cyware2 === @out "cyware1 cyware2"
    @mock echo 1.1.2.1 1.1.2.1 === @out "1.1.2.1"
    @mock echo kibana1 kibana2 === @out "kibana1 kibana2"
    @mock echo 1.1.3.1 1.1.3.1 === @out "1.1.3.1"
    @mocktrue echo master
    @mocktrue echo worker
    @mocktrue grep -ioq master
    @mocktrue grep -ioq worker

    @mock wc -l
    @mock grep -io master === @out 1
    @mock grep -io worker === @out 1
    
    cert_readConfig
    @rm "${config_file}"
}

test-ASSERT-FAIL-23-cert_readConfig-different-number-of-cyware-names-and-ips() {
    load-cert_readConfig
    @mkdir -p "${base_path}"
    @touch "${config_file}"
    @echo "config_file" > "${config_file}"
    
    @mock cert_parseYaml /tmp/cyware-cert-tool/config.yml === @out
    @mock grep nodes_elasticsearch_name === @out "elastic1 elastic2"
    @mock sed 's/nodes_elasticsearch_name=//'
    @mock grep nodes_cyware_servers_name === @out "cyware1"
    @mock sed 's/nodes_cyware_servers_name=//'
    @mock grep nodes_kibana_name === @out "kibana1 kibana2"
    @mock sed 's/nodes_kibana_name=//'

    @mock grep nodes_elasticsearch_ip === @out "1.1.1.1 1.1.1.2"
    @mock sed 's/nodes_elasticsearch_ip=//'
    @mock grep nodes_cyware_servers_ip === @out "1.1.2.1 1.1.2.1"
    @mock sed 's/nodes_cyware_servers_ip=//'
    @mock grep nodes_kibana_ip === @out "1.1.3.1 1.1.3.2"
    @mock sed 's/nodes_kibana_ip=//'

    @mock grep nodes_cyware_servers_node_type === @out "worker master"
    @mock sed 's/nodes_cyware_servers_node_type=//'

    @mock tr ' ' '\n'
    @mock sort -u
    @mock tr '\n' ' '
    @mock echo elastic1 elastic2 === @out "elastic1 elastic2"
    @mock echo 1.1.1.1 1.1.1.2 === @out "1.1.1.1 1.1.1.2"
    @mock echo cyware1 === @out "(cyware1)"
    @mock echo 1.1.2.1 1.1.2.1 === @out "1.1.2.1"
    @mock echo kibana1 kibana2 === @out "kibana1 kibana2"
    @mock echo 1.1.3.1 1.1.3.2 === @out "1.1.3.1 1.1.3.2"

    @mocktrue echo cyware1
    @mocktrue grep -ioq master
    @mocktrue grep -ioq worker

    @mock wc -l
    @mock grep -io master === @out 1
    @mock grep -io worker === @out 1
    
    cert_readConfig
    @rm "${config_file}"
}

test-ASSERT-FAIL-24-cert_readConfig-incorrect-cyware-node-type() {
    load-cert_readConfig
    @mkdir -p "${base_path}"
    @touch "${config_file}"
    @echo "config_file" > "${config_file}"
    
    @mock cert_parseYaml /tmp/cyware-cert-tool/config.yml === @out
    @mock grep nodes_elasticsearch_name === @out "elastic1 elastic2"
    @mock sed 's/nodes_elasticsearch_name=//'
    @mock grep nodes_cyware_servers_name === @out "cyware1 cyware2"
    @mock sed 's/nodes_cyware_servers_name=//'
    @mock grep nodes_kibana_name === @out "kibana1 kibana2"
    @mock sed 's/nodes_kibana_name=//'

    @mock grep nodes_elasticsearch_ip === @out "1.1.1.1 1.1.1.2"
    @mock sed 's/nodes_elasticsearch_ip=//'
    @mock grep nodes_cyware_servers_ip === @out "1.1.2.1 1.1.2.1"
    @mock sed 's/nodes_cyware_servers_ip=//'
    @mock grep nodes_kibana_ip === @out "1.1.3.1 1.1.3.2"
    @mock sed 's/nodes_kibana_ip=//'

    @mock grep nodes_cyware_servers_node_type === @out "worker master"
    @mock sed 's/nodes_cyware_servers_node_type=//'

    @mock tr ' ' '\n'
    @mock sort -u
    @mock tr '\n' ' '
    @mock echo elastic1 elastic2 === @out "elastic1 elastic2"
    @mock echo 1.1.1.1 1.1.1.2 === @out "1.1.1.1 1.1.1.2"
    @mock echo cyware1 cyware2 === @out "cyware1 cyware2"
    @mock echo 1.1.2.1 1.1.2.1 === @out "1.1.2.1"
    @mock echo kibana1 kibana2 === @out "kibana1 kibana2"
    @mock echo 1.1.3.1 1.1.3.2 === @out "1.1.3.1 1.1.3.2"

    @mock echo cyware1
    @mock echo cyware2
    @mockfalse grep -ioq master
    @mockfalse grep -ioq worker

    @mock wc -l
    @mock grep -io master === @out 1
    @mock grep -io worker === @out 1
    
    cert_readConfig
    @rm "${config_file}"
}

test-ASSERT-FAIL-25-cert_readConfig-cyware-node-type-one-node() {
    load-cert_readConfig
    @mkdir -p "${base_path}"
    @touch "${config_file}"
    @echo "config_file" > "${config_file}"
    
    @mock cert_parseYaml /tmp/cyware-cert-tool/config.yml === @out
    @mock grep nodes_elasticsearch_name === @out "elastic1 elastic2"
    @mock sed 's/nodes_elasticsearch_name=//'
    @mock grep nodes_cyware_servers_name === @out "cyware1"
    @mock sed 's/nodes_cyware_servers_name=//'
    @mock grep nodes_kibana_name === @out "kibana1 kibana2"
    @mock sed 's/nodes_kibana_name=//'

    @mock grep nodes_elasticsearch_ip === @out "1.1.1.1 1.1.1.2"
    @mock sed 's/nodes_elasticsearch_ip=//'
    @mock grep nodes_cyware_servers_ip === @out "1.1.2.1"
    @mock sed 's/nodes_cyware_servers_ip=//'
    @mock grep nodes_kibana_ip === @out "1.1.3.1 1.1.3.2"
    @mock sed 's/nodes_kibana_ip=//'

    @mock grep nodes_cyware_servers_node_type === @out "master"
    @mock sed 's/nodes_cyware_servers_node_type=//'

    @mock tr ' ' '\n'
    @mock sort -u
    @mock tr '\n' ' '
    @mock echo elastic1 elastic2 === @out "elastic1 elastic2"
    @mock echo 1.1.1.1 1.1.1.2 === @out "1.1.1.1 1.1.1.2"
    @mock echo cyware1 === @out "cyware1"
    @mock echo 1.1.2.1 1.1.2.1 === @out "1.1.2.1"
    @mock echo kibana1 kibana2 === @out "kibana1 kibana2"
    @mock echo 1.1.3.1 1.1.3.2 === @out "1.1.3.1 1.1.3.2"

    @mock echo cyware1
    @mockfalse grep -ioq master
    @mockfalse grep -ioq worker

    @mock wc -l
    @mock grep -io master === @out 1
    @mock grep -io worker === @out 1
    
    cert_readConfig
    @rm "${config_file}"
}

test-ASSERT-FAIL-26-cert_readConfig-less-cyware-node-types-than-nodes() {
    load-cert_readConfig
    @mkdir -p "${base_path}"
    @touch "${config_file}"
    @echo "config_file" > "${config_file}"
    
    @mock cert_parseYaml /tmp/cyware-cert-tool/config.yml === @out
    @mock grep nodes_elasticsearch_name === @out "elastic1 elastic2"
    @mock sed 's/nodes_elasticsearch_name=//'
    @mock grep nodes_cyware_servers_name === @out "cyware1 cyware2"
    @mock sed 's/nodes_cyware_servers_name=//'
    @mock grep nodes_kibana_name === @out "kibana1 kibana2"
    @mock sed 's/nodes_kibana_name=//'

    @mock grep nodes_elasticsearch_ip === @out "1.1.1.1 1.1.1.2"
    @mock sed 's/nodes_elasticsearch_ip=//'
    @mock grep nodes_cyware_servers_ip === @out "1.1.2.1 1.1.2.2"
    @mock sed 's/nodes_cyware_servers_ip=//'
    @mock grep nodes_kibana_ip === @out "1.1.3.1 1.1.3.2"
    @mock sed 's/nodes_kibana_ip=//'

    @mock grep nodes_cyware_servers_node_type === @out "master"
    @mock sed 's/nodes_cyware_servers_node_type=//'

    @mock tr ' ' '\n'
    @mock sort -u
    @mock tr '\n' ' '
    @mock echo elastic1 elastic2 === @out "elastic1 elastic2"
    @mock echo 1.1.1.1 1.1.1.2 === @out "1.1.1.1 1.1.1.2"
    @mock echo cyware1 cyware2 === @out "cyware1 cyware2"
    @mock echo 1.1.2.1 1.1.2.2 === @out "1.1.2.1 1.1.2.2"
    @mock echo kibana1 kibana2 === @out "kibana1 kibana2"
    @mock echo 1.1.3.1 1.1.3.2 === @out "1.1.3.1 1.1.3.2"

    @mock echo cyware1
    @mock echo cyware2
    @mocktrue grep -ioq master
    @mocktrue grep -ioq worker

    @mock wc -l
    @mock grep -io master === @out 1
    @mock grep -io worker === @out 1
    
    cert_readConfig
    @rm "${config_file}"
}

test-ASSERT-FAIL-27-cert_readConfig-different-number-of-kibana-names-and-ips() {
    load-cert_readConfig
    @mkdir -p "${base_path}"
    @touch "${config_file}"
    @echo "config_file" > "${config_file}"
    
    @mock cert_parseYaml /tmp/cyware-cert-tool/config.yml === @out
    @mock grep nodes_elasticsearch_name === @out "elastic1 elastic2"
    @mock sed 's/nodes_elasticsearch_name=//'
    @mock grep nodes_cyware_servers_name === @out "cyware1 cyware2"
    @mock sed 's/nodes_cyware_servers_name=//'
    @mock grep nodes_kibana_name === @out "kibana1 kibana2"
    @mock sed 's/nodes_kibana_name=//'

    @mock grep nodes_elasticsearch_ip === @out "1.1.1.1 1.1.1.2"
    @mock sed 's/nodes_elasticsearch_ip=//'
    @mock grep nodes_cyware_servers_ip === @out "1.1.2.1 1.1.2.2"
    @mock sed 's/nodes_cyware_servers_ip=//'
    @mock grep nodes_kibana_ip === @out "1.1.3.1 1.1.1.3.2 1.1.3.3"
    @mock sed 's/nodes_kibana_ip=//'

    @mock grep nodes_cyware_servers_node_type === @out "master worker"
    @mock sed 's/nodes_cyware_servers_node_type=//'

    @mock tr ' ' '\n'
    @mock sort -u
    @mock tr '\n' ' '
    @mock echo elastic1 elastic2 === @out "elastic1 elastic2"
    @mock echo 1.1.1.1 1.1.1.2 === @out "1.1.1.1 1.1.1.2"
    @mock echo cyware1 cyware2 === @out "cyware1 cyware2"
    @mock echo 1.1.2.1 1.1.2.2 === @out "1.1.2.1 1.1.2.2"
    @mock echo kibana1 kibana2 === @out "kibana1 kibana2"
    @mock echo 1.1.3.1 1.1.3.2 1.1.3.3=== @out "1.1.3.1 1.1.3.2 1.1.3.)"

    @mock echo cyware1
    @mock echo cyware2
    @mocktrue grep -ioq master
    @mocktrue grep -ioq worker

    @mock wc -l
    @mock grep -io master === @out 1
    @mock grep -io worker === @out 1

    cert_readConfig
    @rm "${config_file}"
}

test-28-cert_readConfig-everything-correct() {
    load-cert_readConfig
    @mkdir -p "${base_path}"
    @touch "${config_file}"
    @echo "config_file" > "${config_file}"
    
    @mock cert_parseYaml /tmp/cyware-cert-tool/config.yml === @out
    @mock grep nodes_elasticsearch_name === @out "elastic1 elastic2"
    @mock sed 's/nodes_elasticsearch_name=//'
    @mock grep nodes_cyware_servers_name === @out "cyware1 cyware2"
    @mock sed 's/nodes_cyware_servers_name=//'
    @mock grep nodes_kibana_name === @out "kibana1 kibana2"
    @mock sed 's/nodes_kibana_name=//'

    @mock grep nodes_elasticsearch_ip === @out "1.1.1.1 1.1.1.2"
    @mock sed 's/nodes_elasticsearch_ip=//'
    @mock grep nodes_cyware_servers_ip === @out "1.1.2.1 1.1.2.2"
    @mock sed 's/nodes_cyware_servers_ip=//'
    @mock grep nodes_kibana_ip === @out "1.1.3.1 1.1.3.2"
    @mock sed 's/nodes_kibana_ip=//'

    @mock grep nodes_cyware_servers_node_type === @out "master worker"
    @mock sed 's/nodes_cyware_servers_node_type=//'

    @mock tr ' ' '\n'
    @mock sort -u
    @mock tr '\n' ' '
    @mock echo elastic1 elastic2 === @out "elastic1 elastic2"
    @mock echo 1.1.1.1 1.1.1.2 === @out "1.1.1.1 1.1.1.2"
    @mock echo cyware1 cyware2 === @out "cyware1 cyware2"
    @mock echo 1.1.2.1 1.1.2.2 === @out "1.1.2.1 1.1.2.2"
    @mock echo kibana1 kibana2 === @out "kibana1 kibana2"
    @mock echo 1.1.3.1 1.1.3.2 === @out "1.1.3.1 1.1.3.2"

    @mocktrue echo "master"
    @mocktrue echo "worker"
    @mocktrue grep -ioq master
    @mocktrue grep -ioq worker

    @mock wc -l
    @mock grep -io master === @out 1
    @mock grep -io worker === @out 1

    cert_readConfig
    @rm "${config_file}"
    @echo "${indexer_node_names[@]}"
    @echo "${indexer_node_ips[@]}"
    @echo "${server_node_names[@]}"
    @echo "${server_node_ips[@]}"
    @echo "${kibana_node_names[@]}"
    @echo "${kibana_node_ips[@]}"
}

test-28-cert_readConfig-everything-correct-assert() {
    @echo elastic1 elastic2
    @echo 1.1.1.1 1.1.1.2
    @echo cyware1 cyware2
    @echo 1.1.2.1 1.1.2.2
    @echo kibana1 kibana2
    @echo 1.1.3.1 1.1.3.2
}
