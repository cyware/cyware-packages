# Cyware installer - common.sh functions.
# Copyright (C) 2015, KhulnaSoft Ltd.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

function installCommon_addCentOSRepository() {

    local repo_name="$1"
    local repo_description="$2"
    local repo_baseurl="$3"

    echo "[$repo_name]" >> "${centos_repo}"
    echo "name=${repo_description}" >> "${centos_repo}"
    echo "baseurl=${repo_baseurl}" >> "${centos_repo}"
    echo 'gpgcheck=1' >> "${centos_repo}"
    echo 'enabled=1' >> "${centos_repo}"
    echo "gpgkey=file://${centos_key}" >> "${centos_repo}"
    echo '' >> "${centos_repo}"

}

function installCommon_cleanExit() {

    rollback_conf=""

    if [ -n "$spin_pid" ]; then
        eval "kill -9 $spin_pid ${debug}"
    fi

    until [[ "${rollback_conf}" =~ ^[N|Y|n|y]$ ]]; do
        echo -ne "\nDo you want to remove the ongoing installation?[Y/N]"
        read -r rollback_conf
    done
    if [[ "${rollback_conf}" =~ [N|n] ]]; then
        exit 1
    else
        common_checkInstalled
        installCommon_rollBack
        exit 1
    fi

}

function installCommon_addCywareRepo() {

    common_logger -d "Adding the Cyware repository."

    if [ -n "${development}" ]; then
        if [ "${sys_type}" == "yum" ]; then
            eval "rm -f /etc/yum.repos.d/cyware.repo ${debug}"
        elif [ "${sys_type}" == "apt-get" ]; then
            eval "rm -f /etc/apt/sources.list.d/cyware.list ${debug}"
        fi
    fi

    if [ ! -f "/etc/yum.repos.d/cyware.repo" ] && [ ! -f "/etc/zypp/repos.d/cyware.repo" ] && [ ! -f "/etc/apt/sources.list.d/cyware.list" ] ; then
        if [ "${sys_type}" == "yum" ]; then
            eval "rpm --import ${repogpg} ${debug}"
            if [ "${PIPESTATUS[0]}" != 0 ]; then
                common_logger -e "Cannot import Cyware GPG key"
                exit 1
            fi
            eval "(echo -e '[cyware]\ngpgcheck=1\ngpgkey=${repogpg}\nenabled=1\nname=EL-\${releasever} - Cyware\nbaseurl='${repobaseurl}'/yum/\nprotect=1' | tee /etc/yum.repos.d/cyware.repo)" "${debug}"
            eval "chmod 644 /etc/yum.repos.d/cyware.repo ${debug}"
        elif [ "${sys_type}" == "apt-get" ]; then
            eval "common_curl -s ${repogpg} --max-time 300 --retry 5 --retry-delay 5 --fail | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/cyware.gpg --import - ${debug}"
            if [ "${PIPESTATUS[0]}" != 0 ]; then
                common_logger -e "Cannot import Cyware GPG key"
                exit 1
            fi
            eval "chmod 644 /usr/share/keyrings/cyware.gpg ${debug}"
            eval "(echo \"deb [signed-by=/usr/share/keyrings/cyware.gpg] ${repobaseurl}/apt/ ${reporelease} main\" | tee /etc/apt/sources.list.d/cyware.list)" "${debug}"
            eval "apt-get update -q ${debug}"
            eval "chmod 644 /etc/apt/sources.list.d/cyware.list ${debug}"
        fi
    else
        common_logger -d "Cyware repository already exists. Skipping addition."
    fi

    if [ -n "${development}" ]; then
        common_logger "Cyware development repository added."
    else
        common_logger "Cyware repository added."
    fi
}

function installCommon_aptInstall() {

    package="${1}"
    version="${2}"
    attempt=0
    if [ -n "${version}" ]; then
        installer=${package}${sep}${version}
    else
        installer=${package}
    fi
    command="DEBIAN_FRONTEND=noninteractive apt-get install ${installer} -y -q"
    installCommon_checkAptLock

    if [ "${attempt}" -ne "${max_attempts}" ]; then
        apt_output=$(eval "${command} 2>&1")
        install_result="${PIPESTATUS[0]}"
        eval "echo \${apt_output} ${debug}"
    fi

}

