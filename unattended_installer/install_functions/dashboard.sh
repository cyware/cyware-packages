# Cyware installer - dashboard.sh functions.
# Copyright (C) 2015, KhulnaSoft Ltd.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

function dashboard_changePort() {

    chosen_port="$1"
    http_port="${chosen_port}" 
    cyware_dashboard_ports=( "${http_port}" )
    cyware_aio_ports=(9200 9300 1514 1515 1516 55000 "${http_port}")

    sed -i 's/server\.port: [0-9]\+$/server.port: '"${chosen_port}"'/' "$0"
    common_logger "Cyware web interface port will be ${chosen_port}."
}

function dashboard_configure() {

    common_logger -d "Configuring Cyware dashboard."
    if [ -n "${AIO}" ]; then
        eval "installCommon_getConfig dashboard/dashboard_unattended.yml /etc/cyware-dashboard/opensearch_dashboards.yml ${debug}"
        dashboard_copyCertificates "${debug}"
    else
        eval "installCommon_getConfig dashboard/dashboard_unattended_distributed.yml /etc/cyware-dashboard/opensearch_dashboards.yml ${debug}"
        dashboard_copyCertificates "${debug}"
        if [ "${#dashboard_node_names[@]}" -eq 1 ]; then
            pos=0
            ip=${dashboard_node_ips[0]}
        else
            for i in "${!dashboard_node_names[@]}"; do
                if [[ "${dashboard_node_names[i]}" == "${dashname}" ]]; then
                    pos="${i}";
                fi
            done
            ip=${dashboard_node_ips[pos]}
        fi

        if [[ "${ip}" != "127.0.0.1" ]]; then
            echo "server.host: ${ip}" >> /etc/cyware-dashboard/opensearch_dashboards.yml
        else
            echo 'server.host: '0.0.0.0'' >> /etc/cyware-dashboard/opensearch_dashboards.yml
        fi

        if [ "${#indexer_node_names[@]}" -eq 1 ]; then
            echo "opensearch.hosts: https://${indexer_node_ips[0]}:9200" >> /etc/cyware-dashboard/opensearch_dashboards.yml
        else
            echo "opensearch.hosts:" >> /etc/cyware-dashboard/opensearch_dashboards.yml
            for i in "${indexer_node_ips[@]}"; do
                    echo "  - https://${i}:9200" >> /etc/cyware-dashboard/opensearch_dashboards.yml
            done
        fi
    fi

    sed -i 's/server\.port: [0-9]\+$/server.port: '"${chosen_port}"'/' /etc/cyware-dashboard/opensearch_dashboards.yml

    common_logger "Cyware dashboard post-install configuration finished."

}

function dashboard_copyCertificates() {

    common_logger -d "Copying Cyware dashboard certificates."
    eval "rm -f ${dashboard_cert_path}/* ${debug}"
    name=${dashboard_node_names[pos]}

    if [ -f "${tar_file}" ]; then
        if ! tar -tvf "${tar_file}" | grep -q "${name}" ; then
            common_logger -e "Tar file does not contain certificate for the node ${name}."
            installCommon_rollBack
            exit 1;
        fi
        eval "mkdir ${dashboard_cert_path} ${debug}"
        eval "sed -i s/dashboard.pem/${name}.pem/ /etc/cyware-dashboard/opensearch_dashboards.yml ${debug}"
        eval "sed -i s/dashboard-key.pem/${name}-key.pem/ /etc/cyware-dashboard/opensearch_dashboards.yml ${debug}"
        eval "tar -xf ${tar_file} -C ${dashboard_cert_path} cyware-install-files/${name}.pem --strip-components 1 ${debug}"
        eval "tar -xf ${tar_file} -C ${dashboard_cert_path} cyware-install-files/${name}-key.pem --strip-components 1 ${debug}"
        eval "tar -xf ${tar_file} -C ${dashboard_cert_path} cyware-install-files/root-ca.pem --strip-components 1 ${debug}"
        eval "chown -R cyware-dashboard:cyware-dashboard /etc/cyware-dashboard/ ${debug}"
        eval "chmod 500 ${dashboard_cert_path} ${debug}"
        eval "chmod 400 ${dashboard_cert_path}/* ${debug}"
        eval "chown cyware-dashboard:cyware-dashboard ${dashboard_cert_path}/* ${debug}"
        common_logger -d "Cyware dashboard certificate setup finished."
    else
        common_logger -e "No certificates found. Cyware dashboard  could not be initialized."
        exit 1
    fi

}

