# Cyware installer - indexer.sh functions.
# Copyright (C) 2015, KhulnaSoft Ltd.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

function indexer_configure() {

    common_logger -d "Configuring Cyware indexer."
    eval "export JAVA_HOME=/usr/share/cyware-indexer/jdk/"

    # Configure JVM options for Cyware indexer
    ram_mb=$(free -m | awk '/^Mem:/{print $2}')
    ram="$(( ram_mb / 2 ))"

    if [ "${ram}" -eq "0" ]; then
        ram=1024;
    fi
    eval "sed -i "s/-Xms1g/-Xms${ram}m/" /etc/cyware-indexer/jvm.options ${debug}"
    eval "sed -i "s/-Xmx1g/-Xmx${ram}m/" /etc/cyware-indexer/jvm.options ${debug}"

    if [ -n "${AIO}" ]; then
        eval "installCommon_getConfig indexer/indexer_all_in_one.yml /etc/cyware-indexer/opensearch.yml ${debug}"
    else
        eval "installCommon_getConfig indexer/indexer_unattended_distributed.yml /etc/cyware-indexer/opensearch.yml ${debug}"
        if [ "${#indexer_node_names[@]}" -eq 1 ]; then
            pos=0
            {
            echo "node.name: ${indxname}"
            echo "network.host: ${indexer_node_ips[0]}"
            echo "cluster.initial_master_nodes: ${indxname}"
            echo "plugins.security.nodes_dn:"
            echo '        - CN='"${indxname}"',OU=Cyware,O=Cyware,L=California,C=US'
            } >> /etc/cyware-indexer/opensearch.yml
        else
            echo "node.name: ${indxname}" >> /etc/cyware-indexer/opensearch.yml
            echo "cluster.initial_master_nodes:" >> /etc/cyware-indexer/opensearch.yml
            for i in "${indexer_node_names[@]}"; do
                echo "        - ${i}" >> /etc/cyware-indexer/opensearch.yml
            done

            echo "discovery.seed_hosts:" >> /etc/cyware-indexer/opensearch.yml
            for i in "${indexer_node_ips[@]}"; do
                echo "        - ${i}" >> /etc/cyware-indexer/opensearch.yml
            done

            for i in "${!indexer_node_names[@]}"; do
                if [[ "${indexer_node_names[i]}" == "${indxname}" ]]; then
                    pos="${i}";
                fi
            done

            echo "network.host: ${indexer_node_ips[pos]}" >> /etc/cyware-indexer/opensearch.yml

            echo "plugins.security.nodes_dn:" >> /etc/cyware-indexer/opensearch.yml
            for i in "${indexer_node_names[@]}"; do
                    echo "        - CN=${i},OU=Cyware,O=Cyware,L=California,C=US" >> /etc/cyware-indexer/opensearch.yml
            done
        fi
    fi

    indexer_copyCertificates

    jv=$(java -version 2>&1 | grep -o -m1 '1.8.0' )
    if [ "$jv" == "1.8.0" ]; then
        {
        echo "cyware-indexer hard nproc 4096"
        echo "cyware-indexer soft nproc 4096"
        echo "cyware-indexer hard nproc 4096"
        echo "cyware-indexer soft nproc 4096"
        } >> /etc/security/limits.conf
        echo -ne "\nbootstrap.system_call_filter: false" >> /etc/cyware-indexer/opensearch.yml
    fi

    common_logger "Cyware indexer post-install configuration finished."
}

function indexer_copyCertificates() {

    common_logger -d "Copying Cyware indexer certificates."
    eval "rm -f ${indexer_cert_path}/* ${debug}"
    name=${indexer_node_names[pos]}

    if [ -f "${tar_file}" ]; then
        if ! tar -tvf "${tar_file}" | grep -q "${name}" ; then
            common_logger -e "Tar file does not contain certificate for the node ${name}."
            installCommon_rollBack
            exit 1;
        fi
        eval "mkdir ${indexer_cert_path} ${debug}"
        eval "sed -i s/indexer.pem/${name}.pem/ /etc/cyware-indexer/opensearch.yml ${debug}"
        eval "sed -i s/indexer-key.pem/${name}-key.pem/ /etc/cyware-indexer/opensearch.yml ${debug}"
        eval "tar -xf ${tar_file} -C ${indexer_cert_path} cyware-install-files/${name}.pem --strip-components 1 ${debug}"
        eval "tar -xf ${tar_file} -C ${indexer_cert_path} cyware-install-files/${name}-key.pem --strip-components 1 ${debug}"
        eval "tar -xf ${tar_file} -C ${indexer_cert_path} cyware-install-files/root-ca.pem --strip-components 1 ${debug}"
        eval "tar -xf ${tar_file} -C ${indexer_cert_path} cyware-install-files/admin.pem --strip-components 1 ${debug}"
        eval "tar -xf ${tar_file} -C ${indexer_cert_path} cyware-install-files/admin-key.pem --strip-components 1 ${debug}"
        eval "rm -rf ${indexer_cert_path}/cyware-install-files/ ${debug}"
        eval "chown -R cyware-indexer:cyware-indexer ${indexer_cert_path} ${debug}"
        eval "chmod 500 ${indexer_cert_path} ${debug}"
        eval "chmod 400 ${indexer_cert_path}/* ${debug}"
    else
        common_logger -e "No certificates found. Could not initialize Cyware indexer"
        installCommon_rollBack
        exit 1;
    fi

}