function installCommon_aptInstallList(){

    dependencies=("$@")
    not_installed=()

    for dep in "${dependencies[@]}"; do
        if ! apt list --installed 2>/dev/null | grep -q -E ^"${dep}"\/; then
            not_installed+=("${dep}")
        fi
    done

    if [ "${#not_installed[@]}" -gt 0 ]; then
        common_logger "--- Dependencies ----"
        for dep in "${not_installed[@]}"; do
            common_logger "Installing $dep."
            installCommon_aptInstall "${dep}"
            if [ "${install_result}" != 0 ]; then
                installCommon_checkOptionalInstallation
            fi
        done
    fi

}

function installCommon_changePasswordApi() {

    common_logger -d "Changing API passwords."

    #Change API password tool
    if [ -n "${changeall}" ]; then
        for i in "${!api_passwords[@]}"; do
            if [ -n "${cyware}" ] || [ -n "${AIO}" ]; then
                passwords_getApiUserId "${api_users[i]}"
                CYWARE_PASS_API='{\"password\":\"'"${api_passwords[i]}"'\"}'
                eval 'common_curl -s -k -X PUT -H \"Authorization: Bearer $TOKEN_API\" -H \"Content-Type: application/json\" -d "$CYWARE_PASS_API" "https://localhost:55000/security/users/${user_id}" -o /dev/null --max-time 300 --retry 5 --retry-delay 5 --fail'
                if [ "${api_users[i]}" == "${adminUser}" ]; then
                    sleep 1
                    adminPassword="${api_passwords[i]}"
                    passwords_getApiToken
                fi
            fi
            if [ "${api_users[i]}" == "cyware-wui" ] && { [ -n "${dashboard}" ] || [ -n "${AIO}" ]; }; then
                passwords_changeDashboardApiPassword "${api_passwords[i]}"
            fi
        done
    else
        if [ -n "${cyware}" ] || [ -n "${AIO}" ]; then
            passwords_getApiUserId "${nuser}"
            CYWARE_PASS_API='{\"password\":\"'"${password}"'\"}'
            eval 'common_curl -s -k -X PUT -H \"Authorization: Bearer $TOKEN_API\" -H \"Content-Type: application/json\" -d "$CYWARE_PASS_API" "https://localhost:55000/security/users/${user_id}" -o /dev/null --max-time 300 --retry 5 --retry-delay 5 --fail'
        fi
        if [ "${nuser}" == "cyware-wui" ] && { [ -n "${dashboard}" ] || [ -n "${AIO}" ]; }; then
                passwords_changeDashboardApiPassword "${password}"
        fi
    fi

}

function installCommon_checkOptionalInstallation() {

    if [ "${optional_installation}" != 1 ]; then
        common_logger -e "Cannot install dependency: ${dep}."
        exit 1
    else
        common_logger -w "Cannot install optional dependency: ${dep}."
        if [ "${report_dependencies}" == 1 ]; then 
            pdf_warning=1
        fi
    fi

}

function installCommon_checkAptLock() {

    attempt=0
    seconds=30
    max_attempts=10

    while fuser "${apt_lockfile}" >/dev/null 2>&1 && [ "${attempt}" -lt "${max_attempts}" ]; do
        attempt=$((attempt+1))
        common_logger "Another process is using APT. Waiting for it to release the lock. Next retry in ${seconds} seconds (${attempt}/${max_attempts})"
        sleep "${seconds}"
    done

}

function installCommon_checkYumLock() {

    attempt=0
    seconds=30
    max_attempts=10

    while [ -f "${yum_lockfile}" ] && [ "${attempt}" -lt "${max_attempts}" ]; do
        attempt=$((attempt+1))
        common_logger "Another process is using YUM. Waiting for it to release the lock. Next retry in ${seconds} seconds (${attempt}/${max_attempts})"
        sleep "${seconds}"
    done

}

function installCommon_createCertificates() {

    common_logger -d "Creating Cyware certificates."
    if [ -n "${AIO}" ]; then
        eval "installCommon_getConfig certificate/config_aio.yml ${config_file} ${debug}"
    fi

    cert_readConfig

    if [ -d /tmp/cyware-certificates/ ]; then
        eval "rm -rf /tmp/cyware-certificates/ ${debug}"
    fi
    eval "mkdir /tmp/cyware-certificates/ ${debug}"

    cert_tmp_path="/tmp/cyware-certificates/"

    cert_generateRootCAcertificate
    cert_generateAdmincertificate
    cert_generateIndexercertificates
    cert_generateFilebeatcertificates
    cert_generateDashboardcertificates
    cert_cleanFiles
    eval "chmod 400 /tmp/cyware-certificates/* ${debug}"
    eval "mv /tmp/cyware-certificates/* /tmp/cyware-install-files ${debug}"
    eval "rm -rf /tmp/cyware-certificates/ ${debug}"

}