function dashboard_initialize() {

    common_logger "Initializing Cyware dashboard web application."
    installCommon_getPass "admin"
    j=0

    if [ "${#dashboard_node_names[@]}" -eq 1 ]; then
        nodes_dashboard_ip=${dashboard_node_ips[0]}
    else
        for i in "${!dashboard_node_names[@]}"; do
            if [[ "${dashboard_node_names[i]}" == "${dashname}" ]]; then
                pos="${i}";
            fi
        done
        nodes_dashboard_ip=${dashboard_node_ips[pos]}
    fi

    if [ "${nodes_dashboard_ip}" == "localhost" ] || [[ "${nodes_dashboard_ip}" == 127.* ]]; then
        print_ip="<cyware-dashboard-ip>"
    else
        print_ip="${nodes_dashboard_ip}"
    fi

    until [ "$(curl -XGET https://"${nodes_dashboard_ip}":"${http_port}"/status -uadmin:"${u_pass}" -k -w %"{http_code}" -s -o /dev/null)" -eq "200" ] || [ "${j}" -eq "12" ]; do
        sleep 10
        j=$((j+1))
        common_logger -d "Retrying Cyware dashboard connection..."
    done

    if [ ${j} -lt 12 ]; then
        common_logger -d "Cyware dashboard connection was successful."
        if [ "${#server_node_names[@]}" -eq 1 ]; then
            cyware_api_address=${server_node_ips[0]}
        else
            for i in "${!server_node_types[@]}"; do
                if [[ "${server_node_types[i]}" == "master" ]]; then
                    cyware_api_address=${server_node_ips[i]}
                fi
            done
        fi
        if [ -f "/usr/share/cyware-dashboard/data/cyware/config/cyware.yml" ]; then
            eval "sed -i 's,url: https://localhost,url: https://${cyware_api_address},g' /usr/share/cyware-dashboard/data/cyware/config/cyware.yml ${debug}"
        fi

        common_logger "Cyware dashboard web application initialized."
        common_logger -nl "--- Summary ---"
        common_logger -nl "You can access the web interface https://${print_ip}:${http_port}\n    User: admin\n    Password: ${u_pass}"

    else
        flag="-w"
        if [ -z "${force}" ]; then
            flag="-e"
        fi
        failed_nodes=()
        common_logger "${flag}" "Cannot connect to Cyware dashboard."

        for i in "${!indexer_node_ips[@]}"; do
            curl=$(common_curl -XGET https://"${indexer_node_ips[i]}":9200/ -uadmin:"${u_pass}" -k -s --max-time 300 --retry 5 --retry-delay 5 --fail)
            exit_code=${PIPESTATUS[0]}
            if [[ "${exit_code}" -eq "7" ]]; then
                failed_connect=1
                failed_nodes+=("${indexer_node_names[i]}")
            elif [ "${exit_code}" -eq "22" ]; then
                sec_not_initialized=1
            fi
        done
        if [ -n "${failed_connect}" ]; then
            common_logger "${flag}" "Failed to connect with ${failed_nodes[*]}. Connection refused."
        fi

        if [ -n "${sec_not_initialized}" ]; then
            common_logger "${flag}" "Cyware indexer security settings not initialized. Please run the installation assistant using -s|--start-cluster in one of the cyware indexer nodes."
        fi

        if [ -z "${force}" ]; then
            common_logger "If you want to install Cyware dashboard without waiting for the Cyware indexer cluster, use the -fd option"
            installCommon_rollBack
            exit 1
        else
            common_logger -nl "--- Summary ---"
            common_logger -nl "When Cyware dashboard is able to connect to your Cyware indexer cluster, you can access the web interface https://${print_ip}\n    User: admin\n    Password: ${u_pass}"
        fi
    fi

}

function dashboard_initializeAIO() {

    common_logger "Initializing Cyware dashboard web application."
    installCommon_getPass "admin"
    http_code=$(curl -XGET https://localhost:"${http_port}"/status -uadmin:"${u_pass}" -k -w %"{http_code}" -s -o /dev/null)
    retries=0
    max_dashboard_initialize_retries=20
    while [ "${http_code}" -ne "200" ] && [ "${retries}" -lt "${max_dashboard_initialize_retries}" ]
    do
        http_code=$(curl -XGET https://localhost:"${http_port}"/status -uadmin:"${u_pass}" -k -w %"{http_code}" -s -o /dev/null)
        common_logger "Cyware dashboard web application not yet initialized. Waiting..."
        retries=$((retries+1))
        sleep 15
    done
    if [ "${http_code}" -eq "200" ]; then
        common_logger "Cyware dashboard web application initialized."
        common_logger -nl "--- Summary ---"
        common_logger -nl "You can access the web interface https://<cyware-dashboard-ip>:${http_port}\n    User: admin\n    Password: ${u_pass}"
    else
        common_logger -e "Cyware dashboard installation failed."
        installCommon_rollBack
        exit 1
    fi
}

function dashboard_install() {

    common_logger "Starting Cyware dashboard installation."
    if [ "${sys_type}" == "yum" ]; then
        eval "yum install cyware-dashboard${sep}${cyware_version} -y ${debug}"
        install_result="${PIPESTATUS[0]}"
    elif [ "${sys_type}" == "apt-get" ]; then
        installCommon_aptInstall "cyware-dashboard" "${cyware_version}-*"
    fi
    common_checkInstalled
    if [  "$install_result" != 0  ] || [ -z "${dashboard_installed}" ]; then
        common_logger -e "Cyware dashboard installation failed."
        installCommon_rollBack
        exit 1
    else
        common_logger "Cyware dashboard installation finished."
    fi

}

function dashboard_installReportDependencies() {

    # Flags that indicates that is an optional installation.
    optional_installation=1
    report_dependencies=1
    common_logger -d "Installing Cyware dashboard report dependencies."

    installCommon_checkChromium

    if [ "${sys_type}" == "yum" ]; then
        dashboard_dependencies+=( nss xorg-x11-fonts-100dpi xorg-x11-fonts-75dpi xorg-x11-utils xorg-x11-fonts-cyrillic xorg-x11-fonts-Type1 xorg-x11-fonts-misc fontconfig freetype )
        installCommon_yumInstallList "${dashboard_dependencies[@]}"

        # In RHEL cases, remove the CentOS repositories configuration
        if [ "${centos_repos_configured}" == 1 ]; then
            installCommon_removeCentOSrepositories
        fi
    
    elif [ "${sys_type}" == "apt-get" ]; then
        dashboard_dependencies+=( libnss3-dev fonts-liberation libfontconfig1 )
        installCommon_aptInstallList "${dashboard_dependencies[@]}"
    fi

    if [ "${pdf_warning}" == 1 ]; then
        common_logger -w "Cyware dashboard dependencies skipped. PDF report generation may not work."
    fi
    optional_installation=0

}
