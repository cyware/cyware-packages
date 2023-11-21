#! /bin/bash

set -ex

BRANCH=$1
JOBS=$2
DEBUG=$3
REVISION=$4
TRUST_VERIFICATION=$5
CA_NAME=$6
ZIP_NAME="windows_agent_${REVISION}.zip"

URL_REPO=https://github.com/cyware/cyware/archive/${BRANCH}.zip

# Download the cyware repository
wget -O cyware.zip ${URL_REPO} && unzip cyware.zip

# Compile the cyware agent for Windows
FLAGS="-j ${JOBS} IMAGE_TRUST_CHECKS=${TRUST_VERIFICATION} CA_NAME=\"${CA_NAME}\" "

if [[ "${DEBUG}" = "yes" ]]; then
    FLAGS+="-d "
fi

bash -c "make -C /cyware-*/src deps TARGET=winagent ${FLAGS}"
bash -c "make -C /cyware-*/src TARGET=winagent ${FLAGS}"

rm -rf /cyware-*/src/external

# Zip the compiled agent and move it to the shared folder
zip -r ${ZIP_NAME} cyware-*
cp ${ZIP_NAME} /shared
