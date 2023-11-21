#!/bin/bash
set -x
# Program to build and package OSX cyware-agent
# Cyware package generator
# Copyright (C) 2015, KhulnaSoft Ltd.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

CURRENT_PATH="$( cd $(dirname ${0}) ; pwd -P )"
SOURCES_DIRECTORY="${CURRENT_PATH}/repository"
CYWARE_PATH="${SOURCES_DIRECTORY}/cyware"
CYWARE_SOURCE_REPOSITORY="https://github.com/cyware/cyware"
export CONFIG="${CYWARE_PATH}/etc/preloaded-vars.conf"
ENTITLEMENTS_PATH="${CURRENT_PATH}/entitlements.plist"
ARCH="intel64"
INSTALLATION_PATH="/Library/Ossec"    # Installation path
VERSION=""                            # Default VERSION (branch/tag)
REVISION="1"                          # Package revision.
BRANCH_TAG="master"                   # Branch that will be downloaded to build package.
DESTINATION="${CURRENT_PATH}/output/" # Where package will be stored.
JOBS="2"                              # Compilation jobs.
DEBUG="no"                            # Enables the full log by using `set -exf`.
CHECKSUMDIR=""                        # Directory to store the checksum of the package.
CHECKSUM="no"                         # Enables the checksum generation.
CERT_APPLICATION_ID=""                # Apple Developer ID certificate to sign Apps and binaries.
CERT_INSTALLER_ID=""                  # Apple Developer ID certificate to sign pkg.
KEYCHAIN=""                           # Keychain where the Apple Developer ID certificate is.
KC_PASS=""                            # Password of the keychain.
NOTARIZE="no"                         # Notarize the package for macOS Catalina.
DEVELOPER_ID=""                       # Apple Developer ID.
ALTOOL_PASS=""                        # Temporary Application password for altool.
TEAM_ID=""                            # Team ID of the Apple Developer ID.
pkg_name=""
notarization_path=""

trap ctrl_c INT

function clean_and_exit() {
    exit_code=$1
    rm -rf "${SOURCES_DIRECTORY}"
    rm "${CURRENT_PATH}"/specs/cyware-agent.pkgproj-e
    ${CURRENT_PATH}/uninstall.sh
    exit ${exit_code}
}

function ctrl_c() {
    clean_and_exit 1
}


function notarize_pkg() {

    # Notarize the macOS package
    sleep_time="120"
    build_timestamp="$(date +"%m%d%Y%H%M%S")"
    if [ "${NOTARIZE}" = "yes" ]; then
           
        if sudo xcrun notarytool submit ${1} --apple-id "${DEVELOPER_ID}" --team-id "${TEAM_ID}" --password "${ALTOOL_PASS}" --wait ; then
            echo "Package is notarized and ready to go."
            echo "Adding the ticket to the package."
            if xcrun stapler staple -v "${1}" ; then
                echo "Ticket added. Ready to release the package."
                mkdir -p "${DESTINATION}" && cp "${1}" "${DESTINATION}/"
                return 0
            else
                echo "Something went wrong while adding the package."
                clean_and_exit 1
            fi
        else
            echo "Error notarizing the package."
            clean_and_exit 1
        fi
    fi

    return 0
}

function sign_binaries() {
    if [ ! -z "${KEYCHAIN}" ] && [ ! -z "${CERT_APPLICATION_ID}" ] ; then
        security -v unlock-keychain -p "${KC_PASS}" "${KEYCHAIN}" > /dev/null
        # Sign every single binary in Cyware's installation. This also includes library files.
        for bin in $(find ${INSTALLATION_PATH} -exec file {} \; | grep bit | cut -d: -f1); do
            codesign -f --sign "${CERT_APPLICATION_ID}" --entitlements ${ENTITLEMENTS_PATH} --deep --timestamp  --options=runtime --verbose=4 "${bin}"
        done
        security -v lock-keychain "${KEYCHAIN}" > /dev/null
    fi
}

function sign_pkg() {
    if [ ! -z "${KEYCHAIN}" ] && [ ! -z "${CERT_INSTALLER_ID}" ] ; then
        # Unlock the keychain to use the certificate
        security -v unlock-keychain -p "${KC_PASS}" "${KEYCHAIN}"  > /dev/null

        # Sign the package
        productsign --sign "${CERT_INSTALLER_ID}" --timestamp ${DESTINATION}/${pkg_name} ${DESTINATION}/${pkg_name}.signed
        mv ${DESTINATION}/${pkg_name}.signed ${DESTINATION}/${pkg_name}

        security -v lock-keychain "${KEYCHAIN}" > /dev/null
    fi
}