function installCommon_createClusterKey() {

    openssl rand -hex 16 >> "/tmp/cyware-install-files/clusterkey"

}

function installCommon_createInstallFiles() {

    if [ -d /tmp/cyware-install-files ]; then
        eval "rm -rf /tmp/cyware-install-files ${debug}"
    fi

    if eval "mkdir /tmp/cyware-install-files ${debug}"; then
        common_logger "Generating configuration files."
        if [ -n "${configurations}" ]; then
            cert_checkOpenSSL
        fi
        installCommon_createCertificates
        if [ -n "${server_node_types[*]}" ]; then
            installCommon_createClusterKey
        fi
        gen_file="/tmp/cyware-install-files/cyware-passwords.txt"
        passwords_generatePasswordFile
        eval "cp '${config_file}' '/tmp/cyware-install-files/config.yml' ${debug}"
        eval "chown root:root /tmp/cyware-install-files/* ${debug}"
        eval "tar -zcf '${tar_file}' -C '/tmp/' cyware-install-files/ ${debug}"
        eval "rm -rf '/tmp/cyware-install-files' ${debug}"
	    eval "rm -rf ${config_file} ${debug}"
        common_logger "Created ${tar_file_name}. It contains the Cyware cluster key, certificates, and passwords necessary for installation."
    else
        common_logger -e "Unable to create /tmp/cyware-install-files"
        exit 1
    fi
}

function installCommon_changePasswords() {

    common_logger -d "Setting Cyware indexer cluster passwords."
    if [ -f "${tar_file}" ]; then
        eval "tar -xf ${tar_file} -C /tmp cyware-install-files/cyware-passwords.txt ${debug}"
        p_file="/tmp/cyware-install-files/cyware-passwords.txt"
        common_checkInstalled
        if [ -n "${start_indexer_cluster}" ] || [ -n "${AIO}" ]; then
            changeall=1
            passwords_readUsers
        else
            no_indexer_backup=1
        fi
        if { [ -n "${cyware}" ] || [ -n "${AIO}" ]; } && { [ "${server_node_types[pos]}" == "master" ] || [ "${#server_node_names[@]}" -eq 1 ]; }; then
            passwords_getApiToken
            passwords_getApiUsers
            passwords_getApiIds
        else
            api_users=( cyware cyware-wui )
        fi
        installCommon_readPasswordFileUsers
    else
        common_logger -e "Cannot find passwords file. Exiting"
        exit 1
    fi
    if [ -n "${start_indexer_cluster}" ] || [ -n "${AIO}" ]; then
        passwords_getNetworkHost
        passwords_generateHash
    fi

    passwords_changePassword

    if [ -n "${start_indexer_cluster}" ] || [ -n "${AIO}" ]; then
        passwords_runSecurityAdmin
    fi
    if [ -n "${cyware}" ] || [ -n "${dashboard}" ] || [ -n "${AIO}" ]; then
        if [ "${server_node_types[pos]}" == "master" ] || [ "${#server_node_names[@]}" -eq 1 ] || [ -n "${dashboard_installed}" ]; then
            installCommon_changePasswordApi
        fi
    fi

}

function installCommon_checkChromium() {

    if [ "${sys_type}" == "yum" ]; then
        installCommon_checkYumLock
        if (! yum list installed 2>/dev/null | grep -q -E ^"google-chrome-stable"\\.) && (! yum list installed 2>/dev/null | grep -q -E ^"chromium"\\.); then
            if [ "${DIST_NAME}" == "amzn" ]; then
                installCommon_installChrome
            elif [[ "${DIST_NAME}" == "centos" ]] && [[ "${DIST_VER}" == "7" ]]; then
                installCommon_installChrome
            elif [[ "${DIST_NAME}" == "rhel" ]] && [[ "${DIST_VER}" == "8" || "${DIST_VER}" == "9" ]]; then
                installCommon_configureCentOSRepositories
                dashboard_dependencies=(chromium)
            else
                dashboard_dependencies=(chromium)
            fi
        fi
        
    elif [ "${sys_type}" == "apt-get" ]; then
        if (! apt list --installed 2>/dev/null | grep -q -E ^"google-chrome-stable"\/) && (! apt list --installed 2>/dev/null | grep -q -E ^"chromium-browser"\/); then

            # Report generation doesn't work with Chromium in Ubuntu 22 and Ubuntu 20
            if [[ "${DIST_NAME}" == "ubuntu" ]] && [[ "${DIST_VER}" == "22" || "${DIST_VER}" == "20" || "${DIST_VER}" == "18" ]]; then
                installCommon_installChrome
            else
                dashboard_dependencies=(chromium-browser)
            fi
        fi
    fi

}

