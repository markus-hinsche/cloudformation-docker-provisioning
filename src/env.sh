#!/usr/bin/env bash

# Run this from this repository's root directory

set -euo pipefail

if [[ -z $1 ]]; then
    echo "Usage: env <STACK_NAME>"
    exit 1
fi
STACK_NAME=$1

source deploy/"${STACK_NAME}"/config
echo "${DOCKER_PARAMS}"
echo "export DOCKER_HOST DOCKER_TLS_PATH DOCKER_CERT_PATH DOCKER_TLS_VERIFY DOCKER_API_VERSION DOCKER_MACHINE_NAME"
exit
