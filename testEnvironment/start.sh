#!/bin/bash

# Construir imagen Go para AMD64
docker build -f Dockerfile_go -t localhost/gonu0145001_iastacceleratorgateway_mr:test --platform=linux/amd64 --load .

# Levantar servicios con compose
docker compose -f mq-go-compose.yaml up -d

echo "Servicios levantados con MQ ARM64 y Go AMD64"