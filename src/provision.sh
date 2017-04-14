#!/usr/bin/env bash

# Create a CloudFormation stack, install docker on it, and copies the config into your local directory

set -euo pipefail
set -x

if [[ -z $2 ]]; then
    echo "Usage: provision.sh <STACK_NAME> <CLOUDFORMATION_TEMPLATE>"
    exit 1
fi

STACK_NAME=$1
CLOUDFORMATION_TEMPLATE=$2

REGION="eu-central-1"
aws="aws --region=$REGION"

# KeyPairs: This generates and auto-uploads the public key to AWS
mkdir -p deploy/"${STACK_NAME}"/certs
$aws ec2 create-key-pair --key-name "${STACK_NAME}"-key \
     --query 'KeyMaterial' --output text > "${STACK_NAME}"-key
mv "${STACK_NAME}"-key* deploy/"${STACK_NAME}"/certs/
chmod 600 deploy/"${STACK_NAME}"/certs/"${STACK_NAME}"-key

$aws cloudformation create-stack --stack-name "${STACK_NAME}" \
     --template-body file://${CLOUDFORMATION_TEMPLATE} \
     --capabilities CAPABILITY_IAM \
     --parameters \
     ParameterKey=InstanceType,ParameterValue=t2.medium \
     ParameterKey=KeyName,ParameterValue="${STACK_NAME}"-key \
     ParameterKey=SSHLocation,ParameterValue=0.0.0.0/0

echo "Wait until stack has started for the next commands to run"
sleep 300

# Get IP
INSTANCE_ID=$($aws cloudformation describe-stack-resource\
    --stack-name "${STACK_NAME}" \
    --logical-resource-id DockerHost | \
    python -c "import sys, json; print(json.load(sys.stdin)['StackResourceDetail']['PhysicalResourceId'])")
IP_ADDRESS=$($aws ec2 describe-instances --instance-ids="$INSTANCE_ID" | \
    python -c "import sys, json; print(json.load(sys.stdin)['Reservations'][0]['Instances'][0]['PublicIpAddress'])")

docker-machine create \
               --driver generic \
               --generic-ip-address="$IP_ADDRESS" \
               --generic-ssh-key deploy/"${STACK_NAME}"/certs/"${STACK_NAME}"-key \
               --generic-ssh-user ubuntu \
               "${STACK_NAME}"

sleep 60

eval $(docker-machine env --shell bash "${STACK_NAME}")

# Copy docker-machine certs into a local directory
cp -Rf ${DOCKER_CERT_PATH}/* deploy/"${STACK_NAME}"/certs/

# Create config file for sourcing
cat >deploy/"${STACK_NAME}"/config <<EOL
#!/usr/bin/env bash

DIR="\$( cd "\$( dirname "\${BASH_SOURCE[0]}" )" && pwd )"

HOST_IP="${IP_ADDRESS}"
DOCKER_PARAMS="DOCKER_TLS_VERIFY=1 DOCKER_HOST=tcp://\${HOST_IP}:2376 DOCKER_MACHINE_NAME=${STACK_NAME} DOCKER_CERT_PATH=\${DIR}/certs/ DOCKER_API_VERSION=v1.23"
EOL