function indexer_initialize() {

    common_logger "Initializing Cyware indexer cluster security settings."
    eval "common_curl -XGET https://"${indexer_node_ips[pos]}":9200/ -uadmin:admin -k --max-time 120 --silent --output /dev/null"
    e_code="${PIPESTATUS[0]}"

    if [ "${e_code}" -ne "0" ]; then
        common_logger -e "Cannot initialize Cyware indexer cluster."
        installCommon_rollBack
        exit 1
    fi

    if [ -n "${AIO}" ]; then
        eval "sudo -u cyware-indexer JAVA_HOME=/usr/share/cyware-indexer/jdk/ OPENSEARCH_CONF_DIR=/etc/cyware-indexer /usr/share/cyware-indexer/plugins/opensearch-security/tools/securityadmin.sh -cd /etc/cyware-indexer/opensearch-security -icl -p 9200 -nhnv -cacert ${indexer_cert_path}/root-ca.pem -cert ${indexer_cert_path}/admin.pem -key ${indexer_cert_path}/admin-key.pem -h 127.0.0.1 ${debug}"
        eval "bash /usr/share/cyware-indexer/bin/indexer-ism-init.sh ${debug}"
        if [  "${PIPESTATUS[0]}" != 0  ]; then
            common_logger -w "The Cyware indexer cluster ISM policy could not be created."
        else
            common_logger "The Cyware indexer cluster ISM initialized."
        fi
    fi

    if [ "${#indexer_node_names[@]}" -eq 1 ] && [ -z "${AIO}" ]; then
        installCommon_changePasswords
    fi

    common_logger "Cyware indexer cluster initialized."

}

function indexer_install() {

    common_logger "Starting Cyware indexer installation."

    if [ "${sys_type}" == "yum" ]; then
        eval "yum install cyware-indexer-${cyware_version} -y ${debug}"
        install_result="${PIPESTATUS[0]}"
    elif [ "${sys_type}" == "apt-get" ]; then
        installCommon_aptInstall "cyware-indexer" "${cyware_version}-*"
    fi

    common_checkInstalled
    if [  "$install_result" != 0  ] || [ -z "${indexer_installed}" ]; then
        common_logger -e "Cyware indexer installation failed."
        installCommon_rollBack
        exit 1
    else
        common_logger "Cyware indexer installation finished."
    fi

    eval "sysctl -q -w vm.max_map_count=262144 ${debug}"

}

function indexer_startCluster() {

    common_logger -d "Starting Cyware indexer cluster."
    for ip_to_test in "${indexer_node_ips[@]}"; do
        eval "common_curl -XGET https://"${ip_to_test}":9200/ -k -s -o /dev/null"
        e_code="${PIPESTATUS[0]}"

        if [ "${e_code}" -eq "7" ]; then
            common_logger -e "Connectivity check failed on node ${ip_to_test} port 9200. Possible causes: Cyware indexer not installed on the node, the Cyware indexer service is not running or you have connectivity issues with that node. Please check this before trying again."
            exit 1
        fi
    done

    eval "cyware_indexer_ip=( $(cat /etc/cyware-indexer/opensearch.yml | grep network.host | sed 's/network.host:\s//') )"
    eval "sudo -u cyware-indexer JAVA_HOME=/usr/share/cyware-indexer/jdk/ OPENSEARCH_CONF_DIR=/etc/cyware-indexer /usr/share/cyware-indexer/plugins/opensearch-security/tools/securityadmin.sh -cd /etc/cyware-indexer/opensearch-security -icl -p 9200 -nhnv -cacert /etc/cyware-indexer/certs/root-ca.pem -cert /etc/cyware-indexer/certs/admin.pem -key /etc/cyware-indexer/certs/admin-key.pem -h ${cyware_indexer_ip} ${debug}"
    if [  "${PIPESTATUS[0]}" != 0  ]; then
        common_logger -e "The Cyware indexer cluster security configuration could not be initialized."
        exit 1
    else
        common_logger "Cyware indexer cluster security configuration initialized."
        eval "bash /usr/share/cyware-indexer/bin/indexer-ism-init.sh -i ${cyware_indexer_ip} ${debug}"
        if [  "${PIPESTATUS[0]}" != 0  ]; then
            common_logger -w "The Cyware indexer cluster ISM policy could not be created."
        else
            common_logger "The Cyware indexer cluster ISM initialized."
        fi
    fi
    eval "common_curl --silent ${filebeat_cyware_template} --max-time 300 --retry 5 --retry-delay 5 ${debug}" | eval "common_curl -X PUT 'https://${indexer_node_ips[pos]}:9200/_template/cyware' -H 'Content-Type: application/json' -d @- -uadmin:admin -k --silent --max-time 300 --retry 5 --retry-delay 5 ${debug}"
    if [  "${PIPESTATUS[0]}" != 0  ]; then
        common_logger -e "The cyware-alerts template could not be inserted into the Cyware indexer cluster."
        exit 1
    else
        common_logger -d "Inserted cyware-alerts template into the Cyware indexer cluster."
    fi

}