function build_package() {

    # Download source code
    git clone --depth=1 -b ${BRANCH_TAG} ${CYWARE_SOURCE_REPOSITORY} "${CYWARE_PATH}"

    get_pkgproj_specs

    VERSION=$(cat ${CYWARE_PATH}/src/VERSION | cut -d "-" -f1 | cut -c 2-)

    if [ -d "${INSTALLATION_PATH}" ]; then

        echo "\nThe cyware agent is already installed on this machine."
        echo "Removing it from the system."

        ${CURRENT_PATH}/uninstall.sh
    fi

    packages_script_path="package_files"

    cp ${packages_script_path}/*.sh ${CURRENT_PATH}/package_files/
    ${CURRENT_PATH}/package_files/build.sh "${INSTALLATION_PATH}" "${CYWARE_PATH}" ${JOBS}

    # sign the binaries and the libraries
    sign_binaries

    # create package
    if packagesbuild ${AGENT_PKG_FILE} --build-folder ${DESTINATION} ; then
        echo "The cyware agent package for macOS has been successfully built."
        pkg_name="cyware-agent-${VERSION}-${REVISION}.${ARCH}.pkg"
        sign_pkg
        if [[ "${CHECKSUM}" == "yes" ]]; then
            mkdir -p ${CHECKSUMDIR}
            cd ${DESTINATION} && shasum -a512 "${pkg_name}" > "${CHECKSUMDIR}/${pkg_name}.sha512"
        fi
        clean_and_exit 0
    else
        echo "ERROR: something went wrong while building the package."
        clean_and_exit 1
    fi
}

function help() {

    echo "Usage: $0 [OPTIONS]"
    echo
    echo "  Build options:"
    echo "    -a, --architecture <arch>     [Optional] Target architecture of the package [intel64/arm64]. By Default: intel64."
    echo "    -b, --branch <branch>         [Required] Select Git branch or tag e.g. $BRANCH"
    echo "    -s, --store-path <path>       [Optional] Set the destination absolute path of package."
    echo "    -j, --jobs <number>           [Optional] Number of parallel jobs when compiling."
    echo "    -r, --revision <rev>          [Optional] Package revision that append to version e.g. x.x.x-rev"
    echo "    -c, --checksum <path>         [Optional] Generate checksum on the desired path (by default, if no path is specified it will be generated on the same directory than the package)."
    echo "    -h, --help                    [  Util  ] Show this help."
    echo "    -i, --install-deps            [  Util  ] Install build dependencies (Packages)."
    echo "    -x, --install-xcode           [  Util  ] Install X-Code and brew. Can't be executed as root."
    echo "    -v, --verbose                 [  Util  ] Show additional information during the package generation."
    echo
    echo "  Signing options:"
    echo "    --keychain                    [Optional] Keychain where the Certificates are installed."
    echo "    --keychain-password           [Optional] Password of the keychain."
    echo "    --application-certificate     [Optional] Apple Developer ID certificate name to sign Apps and binaries."
    echo "    --installer-certificate       [Optional] Apple Developer ID certificate name to sign pkg."
    echo "    --notarize                    [Optional] Notarize the package for its distribution on macOS."
    echo "    --notarize-path <path>        [Optional] Path of the package to be notarized."
    echo "    --developer-id                [Optional] Your Apple Developer ID."
    echo "    --team-id                     [Optional] Your Apple Team ID."
    echo "    --altool-password             [Optional] Temporary password to use altool from Xcode."
    echo
    exit "$1"
}

function get_pkgproj_specs() {

    VERSION=$(< "${CYWARE_PATH}/src/VERSION"  cut -d "-" -f1 | cut -c 2-)

    pkg_file="specs/cyware-agent-${ARCH}.pkgproj"

    if [ ! -f "${pkg_file}" ]; then
        echo "Warning: the file ${pkg_file} does not exists. Check the version selected."
        exit 1
    else
        echo "Modifiying ${pkg_file} to match revision."
        sed -i -e "s:${VERSION}-.*<:${VERSION}-${REVISION}.${ARCH}<:g" "${pkg_file}"
        cp "${pkg_file}" "${AGENT_PKG_FILE}"
    fi

    return 0
}

function testdep() {

    if command -v packagesbuild ; then
        return 0
    else
        echo "Error: packagesbuild not found. Download and install dependencies."
        echo "Use $0 -i for install it."
        exit 1
    fi
}

function install_deps() {

    # Install packagesbuild tool
    curl -O http://s.sudre.free.fr/Software/files/Packages.dmg

    hdiutil attach Packages.dmg

    cd /Volumes/Packages*/packages/

    if installer -package Packages.pkg -target / ; then
        echo "Packagesbuild was correctly installed."
    else
        echo "Something went wrong installing packagesbuild."
    fi

    if [ "$(uname -m)" = "arm64" ]; then
        echo "Installing build dependencies for arm64 architecture"
        brew install gcc binutils autoconf automake libtool cmake
    fi
    exit 0
}