# Adds the CentOS repository to install the dashboard dependencies. 
function installCommon_configureCentOSRepositories() {

    centos_repos_configured=1
    centos_key="/etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial"
    eval "common_curl -sLo ${centos_key} 'https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official' --max-time 300 --retry 5 --retry-delay 5 --fail"

    if [ ! -f "${centos_key}" ]; then
        common_logger -w "The CentOS key could not be added. Chromium package skipped."
        pdf_warning=1
    else
        centos_repo="/etc/yum.repos.d/centos.repo"
        eval "touch ${centos_repo} ${debug}"
        common_logger -d "CentOS repository file created."

        if [ "${DIST_VER}" == "9" ]; then
            installCommon_addCentOSRepository "appstream" "CentOS Stream \$releasever - AppStream" "https://mirror.stream.centos.org/9-stream/AppStream/\$basearch/os/"
            installCommon_addCentOSRepository "baseos" "CentOS Stream \$releasever - BaseOS" "https://mirror.stream.centos.org/9-stream/BaseOS/\$basearch/os/"
        elif [ "${DIST_VER}" == "8" ]; then
            installCommon_addCentOSRepository "extras" "CentOS Linux \$releasever - Extras" "http://vault.centos.org/centos/\$releasever/extras/\$basearch/os/"
            installCommon_addCentOSRepository "baseos" "CentOS Linux \$releasever - BaseOS" "http://vault.centos.org/centos/\$releasever/BaseOS/\$basearch/os/"
            installCommon_addCentOSRepository "appstream" "CentOS Linux \$releasever - AppStream" "http://vault.centos.org/centos/\$releasever/AppStream/\$basearch/os/"
        fi

        common_logger -d "CentOS repositories added."
    fi

}

function installCommon_extractConfig() {

    common_logger -d "Extracting Cyware configuration."
    if ! tar -tf "${tar_file}" | grep -q cyware-install-files/config.yml; then
        common_logger -e "There is no config.yml file in ${tar_file}."
        exit 1
    fi
    eval "tar -xf ${tar_file} -C /tmp cyware-install-files/config.yml ${debug}"

}

function installCommon_getConfig() {

    if [ "$#" -ne 2 ]; then
        common_logger -e "installCommon_getConfig should be called with two arguments"
        exit 1
    fi

    config_name="config_file_$(eval "echo ${1} | sed 's|/|_|g;s|.yml||'")"
    if [ -z "$(eval "echo \${${config_name}}")" ]; then
        common_logger -e "Unable to find configuration file ${1}. Exiting."
        installCommon_rollBack
        exit 1
    fi
    eval "echo \"\${${config_name}}\"" > "${2}"
}

function installCommon_getPass() {

    for i in "${!users[@]}"; do
        if [ "${users[i]}" == "${1}" ]; then
            u_pass=${passwords[i]}
        fi
    done
}

function installCommon_installCheckDependencies() {

    common_logger -d "Installing check dependencies."
    if [ "${sys_type}" == "yum" ]; then
        dependencies=( systemd grep tar coreutils sed procps-ng gawk lsof curl openssl )
        installCommon_yumInstallList "${dependencies[@]}"

    elif [ "${sys_type}" == "apt-get" ]; then
        eval "apt-get update -q ${debug}"
        dependencies=( systemd grep tar coreutils sed procps gawk lsof curl openssl )
        installCommon_aptInstallList "${dependencies[@]}"
    fi

}

