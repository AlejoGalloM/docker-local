#!/bin/bash

declare -A secrets

secrets["nu0051001-digital-distribution-local-rabbitmq-delivery-adapters-d2b"]="file://secrets/rabbitmq.json"
secrets["nu0051001-digital-distribution-local-rabbitmq-security-services-d2b"]="file://secrets/rabbitmq.json"
secrets["nu0051001-digital-distribution-local-rabbitmq-engagement-d2b"]="file://secrets/rabbitmq.json"
secrets["nu0051001-digital-distribution-local-postgres-ds-ms-channel-validations-d2b"]="file://secrets/channel-validations-postgres.json"
secrets["nu0051001-digital-distribution-local-postgres-cm-ms-channel-management-d2b"]="file://secrets/channel-management-postgres.json"
secrets["nu0051001-digital-distribution-local-postgres-ds-ms-authorization-services-d2b"]="file://secrets/auth-postgres.json"
secrets["nu0051001-digital-distribution-local-cognito-d2b"]="file://secrets/cognito.json"
secrets["nu0051001-digital-distribution-local-apic-suatoken-engagement-d2b"]="file://secrets/sua.json"
secrets["nu0051001-digital-distribution-local-apic-mdm-engagement-d2b"]="file://secrets/mdm.json"
secrets["nu0051001-digital-distribution-local-apic-suid-engagement-d2b"]="file://secrets/suid.json"
secrets["nu0051001-digital-distribution-local-apic-suamodulus-engagement-do2b"]="file://secrets/suamodulus.json"
secrets["nu0051001-digital-distribution-local-feature-flags-security-filters-d2b"]="file://secrets/featureflag.json"
secrets["nu0051001-digital-distribution-local-digital-certificate-apic-d2b"]="file://secrets/digital-certificate.json"




echo "These are the defined secrets:"
echo ""

for name in "${!secrets[@]}"
do
  echo "Name : $name"
  echo "File : ${secrets[$name]}"
  echo ""
done

DEFAULT_LOCALSTACK_ENDPOINT="http://localhost:4566"

read -p "Start the Galatea docker containers? (remember to go to the docker-compose.yaml file folder) [yes / no]: " START_DOCKER_COMPOSE
read -p "Do you use <awslocal> CLI? [yes / no]: " AWS_LOCAL

if [ ! $AWS_LOCAL = 'yes' ]; then
    read -p "Use the default localstack endpoint ($DEFAULT_LOCALSTACK_ENDPOINT)? [yes / (type endpoint...)]: " LOCALSTACK_USE_DEFAULT_ENDPOINT
    
    if [ ! $LOCALSTACK_USE_DEFAULT_ENDPOINT = 'yes' ]; then
        DEFAULT_LOCALSTACK_ENDPOINT=$LOCALSTACK_USE_DEFAULT_ENDPOINT
    fi

    echo "Using $DEFAULT_LOCALSTACK_ENDPOINT"
fi

echo ""

if [ -z $START_DOCKER_COMPOSE ] || [ $START_DOCKER_COMPOSE = 'yes' ]; then

    echo "waiting..."
    docker-compose up -d
fi

echo ""
echo "Creating secrets..."

for name in "${!secrets[@]}"
do
    if [ -z $AWS_LOCAL ] || [ $AWS_LOCAL = 'yes' ] ; then
        awslocal secretsmanager create-secret --name $name --secret-string ${secrets[$name]}
    else
        aws --endpoint-url=$DEFAULT_LOCALSTACK_ENDPOINT secretsmanager create-secret --name $name --secret-string ${secrets[$name]}
    fi
done

echo ""
echo "Restoring secrets to avoid previous delete actions..."
echo ""

for name in "${!secrets[@]}"
do
    if [ -z $AWS_LOCAL ] || [ $AWS_LOCAL = 'yes' ]; then
        awslocal secretsmanager restore-secret --secret-id $name
    else
        aws --endpoint-url=$DEFAULT_LOCALSTACK_ENDPOINT secretsmanager restore-secret --secret-id $name
    fi

    echo ""
done

echo ""
echo "Current secrets availeble..."
echo ""

if [ -z $AWS_LOCAL ] || [ $AWS_LOCAL = 'yes' ]; then
    awslocal secretsmanager list-secrets
else
    aws --endpoint-url=$DEFAULT_LOCALSTACK_ENDPOINT secretsmanager create-secret --name $name --secret-string ${secrets[$name]}
fi


echo ""
echo "Creating kinesis data-stream resource..."
echo ""

KINESIS_DATA_STREAM_NAME="nu0051001-digital-distribution-local-kinesis-central-repo-data-stream"
KINESIS_DATA_STREAM_SHARD_COUNT=1

if [ -z $AWS_LOCAL ] || [ $AWS_LOCAL = 'yes' ]; then
	awslocal kinesis create-stream --shard-count $KINESIS_DATA_STREAM_SHARD_COUNT --stream-name $KINESIS_DATA_STREAM_NAME
else
	aws --endpoint-url=$DEFAULT_LOCALSTACK_ENDPOINT kinesis create-stream --shard-count $KINESIS_DATA_STREAM_SHARD_COUNT --stream-name $KINESIS_DATA_STREAM_NAME
fi