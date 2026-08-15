# Makefile para levantar componentes de Docker por separado

.PHONY: help up-all down-all up-db up-kafka up-aws up-mq up-tools

help:
	@echo "Opciones disponibles:"
	@echo "  make up-all       - Levanta TODOS los servicios (Orquestador principal)"
	@echo "  make down-all     - Apaga TODOS los servicios y elimina contenedores"
	@echo "  make up-db        - Levanta SOLO bases de datos (Postgres, Mongo, Redis, Dynamo)"
	@echo "  make up-kafka     - Levanta SOLO el ecosistema Kafka (Kafka, Zookeeper, Conduktor)"
	@echo "  make up-aws       - Levanta SOLO AWS Emulators (Floci / LocalStack)"
	@echo "  make up-mq        - Levanta SOLO IBM MQ y el Gateway"
	@echo "  make up-tools     - Levanta SOLO herramientas extra (RabbitMQ, Mailhog, Prometheus, SFTP)"

up-all:
	cd compose && docker compose up -d

down-all:
	cd compose && docker compose down

up-db:
	cd compose && docker compose -f compose-db.yml up -d

up-kafka:
	cd compose && docker compose -f compose-kafka.yml up -d

up-aws:
	cd compose && docker compose -f compose-aws.yml up -d

up-mq:
	cd compose && docker compose -f compose-mq.yml up -d

up-tools:
	cd compose && docker compose -f compose-tools.yml up -d
