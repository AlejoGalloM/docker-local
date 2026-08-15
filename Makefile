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
	@echo "  make up-tools     - Levanta SOLO herramientas extra (RabbitMQ, Mailhog, SFTP)"
	@echo "  make up-monitoring - Levanta SOLO el stack de observabilidad (Prometheus, Grafana, Jaeger)"
	@echo "  make snapshot-save - Crea un archivo local_snapshot.tar.gz con el estado de las BDs"
	@echo "  make snapshot-load - Restaura el estado desde local_snapshot.tar.gz"

up-all:
	@docker network create d2b-shared-network 2>/dev/null || true
	$(MAKE) up-db
	$(MAKE) up-kafka
	$(MAKE) up-aws
	$(MAKE) up-mq
	$(MAKE) up-tools
	$(MAKE) up-monitoring

down-all:
	cd compose && docker compose -f compose-monitoring.yml down || true
	cd compose && docker compose -f compose-tools.yml down || true
	cd compose && docker compose -f compose-mq.yml down || true
	cd compose && docker compose -f compose-aws.yml down || true
	cd compose && docker compose -f compose-kafka.yml down || true
	cd compose && docker compose -f compose-db.yml down || true

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

up-monitoring:
	cd compose && docker compose -f compose-monitoring.yml up -d

snapshot-save:
	@echo "Creando snapshot de los datos locales..."
	tar -czvf local_snapshot.tar.gz postgres_data/ floci_data/ dynamodb_data/ kafka-secrets/ container-init/ container-config/
	@echo "✅ Snapshot guardado en local_snapshot.tar.gz"

snapshot-load:
	@echo "Restaurando snapshot..."
	tar -xzvf local_snapshot.tar.gz
	@echo "✅ Entorno restaurado exitosamente"
