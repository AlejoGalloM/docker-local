#!/usr/local/bin/bash

secrets=(
"nu0051001-digital-distribution-local-sm-security-services-rabbitmq=file://Secrets/rabbitmq.json"
"nu0051001-digital-distribution-local-rabbitmq-delivery-adapters-d2b=file://Secrets/rabbitmq.json"
"nu0051001-digital-distribution-local-rabbitmq-engagement-d2b=file://Secrets/rabbitmq.json"
"nu0051001-digital-distribution-local-sm-authorization-services-postgres=file://Secrets/auth-postgres.json"
"nu0051001-digital-distribution-dev-apic-suatoken-engagement-blm=file://Secrets/sua.json"
"nu0051001-digital-distribution-local-sm-channel-validations-postgres=file://Secrets/channel-validations-postgres.json"
"nu0051001-digital-distribution-dev-apic-mdm-engagement-blm=file://Secrets/mdm.json"
"nu0051001-digital-distribution-dev-apic-suid-engagement-blm=file://Secrets/suid.json"
"nu0051001-digital-distribution-dev-apic-suamodulus-engagement-blm=file://Secrets/suamodulus.json"
"nu0051001-digital-distribution-local-postgres-cm-ms-channel-management-d2b=file://Secrets/channel-management-postgres.json"
"nu0051001-digital-distribution-local-digital-certificate-apic-d2b=file://Secrets/digital-certificate.json"
"aw0955001-alm-local-cognito-transversal-blm=file://Secrets/cognito.json"
"nu0212001-negocios-bancolombia-local-keystore-ss-ms-crypto-engagement-dbb=file://Secrets/crypto.json"
"nu0214001-neg-secret-certificate-novelty=file://Secrets/certificate-novelty.json"
"nu0212001-redis-local-svn=file://Secrets/redis.json"
"nu0214001-neg-qa-digital-certificate-apic-neg=file://Secrets/certificate-api.json"
"nu0212001-d2b-local-apic-engagement-DBB=file://Secrets/apic-engagement.json"
"nu0212001-negocios-bancolombia-local-keystore-ss-ms-crypto-engagement-dbb=file://Secrets/keystore-crypto.json"
"nu0212001-neg-local-cic-secret=file://Secrets/cic.json"
"nu0212001-neg-local-iuvity-secret=file://Secrets/iuvity.json"
"nu0212001-d2b-localsandbox-apic-engagement-DBB=file://Secrets/apic.json"
"nu0212001-neg-local-rabbitmq-svn=file://Secrets/rabbitmq-local.json"
)

echo "These are the defined secrets:"
echo ""

for idx in "${!secrets[@]}"
do
  echo "Secret : ${secrets[$idx]}"
  echo ""
done

AWS_ACCESS_KEY_ID="xxxx"
AWS_SECRET_ACCESS_KEY="xxxx"
AWS_DEFAULT_REGION="us-east-1"
DEFAULT_LOCALSTACK_ENDPOINT="http://localhost:4566"

read -p "Start the Galatea docker containers? (remember to go to the docker-compose.yaml file folder) [yes / no]: " START_DOCKER_COMPOSE
read -p "Do you use <aws> CLI? [yes / no]: " AWS

if [ ! $AWS = 'yes' ]; then
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

for idx in "${!secrets[@]}"
do
    IFS='='
    read -a strarr <<< "${secrets[$idx]}"
    if [ -z $AWS ] || [ $AWS = 'yes' ] ; then
        aws secretsmanager create-secret --name ${strarr[0]} --secret-string ${strarr[1]}
    else
        aws --endpoint-url=$DEFAULT_LOCALSTACK_ENDPOINT secretsmanager create-secret --name ${strarr[0]} --secret-string ${strarr[1]}
    fi
done

echo ""
echo "Restoring secrets to avoid previous delete actions..."
echo ""

for idx in "${!secrets[@]}"
do
    IFS='='
    read -a strarr <<< "${secrets[$idx]}"
    if [ -z $AWS ] || [ $AWS = 'yes' ]; then
        aws secretsmanager restore-secret --secret-id ${strarr[0]}
    else
        aws --endpoint-url=$DEFAULT_LOCALSTACK_ENDPOINT secretsmanager restore-secret --secret-id ${strarr[0]}
    fi

    echo ""
done

echo ""
echo "Current secrets availeble..."
echo ""

if [ -z $AWS ] || [ $AWS = 'yes' ]; then
    aws secretsmanager list-secrets
else
    aws --endpoint-url=$DEFAULT_LOCALSTACK_ENDPOINT secretsmanager list-secrets
fi


echo ""
echo "Creating kinesis data-stream resource..."
echo ""

KINESIS_DATA_STREAM_NAME="nu0051001-digital-distribution-local-kinesis-central-repo-data-stream"
KINESIS_DATA_STREAM_SHARD_COUNT=1

if [ -z $AWS ] || [ $AWS = 'yes' ]; then
	aws kinesis create-stream --shard-count $KINESIS_DATA_STREAM_SHARD_COUNT --stream-name $KINESIS_DATA_STREAM_NAME
else
	aws --endpoint-url=$DEFAULT_LOCALSTACK_ENDPOINT kinesis create-stream --shard-count $KINESIS_DATA_STREAM_SHARD_COUNT --stream-name $KINESIS_DATA_STREAM_NAME
fi