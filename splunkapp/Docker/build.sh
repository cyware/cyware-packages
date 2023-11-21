#!/bin/bash

cyware_branch=$1
checksum=$2
revision=$3

cyware_version=""
splunk_version=""

build_dir="/pkg"
destination_dir="/cyware_splunk_app"
checksum_dir="/var/local/checksum"
package_json="${build_dir}/package.json"

download_sources() {
    if ! curl -L https://github.com/cyware/cyware-splunk/tarball/${cyware_branch} | tar zx ; then
        echo "Error downloading the source code from GitHub."
        exit 1
    fi
    mv cyware-* ${build_dir}
    cyware_version=$(python -c "import json, os; f=open(\""${package_json}"\"); pkg=json.load(f); f.close(); print(pkg[\"version\"])")
    splunk_version=$(python -c "import json, os; f=open(\""${package_json}"\"); pkg=json.load(f); f.close(); print(pkg[\"splunk\"])")}
}

remove_execute_permissions() {
    chmod -R -x+X * ./SplunkAppForCyware/appserver
}

build_package() {

    download_sources

    cd ${build_dir}

    remove_execute_permissions

    if [ -z ${revision} ]; then
        cyware_splunk_pkg_name="cyware_splunk-${cyware_version}_${splunk_version}.tar.gz"
    else
        cyware_splunk_pkg_name="cyware_splunk-${cyware_version}_${splunk_version}-${revision}.tar.gz"
    fi

    tar -zcf ${cyware_splunk_pkg_name} SplunkAppForCyware

    mv ${cyware_splunk_pkg_name} ${destination_dir}

    if [ ${checksum} = "yes" ]; then
        cd ${destination_dir} && sha512sum "${cyware_splunk_pkg_name}" > "${checksum_dir}/${cyware_splunk_pkg_name}".sha512
    fi

    exit 0
}

build_package