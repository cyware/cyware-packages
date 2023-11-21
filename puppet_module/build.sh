#!/bin/bash
set -e

cyware_branch=$1

download_sources() {
    if ! curl -L https://github.com/cyware/cyware-puppet/tarball/${cyware_branch} | tar zx ; then
        echo "Error downloading the source code from GitHub."
        exit 1
    fi
    cd cyware-*
}

build_module() {

    download_sources

    pdk build --force --target-dir=/tmp/output/

    exit 0
}

build_module