function installCommon_installChrome() {

    dep="chrome"
    common_logger "Installing ${dep}."

    if [ "${sys_type}" == "yum" ]; then
        chrome_package="/tmp/cyware-install-files/chrome.rpm"
        common_curl -sSo "${chrome_package}" https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm --max-time 100 --retry 5 --retry-delay 5 --fail
        eval "yum install ${chrome_package} -y ${debug}"

        if [ "${PIPESTATUS[0]}" != 0 ]; then
            installCommon_checkOptionalInstallation
        fi

    elif [ "${sys_type}" == "apt-get" ]; then
        chrome_package="/tmp/cyware-install-files/chrome.deb"
        common_curl -sSo "${chrome_package}" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb --max-time 100 --retry 5 --retry-delay 5 --fail
        installCommon_aptInstall "${chrome_package}"

        if [ "${install_result}" != 0 ]; then
            installCommon_checkOptionalInstallation
        fi
    fi

}

function installCommon_installPrerequisites() {

    common_logger -d "Installing prerequisites dependencies."
    if [ "${sys_type}" == "yum" ]; then
        dependencies=( libcap gnupg2 )
        installCommon_yumInstallList "${dependencies[@]}"

    elif [ "${sys_type}" == "apt-get" ]; then
        eval "apt-get update -q ${debug}"
        dependencies=( apt-transport-https libcap2-bin software-properties-common gnupg )
        installCommon_aptInstallList "${dependencies[@]}"
    fi

}

function installCommon_readPasswordFileUsers() {

    filecorrect=$(grep -Ev '^#|^\s*$' "${p_file}" | grep -Pzc "\A(\s*(indexer_username|api_username|indexer_password|api_password):[ \t]+[\'\"]?[\w.*+?-]+[\'\"]?)+\Z")
    if [[ "${filecorrect}" -ne 1 ]]; then
        common_logger -e "The password file does not have a correct format or password uses invalid characters. Allowed characters: A-Za-z0-9.*+?

For Cyware indexer users, the file must have this format:

# Description
  indexer_username: <user>
  indexer_password: <password>

For Cyware API users, the file must have this format:

# Description
  api_username: <user>
  api_password: <password>

"
	    installCommon_rollBack
        exit 1
    fi

    sfileusers=$(grep indexer_username: "${p_file}" | awk '{ print substr( $2, 1, length($2) ) }' | sed -e "s/[\'\"]//g")
    sfilepasswords=$(grep indexer_password: "${p_file}" | awk '{ print substr( $2, 1, length($2) ) }' | sed -e "s/[\'\"]//g")

    sfileapiusers=$(grep api_username: "${p_file}" | awk '{ print substr( $2, 1, length($2) ) }' | sed -e "s/[\'\"]//g")
    sfileapipasswords=$(grep api_password: "${p_file}" | awk '{ print substr( $2, 1, length($2) ) }' | sed -e "s/[\'\"]//g")


    mapfile -t fileusers < <(printf '%s\n' "${sfileusers}")
    mapfile -t filepasswords < <(printf '%s\n' "${sfilepasswords}")
    mapfile -t fileapiusers < <(printf '%s\n' "${sfileapiusers}")
    mapfile -t fileapipasswords < <(printf '%s\n' "${sfileapipasswords}")

    if [ -n "${changeall}" ]; then
        for j in "${!fileusers[@]}"; do
            supported=false
            for i in "${!users[@]}"; do
                if [[ ${users[i]} == "${fileusers[j]}" ]]; then
                    passwords_checkPassword "${filepasswords[j]}"
                    passwords[i]=${filepasswords[j]}
                    supported=true
                fi
            done
            if [ "${supported}" = false ] && [ -n "${indexer_installed}" ]; then
                common_logger -e -d "The given user ${fileusers[j]} does not exist"
            fi
        done

        for j in "${!fileapiusers[@]}"; do
            supported=false
            for i in "${!api_users[@]}"; do
                if [[ "${api_users[i]}" == "${fileapiusers[j]}" ]]; then
                    passwords_checkPassword "${fileapipasswords[j]}"
                    api_passwords[i]=${fileapipasswords[j]}
                    supported=true
                fi
            done
            if [ "${supported}" = false ] && [ -n "${indexer_installed}" ]; then
                common_logger -e "The Cyware API user ${fileapiusers[j]} does not exist"
            fi
        done
    else
        finalusers=()
        finalpasswords=()

        finalapiusers=()
        finalapipasswords=()

        if [ -n "${dashboard_installed}" ] &&  [ -n "${dashboard}" ]; then
            users=( kibanaserver admin )
        fi

        if [ -n "${filebeat_installed}" ] && [ -n "${cyware}" ]; then
            users=( admin )
        fi

        for j in "${!fileusers[@]}"; do
            supported=false
            for i in "${!users[@]}"; do
                if [[ "${users[i]}" == "${fileusers[j]}" ]]; then
                    passwords_checkPassword "${filepasswords[j]}"
                    finalusers+=(${fileusers[j]})
                    finalpasswords+=(${filepasswords[j]})
                    supported=true
                fi
            done
            if [ "${supported}" = "false" ] && [ -n "${indexer_installed}" ] && [ -n "${changeall}" ]; then
                common_logger -e -d "The given user ${fileusers[j]} does not exist"
            fi
        done

        for j in "${!fileapiusers[@]}"; do
            supported=false
            for i in "${!api_users[@]}"; do
                if [[ "${api_users[i]}" == "${fileapiusers[j]}" ]]; then
                    passwords_checkPassword "${fileapipasswords[j]}"
                    finalapiusers+=("${fileapiusers[j]}")
                    finalapipasswords+=("${fileapipasswords[j]}")
                    supported=true
                fi
            done
            if [ ${supported} = false ] && [ -n "${indexer_installed}" ]; then
                common_logger -e "The Cyware API user ${fileapiusers[j]} does not exist"
            fi
        done

        users=()
        mapfile -t users < <(printf '%s\n' "${finalusers[@]}")
        mapfile -t passwords < <(printf '%s\n' "${finalpasswords[@]}")
        mapfile -t api_users < <(printf '%s\n' "${finalapiusers[@]}")
        mapfile -t api_passwords < <(printf '%s\n' "${finalapipasswords[@]}")
        changeall=1
    fi

}