function install_xcode() {

    # Install brew tool. Brew will install X-Code if it is not already installed in the host.
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

    exit 0
}

function check_root() {

    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root"
        echo
        exit 1
    fi
}

function main() {

    BUILD="no"
    while [ -n "$1" ]
    do
        case "$1" in
        "-a"|"--architecture")
            if [ -n "$2" ]; then
                ARCH="$2"
                shift 2
            else
                help 1
            fi
            ;;
        "-b"|"--branch")
            if [ -n "$2" ]; then
                BRANCH_TAG="$2"
                BUILD=yes
                shift 2
            else
                help 1
            fi
            ;;
        "-s"|"--store-path")
            if [ -n "$2" ]; then
                DESTINATION="$2"
                shift 2
            else
                help 1
            fi
            ;;
        "-j"|"--jobs")
            if [ -n "$2" ]; then
                JOBS="$2"
                shift 2
            else
                help 1
            fi
            ;;
        "-r"|"--revision")
            if [ -n "$2" ]; then
                REVISION="$2"
                shift 2
            else
                help 1
            fi
            ;;
        "-h"|"--help")
            help 0
            ;;
        "-i"|"--install-deps")
            check_root
            install_deps
            ;;
        "-x"|"--install-xcode")
            install_xcode
            ;;
        "-v"|"--verbose")
            DEBUG="yes"
            shift 1
            ;;
        "-c"|"--checksum")
            if [ -n "$2" ]; then
                CHECKSUMDIR="$2"
                CHECKSUM="yes"
                shift 2
            else
                CHECKSUM="yes"
                shift 1
            fi
            ;;
        "--keychain")
            if [ -n "$2" ]; then
                KEYCHAIN="$2"
                shift 2
            else
                help 1
            fi
            ;;
        "--keychain-password")
            if [ -n "$2" ]; then
                KC_PASS="$2"
                shift 2
            else
                help 1
            fi
            ;;
        "--application-certificate")
            if [ -n "$2" ]; then
                CERT_APPLICATION_ID="$2"
                shift 2
            else
                help 1
            fi
            ;;
        "--installer-certificate")
            if [ -n "$2" ]; then
                CERT_INSTALLER_ID="$2"
                shift 2
            else
                help 1
            fi
            ;;
        "--notarize")
            NOTARIZE="yes"
            shift 1
            ;;
        "--notarize-path")
            if [ -n "$2" ]; then
                notarization_path="$2"
                shift 2
            else
                help 1
            fi
            ;;
        "--developer-id")
            if [ -n "$2" ]; then
                DEVELOPER_ID="$2"
                shift 2
            else
                help 1
            fi
            ;;
        "--team-id")
            if [ -n "$2" ]; then
                TEAM_ID="$2"
                shift 2
            else
                help 1
            fi
            ;;
        "--altool-password")
            if [ -n "$2" ]; then
                ALTOOL_PASS="$2"
                shift 2
            else
                help 1
            fi
            ;;
        *)
            help 1
        esac
    done

    if [ ${DEBUG} = "yes" ]; then
        set -exf
    fi

    testdep

    if [ "${ARCH}" != "intel64" ] && [ "${ARCH}" != "arm64" ]; then
        echo "Error: architecture not supported."
        echo "Supported architectures: intel64, arm64"
        exit 1
    fi

    if [ -z "${CHECKSUMDIR}" ]; then
        CHECKSUMDIR="${DESTINATION}"
    fi

    if [[ "${BUILD}" != "no" ]]; then
        check_root
        AGENT_PKG_FILE="${CURRENT_PATH}/package_files/cyware-agent-${ARCH}.pkgproj"
        build_package
        "${CURRENT_PATH}/uninstall.sh"
    fi
    if [ "${NOTARIZE}" = "yes" ]; then
        if [ "${BUILD}" = "yes" ]; then
            pkg_name="cyware-agent-${VERSION}-${REVISION}.${ARCH}.pkg"
            notarization_path="${DESTINATION}/${pkg_name}"
        fi
        if [ -z "${notarization_path}" ]; then
            echo "The path of the package to be notarized has not been specified."
            help 1
        fi
        notarize_pkg "${notarization_path}"
    fi
    if [ "${BUILD}" = "no" ] && [ "${NOTARIZE}" = "no" ]; then
        echo "The branch has not been specified and notarization has not been selected."
        help 1
    fi

    return 0
}

main "$@"
