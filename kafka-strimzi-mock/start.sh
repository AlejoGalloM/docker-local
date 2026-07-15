#!/bin/bash
# =============================================================================
# Kafka Strimzi Mock — start.sh
#
# Requisitos en el host:
#   - Docker + Docker Compose v2  (docker compose) o v1 (docker-compose)
#   - Java JDK (keytool)          → brew install openjdk  /  sdk install java
#   - Python 3                    → brew install python3
#   - AWS CLI (opcional)          → solo para actualizar el secreto en LocalStack
#
# Uso:
#   bash kafka-strimzi-mock/start.sh          # flujo completo
#   SKIP_START=1 bash kafka-strimzi-mock/start.sh  # solo genera certs, no levanta
# =============================================================================

KAFKA_USER="local-user"
KAFKA_PASS="local-password"
KAFKA_TOPIC="${KAFKA_TOPIC:-test-with-registries}"
ALIAS="kafka2"
SECRET_NAME="nu1291001-conversor-contable-dev-secret-operative-eda-com-mnt"
LOCALSTACK_ENDPOINT="${LOCALSTACK_ENDPOINT:-http://localhost:4566}"

# Resolver rutas absolutas sin importar desde dónde se ejecute el script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
KAFKA_SECRETS_DIR="$SCRIPT_DIR/kafka-secrets"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/docker-compose-services.yml"

echo "============================================="
echo "  Kafka Strimzi Mock - Inicializando..."
echo "  SCRIPT_DIR  : $SCRIPT_DIR"
echo "  REPO_ROOT   : $REPO_ROOT"
echo "  COMPOSE_FILE: $COMPOSE_FILE"
echo "============================================="

# -------------------------------------------------------
# Verificar prerequisitos
# -------------------------------------------------------
MISSING=""
command -v docker   >/dev/null 2>&1 || MISSING="$MISSING docker"
command -v keytool  >/dev/null 2>&1 || MISSING="$MISSING keytool(JDK)"
command -v python3  >/dev/null 2>&1 || MISSING="$MISSING python3"

if [ -n "$MISSING" ]; then
  echo "[ERROR] Faltan dependencias en el host:$MISSING"
  echo "  - docker:          https://docs.docker.com/get-docker/"
  echo "  - keytool (JDK):   brew install openjdk   (macOS)"
  echo "                     sudo apt install default-jdk  (Ubuntu)"
  echo "  - python3:         brew install python3   (macOS)"
  exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "[ERROR] No se encontró $COMPOSE_FILE"
  echo "  Asegúrate de ejecutar el script desde dentro del repo."
  exit 1
fi

# -------------------------------------------------------
# Detectar Docker Compose
# -------------------------------------------------------
if command -v docker-compose >/dev/null 2>&1; then
  DOCKER_COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
  DOCKER_COMPOSE_CMD="docker compose"
else
  echo "[ERROR] Docker Compose no está disponible."
  echo "  Instala Docker Desktop o 'docker compose' plugin."
  exit 1
fi

# -------------------------------------------------------
# 1. Generar Keystore / Truststore
# -------------------------------------------------------
echo ""
echo "[1/5] Generando certificados SSL con keytool..."
CERT_DIR=/tmp/kafka-certs
mkdir -p "$CERT_DIR"
rm -f "$CERT_DIR/kafka.keystore.jks" "$CERT_DIR/kafka.truststore.jks" "$CERT_DIR/kafka.cert"

keytool -genkey -noprompt \
  -alias "$ALIAS" \
  -dname "CN=localhost, OU=Test, O=Test, L=Test, S=Test, C=US" \
  -keystore "$CERT_DIR/kafka.keystore.jks" \
  -storepass secret \
  -keypass secret \
  -keyalg RSA \
  -validity 3650

keytool -export -noprompt \
  -alias "$ALIAS" \
  -keystore "$CERT_DIR/kafka.keystore.jks" \
  -storepass secret \
  -file "$CERT_DIR/kafka.cert"

keytool -import -noprompt \
  -alias "$ALIAS" \
  -file "$CERT_DIR/kafka.cert" \
  -keystore "$CERT_DIR/kafka.truststore.jks" \
  -storepass secret

echo "[1/5] Certificados generados correctamente."

# -------------------------------------------------------
# 2. Escribir secrets en kafka-secrets/
# -------------------------------------------------------
echo ""
echo "[2/5] Configurando archivos de secretos..."
mkdir -p "$KAFKA_SECRETS_DIR"

if ! touch "$KAFKA_SECRETS_DIR/.write_test" >/dev/null 2>&1; then
  echo "[ERROR] Sin permisos de escritura en $KAFKA_SECRETS_DIR"
  exit 1
fi
rm -f "$KAFKA_SECRETS_DIR/.write_test"

cp "$CERT_DIR/kafka.keystore.jks"   "$KAFKA_SECRETS_DIR/kafka.keystore.jks"
cp "$CERT_DIR/kafka.truststore.jks" "$KAFKA_SECRETS_DIR/kafka.truststore.jks"
printf 'secret' > "$KAFKA_SECRETS_DIR/ssl_keystore_password"
printf 'secret' > "$KAFKA_SECRETS_DIR/ssl_key_password"
printf 'secret' > "$KAFKA_SECRETS_DIR/ssl_truststore_password"