function installCommon_restoreCywarerepo() {

    common_logger -d "Restoring Cyware repository."
    if [ -n "${development}" ]; then
        if [ "${sys_type}" == "yum" ] && [ -f "/etc/yum.repos.d/cyware.repo" ]; then
            file="/etc/yum.repos.d/cyware.repo"
        elif [ "${sys_type}" == "apt-get" ] && [ -f "/etc/apt/sources.list.d/cyware.list" ]; then
            file="/etc/apt/sources.list.d/cyware.list"
        else
            common_logger -w -d "Cyware repository does not exists."
        fi
        eval "sed -i 's/-dev//g' ${file} ${debug}"
        eval "sed -i 's/pre-release/4.x/g' ${file} ${debug}"
        eval "sed -i 's/unstable/stable/g' ${file} ${debug}"
    fi

}

function installCommon_removeCentOSrepositories() {
    
    eval "rm -f ${centos_repo} ${debug}"
    eval "rm -f ${centos_key} ${debug}"
    eval "yum clean all ${debug}"
    centos_repos_configured=0
    common_logger -d "CentOS repositories and key deleted."

}

function installCommon_rollBack() {

    if [ -z "${uninstall}" ]; then
        common_logger "--- Removing existing Cyware installation ---"
    fi

    if [ -f "/etc/yum.repos.d/cyware.repo" ]; then
        eval "rm /etc/yum.repos.d/cyware.repo ${debug}"
    elif [ -f "/etc/zypp/repos.d/cyware.repo" ]; then
        eval "rm /etc/zypp/repos.d/cyware.repo ${debug}"
    elif [ -f "/etc/apt/sources.list.d/cyware.list" ]; then
        eval "rm /etc/apt/sources.list.d/cyware.list ${debug}"
    fi

    if [[ -n "${cyware_installed}" && ( -n "${cyware}" || -n "${AIO}" || -n "${uninstall}" ) ]];then
        common_logger "Removing Cyware manager."
        if [ "${sys_type}" == "yum" ]; then
            installCommon_checkYumLock
            if [ "${attempt}" -ne "${max_attempts}" ]; then
                eval "yum remove cyware-manager -y ${debug}"
                manager_installed=$(yum list installed 2>/dev/null | grep cyware-manager)
            fi
        elif [ "${sys_type}" == "apt-get" ]; then
            installCommon_checkAptLock
            eval "apt-get remove --purge cyware-manager -y ${debug}"
            manager_installed=$(apt list --installed 2>/dev/null | grep cyware-manager)
        fi

        if [ -n "${manager_installed}" ]; then
            common_logger -w "The Cyware manager package could not be removed."
        else
            common_logger "Cyware manager removed."
        fi
        
    fi

    if [[ ( -n "${cyware_remaining_files}"  || -n "${cyware_installed}" ) && ( -n "${cyware}" || -n "${AIO}" || -n "${uninstall}" ) ]]; then
        eval "rm -rf /var/ossec/ ${debug}"
    fi

    if [[ -n "${indexer_installed}" && ( -n "${indexer}" || -n "${AIO}" || -n "${uninstall}" ) ]]; then
        common_logger "Removing Cyware indexer."
        if [ "${sys_type}" == "yum" ]; then
            installCommon_checkYumLock
            if [ "${attempt}" -ne "${max_attempts}" ]; then
                eval "yum remove cyware-indexer -y ${debug}"
                indexer_installed=$(yum list installed 2>/dev/null | grep cyware-indexer)
            fi
        elif [ "${sys_type}" == "apt-get" ]; then
            installCommon_checkAptLock
            eval "apt-get remove --purge cyware-indexer -y ${debug}"
            indexer_installed=$(apt list --installed 2>/dev/null | grep cyware-indexer)
        fi

        if [ -n "${indexer_installed}" ]; then
            common_logger -w "The Cyware indexer package could not be removed."
        else
            common_logger "Cyware indexer removed."
        fi
    fi

    if [[ ( -n "${indexer_remaining_files}" || -n "${indexer_installed}" ) && ( -n "${indexer}" || -n "${AIO}" || -n "${uninstall}" ) ]]; then
        eval "rm -rf /var/lib/cyware-indexer/ ${debug}"
        eval "rm -rf /usr/share/cyware-indexer/ ${debug}"
        eval "rm -rf /etc/cyware-indexer/ ${debug}"
    fi

    if [[ -n "${filebeat_installed}" && ( -n "${cyware}" || -n "${AIO}" || -n "${uninstall}" ) ]]; then
        common_logger "Removing Filebeat."
        if [ "${sys_type}" == "yum" ]; then
            installCommon_checkYumLock
            if [ "${attempt}" -ne "${max_attempts}" ]; then
                eval "yum remove filebeat -y ${debug}"
                filebeat_installed=$(yum list installed 2>/dev/null | grep filebeat)
            fi
        elif [ "${sys_type}" == "apt-get" ]; then
            installCommon_checkAptLock
            eval "apt-get remove --purge filebeat -y ${debug}"
            filebeat_installed=$(apt list --installed 2>/dev/null | grep filebeat)
        fi

        if [ -n "${filebeat_installed}" ]; then
            common_logger -w "The Filebeat package could not be removed."
        else
            common_logger "Filebeat removed."
        fi
    fi

    if [[ ( -n "${filebeat_remaining_files}" || -n "${filebeat_installed}" ) && ( -n "${cyware}" || -n "${AIO}" || -n "${uninstall}" ) ]]; then
        eval "rm -rf /var/lib/filebeat/ ${debug}"
        eval "rm -rf /usr/share/filebeat/ ${debug}"
        eval "rm -rf /etc/filebeat/ ${debug}"
    fi

    if [[ -n "${dashboard_installed}" && ( -n "${dashboard}" || -n "${AIO}" || -n "${uninstall}" ) ]]; then
        common_logger "Removing Cyware dashboard."
        if [ "${sys_type}" == "yum" ]; then
            installCommon_checkYumLock
            if [ "${attempt}" -ne "${max_attempts}" ]; then
                eval "yum remove cyware-dashboard -y ${debug}"
                dashboard_installed=$(yum list installed 2>/dev/null | grep cyware-dashboard)
            fi
        elif [ "${sys_type}" == "apt-get" ]; then
            installCommon_checkAptLock
            eval "apt-get remove --purge cyware-dashboard -y ${debug}"
            dashboard_installed=$(apt list --installed 2>/dev/null | grep cyware-dashboard)
        fi

        if [ -n "${dashboard_installed}" ]; then
            common_logger -w "The Cyware dashboard package could not be removed."
        else
            common_logger "Cyware dashboard removed."
        fi
    fi

    if [[ ( -n "${dashboard_remaining_files}" || -n "${dashboard_installed}" ) && ( -n "${dashboard}" || -n "${AIO}" || -n "${uninstall}" ) ]]; then
        eval "rm -rf /var/lib/cyware-dashboard/ ${debug}"
        eval "rm -rf /usr/share/cyware-dashboard/ ${debug}"
        eval "rm -rf /etc/cyware-dashboard/ ${debug}"
        eval "rm -rf /run/cyware-dashboard/ ${debug}"
    fi

    elements_to_remove=(    "/var/log/cyware-indexer/"
                            "/var/log/filebeat/"
                            "/etc/systemd/system/opensearch.service.wants/"
                            "/securityadmin_demo.sh"
                            "/etc/systemd/system/multi-user.target.wants/cyware-manager.service"
                            "/etc/systemd/system/multi-user.target.wants/filebeat.service"
                            "/etc/systemd/system/multi-user.target.wants/opensearch.service"
                            "/etc/systemd/system/multi-user.target.wants/cyware-dashboard.service"
                            "/etc/systemd/system/cyware-dashboard.service"
                            "/lib/firewalld/services/dashboard.xml"
                            "/lib/firewalld/services/opensearch.xml" )

    eval "rm -rf ${elements_to_remove[*]} ${debug}"

    common_remove_gpg_key

    eval "systemctl daemon-reload ${debug}"

    if [ -z "${uninstall}" ]; then
        if [ -n "${rollback_conf}" ] || [ -n "${overwrite}" ]; then
            common_logger "Installation cleaned."
        else
            common_logger "Installation cleaned. Check the ${logfile} file to learn more about the issue."
        fi
    fi

}

