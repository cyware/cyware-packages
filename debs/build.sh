#!/bin/bash

# Cyware package builder
# Copyright (C) 2015, KhulnaSoft Ltd.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

set -ex

# Script parameters to build the package
build_target=$1
cyware_branch=$2
architecture_target=$3
package_release=$4
jobs=$5
dir_path=$6
debug=$7
checksum=$8
cyware_packages_branch=$9
use_local_specs=${10}
local_source_code=${11}
future=${12}

if [ -z "${package_release}" ]; then
    package_release="1"
fi

if [ ${build_target} = "api" ]; then
    if [ "${local_source_code}" = "no" ]; then
        curl -sL https://github.com/cyware/cyware-api/tarball/${cyware_branch} | tar zx
    fi
    cyware_version="$(grep version cyware*/package.json | cut -d '"' -f 4)"
else
    if [ "${local_source_code}" = "no" ]; then
        curl -sL https://github.com/cyware/cyware/tarball/${cyware_branch} | tar zx
    fi
    cyware_version="$(cat cyware*/src/VERSION | cut -d 'v' -f 2)"
fi

# Build directories
build_dir=/build_cyware
package_full_name="cyware-${build_target}-${cyware_version}"
sources_dir="${build_dir}/${build_target}/${package_full_name}"

mkdir -p ${build_dir}/${build_target}
cp -R cyware* ${build_dir}/${build_target}/cyware-${build_target}-${cyware_version}

if [ "${use_local_specs}" = "no" ]; then
    curl -sL https://github.com/cyware/cyware-packages/tarball/${cyware_packages_branch} | tar zx
    package_files="cyware*/debs"
    specs_path=$(find ${package_files} -type d -name "SPECS" -path "*debs*")
else
    package_files="/specs"
    specs_path="${package_files}/SPECS"
fi

if [[ "${future}" == "yes" ]]; then
    # MODIFY VARIABLES
    base_version=$cyware_version
    MAJOR=$(echo $base_version | cut -dv -f2 | cut -d. -f1)
    MINOR=$(echo $base_version | cut -d. -f2)
    cyware_version="${MAJOR}.30.0"
    file_name="cyware-${build_target}-${cyware_version}-${package_release}"
    old_name="cyware-${build_target}-${base_version}-${package_release}"
    package_full_name=cyware-${build_target}-${cyware_version}
    old_package_name=cyware-${build_target}-${base_version}
    mv "${build_dir}/${build_target}/${old_package_name}" "${build_dir}/${build_target}/${package_full_name}"
    sources_dir="${build_dir}/${build_target}/${package_full_name}"

    # PREPARE FUTURE SPECS AND SOURCES
    find "${build_dir}/${package_name}" "${specs_path}" \( -name "*VERSION*" -o -name "*changelog*" \) -exec sed -i "s/${base_version}/${cyware_version}/g" {} \;
    sed -i "s/\$(VERSION)/${MAJOR}.${MINOR}/g" "${build_dir}/${build_target}/${package_full_name}/src/Makefile"
    sed -i "s/${base_version}/${cyware_version}/g" "${build_dir}/${build_target}/${package_full_name}/src/init/cyware-server.sh"
    sed -i "s/${base_version}/${cyware_version}/g" "${build_dir}/${build_target}/${package_full_name}/src/init/cyware-client.sh"
    sed -i "s/${base_version}/${cyware_version}/g" "${build_dir}/${build_target}/${package_full_name}/src/init/cyware-local.sh"
fi
cp -pr ${specs_path}/cyware-${build_target}/debian ${sources_dir}/debian
cp -p ${package_files}/gen_permissions.sh ${sources_dir}

# Generating directory structure to build the .deb package
cd ${build_dir}/${build_target} && tar -czf ${package_full_name}.orig.tar.gz "${package_full_name}"

# Configure the package with the different parameters
sed -i "s:RELEASE:${package_release}:g" ${sources_dir}/debian/changelog
sed -i "s:export JOBS=.*:export JOBS=${jobs}:g" ${sources_dir}/debian/rules
sed -i "s:export DEBUG_ENABLED=.*:export DEBUG_ENABLED=${debug}:g" ${sources_dir}/debian/rules
sed -i "s#export PATH=.*#export PATH=/usr/local/gcc-5.5.0/bin:${PATH}#g" ${sources_dir}/debian/rules
sed -i "s#export LD_LIBRARY_PATH=.*#export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}#g" ${sources_dir}/debian/rules
sed -i "s:export INSTALLATION_DIR=.*:export INSTALLATION_DIR=${dir_path}:g" ${sources_dir}/debian/rules
sed -i "s:DIR=\"/var/ossec\":DIR=\"${dir_path}\":g" ${sources_dir}/debian/{preinst,postinst,prerm,postrm}
if [ "${build_target}" == "api" ]; then
    sed -i "s:DIR=\"/var/ossec\":DIR=\"${dir_path}\":g" ${sources_dir}/debian/cyware-api.init
    if [ "${architecture_target}" == "ppc64le" ]; then
        sed -i "s: nodejs (>= 4.6), npm,::g" ${sources_dir}/debian/control
    fi
fi

if [[ "${debug}" == "yes" ]]; then
    sed -i "s:dh_strip --no-automatic-dbgsym::g" ${sources_dir}/debian/rules
fi

# Installing build dependencies
cd ${sources_dir}
mk-build-deps -ir -t "apt-get -o Debug::pkgProblemResolver=yes -y"

# Build package
if [[ "${architecture_target}" == "amd64" ]] ||  [[ "${architecture_target}" == "ppc64le" ]] || \
    [[ "${architecture_target}" == "arm64" ]]; then
    debuild --rootcmd=sudo -b -uc -us
elif [[ "${architecture_target}" == "armhf" ]]; then
    linux32 debuild --rootcmd=sudo -b -uc -us
else
    linux32 debuild --rootcmd=sudo -ai386 -b -uc -us
fi

deb_file="cyware-${build_target}_${cyware_version}-${package_release}"
if [[ "${architecture_target}" == "ppc64le" ]]; then
  deb_file="${deb_file}_ppc64el.deb"
else
  deb_file="${deb_file}_${architecture_target}.deb"
fi
pkg_path="${build_dir}/${build_target}"

if [[ "${checksum}" == "yes" ]]; then
    cd ${pkg_path} && sha512sum ${deb_file} > /var/local/checksum/${deb_file}.sha512
fi
mv ${pkg_path}/${deb_file} /var/local/cyware