# JAAS para ZooKeeper server — define el usuario "kafka" con DIGEST-MD5
cat > "$KAFKA_SECRETS_DIR/zookeeper_jaas.conf" <<'EOF'
Server {
    org.apache.zookeeper.server.auth.DigestLoginModule required
    user_kafka="kafka-secret";
};
EOF

# JAAS para Kafka broker:
#   KafkaServer → SCRAM-SHA-512 para clientes externos (listener SASL_SSL :9095)
#   Client      → DIGEST-MD5 para la conexión interna broker → ZooKeeper
#   Clase DigestLoginModule está en zookeeper-3.6.x.jar dentro de cp-kafka:7.5.0
cat > "$KAFKA_SECRETS_DIR/kafka_server_jaas.conf" <<'EOF'
KafkaServer {
    org.apache.kafka.common.security.scram.ScramLoginModule required;
};

Client {
    org.apache.zookeeper.server.auth.DigestLoginModule required
    username="kafka"
    password="kafka-secret";
};
EOF

chmod 600 "$KAFKA_SECRETS_DIR/zookeeper_jaas.conf" \
          "$KAFKA_SECRETS_DIR/kafka_server_jaas.conf" 2>/dev/null || true

echo "[2/5] Archivos de secretos listos."

# -------------------------------------------------------
# 3. Levantar stack (o salir si SKIP_START=1)
# -------------------------------------------------------
if [ "${SKIP_START:-0}" = "1" ]; then
  echo ""
  echo "============================================="
  echo "  [SKIP_START=1] Solo se generaron certs."
  echo "  Para levantar: bash $0"
  echo "============================================="
  exit 0
fi

echo ""
echo "[3/5] Levantando stack Strimzi..."
cd "$REPO_ROOT"

# Para y elimina solo los contenedores de Strimzi — no toca Redis, Postgres, etc.
$DOCKER_COMPOSE_CMD -f docker-compose-services.yml stop \
  kafka-strimzi-init kafka-strimzi zookeeper-strimzi kafka-ui 2>/dev/null || true
$DOCKER_COMPOSE_CMD -f docker-compose-services.yml rm -f \
  kafka-strimzi-init kafka-strimzi zookeeper-strimzi 2>/dev/null || true
$DOCKER_COMPOSE_CMD -f docker-compose-services.yml up -d \
  zookeeper-strimzi kafka-strimzi kafka-strimzi-init

echo "Esperando a que Kafka esté disponible (máx 120s)..."
KAFKA_READY="false"
for i in $(seq 1 60); do
  if docker exec kafka-strimzi kafka-broker-api-versions \
       --bootstrap-server localhost:9097 >/dev/null 2>&1; then
    echo "  ✅ Kafka disponible en el intento $i"
    KAFKA_READY="true"
    break
  fi
  echo "  intento $i/60..."
  sleep 2
done

if [ "$KAFKA_READY" != "true" ]; then
  echo "[ERROR] Kafka no respondió en 120s. Últimos logs:"
  $DOCKER_COMPOSE_CMD -f docker-compose-services.yml logs kafka-strimzi 2>&1 | tail -20
  exit 1
fi

# Reiniciar kafka-ui para que registre el nuevo certificado
echo ""
echo "[4/5] Reiniciando kafka-ui..."
$DOCKER_COMPOSE_CMD -f docker-compose-services.yml up -d \
  kafka-ui --force-recreate 2>/dev/null || true

# -------------------------------------------------------
# 5. Actualizar secreto en LocalStack
# -------------------------------------------------------
echo ""
echo "[5/5] Actualizando secreto en LocalStack..."

CERT=$(keytool -exportcert -alias "$ALIAS" \
  -keystore "$KAFKA_SECRETS_DIR/kafka.truststore.jks" \
  -storepass secret -noprompt -rfc 2>/dev/null)

SECRET_JSON=$(python3 - <<PYEOF
import json
cert = open("$KAFKA_SECRETS_DIR/kafka.truststore.jks.pem", "r").read() if False else r"""$CERT"""
secret = {
    "username": "$KAFKA_USER",
    "password": "$KAFKA_PASS",
    "bootstrapServer": "localhost:9095",
    "certificate": cert.strip()
}
print(json.dumps(secret))
PYEOF
)

if command -v aws >/dev/null 2>&1; then
  aws --endpoint-url="$LOCALSTACK_ENDPOINT" --region us-east-1 \
    secretsmanager create-secret \
    --name "$SECRET_NAME" --secret-string "$SECRET_JSON" 2>/dev/null \
  || aws --endpoint-url="$LOCALSTACK_ENDPOINT" --region us-east-1 \
    secretsmanager put-secret-value \
    --secret-id "$SECRET_NAME" --secret-string "$SECRET_JSON" 2>/dev/null
  echo "  ✅ Secreto '$SECRET_NAME' actualizado en LocalStack"
else
  echo "  ⚠️  AWS CLI no encontrado — secreto NO actualizado."
  echo "  Instala con: pip install awscli  o  brew install awscli"
fi

echo ""
echo "============================================="
echo "  ✅ Kafka Strimzi Mock listo"
echo "---------------------------------------------"
echo "  SASL_SSL  (clientes externos) → localhost:9095"
echo "  PLAINTEXT (interno/UI)        → localhost:9097"
echo "  Usuario   : $KAFKA_USER"
echo "  Password  : $KAFKA_PASS"
echo "  Tópico    : $KAFKA_TOPIC"
echo "  Kafka UI  : http://localhost:9091  (cluster: strimzi-mock)"
echo "  Secreto   : $SECRET_NAME"
echo "============================================="