function installCommon_startService() {

    if [ "$#" -ne 1 ]; then
        common_logger -e "installCommon_startService must be called with 1 argument."
        exit 1
    fi

    common_logger "Starting service ${1}."

    if [[ -d /run/systemd/system ]]; then
        eval "systemctl daemon-reload ${debug}"
        eval "systemctl enable ${1}.service ${debug}"
        eval "systemctl start ${1}.service ${debug}"
        if [  "${PIPESTATUS[0]}" != 0  ]; then
            common_logger -e "${1} could not be started."
            if [ -n "$(command -v journalctl)" ]; then
                eval "journalctl -u ${1} >> ${logfile}"
            fi
            installCommon_rollBack
            exit 1
        else
            common_logger "${1} service started."
        fi
    elif ps -p 1 -o comm= | grep "init"; then
        eval "chkconfig ${1} on ${debug}"
        eval "service ${1} start ${debug}"
        eval "/etc/init.d/${1} start ${debug}"
        if [  "${PIPESTATUS[0]}" != 0  ]; then
            common_logger -e "${1} could not be started."
            if [ -n "$(command -v journalctl)" ]; then
                eval "journalctl -u ${1} >> ${logfile}"
            fi
            installCommon_rollBack
            exit 1
        else
            common_logger "${1} service started."
        fi
    elif [ -x "/etc/rc.d/init.d/${1}" ] ; then
        eval "/etc/rc.d/init.d/${1} start ${debug}"
        if [  "${PIPESTATUS[0]}" != 0  ]; then
            common_logger -e "${1} could not be started."
            if [ -n "$(command -v journalctl)" ]; then
                eval "journalctl -u ${1} >> ${logfile}"
            fi
            installCommon_rollBack
            exit 1
        else
            common_logger "${1} service started."
        fi
    else
        common_logger -e "${1} could not start. No service manager found on the system."
        exit 1
    fi

}

function installCommon_yumInstallList(){

    dependencies=("$@")
    not_installed=()
    for dep in "${dependencies[@]}"; do
        installCommon_checkYumLock
        if ! yum list installed 2>/dev/null | grep -q -E ^"${dep}"\\.;then
            not_installed+=("${dep}")
        fi
    done

    if [ "${#not_installed[@]}" -gt 0 ]; then
        common_logger "--- Dependencies ---"
        for dep in "${not_installed[@]}"; do
            common_logger "Installing $dep."
            installCommon_yumInstall "${dep}"
            yum_code="${PIPESTATUS[0]}"

            if [  "${install_result}" != 0  ]; then
                installCommon_checkOptionalInstallation
            fi
        done
    fi

}

function installCommon_yumInstall() {

    package="${1}"
    version="${2}"
    install_result=1
    if [ -n "${version}" ]; then
        installer="${package}-${version}"
    else
        installer="${package}"
    fi
    
    command="yum install ${installer} -y"
    installCommon_checkYumLock

    if [ "${attempt}" -ne "${max_attempts}" ]; then
        yum_output=$(eval "${command} 2>&1")  
        install_result="${PIPESTATUS[0]}"
        eval "echo \${yum_output} ${debug}"
    fi

}