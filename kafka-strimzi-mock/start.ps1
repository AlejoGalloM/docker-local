<#
.SYNOPSIS
Kafka Strimzi Mock — start.ps1 para Windows

.DESCRIPTION
Levanta el entorno de Strimzi localmente en sistemas Windows sin depender de bash.
Requiere:
  - Docker Desktop
  - Java JDK (keytool agregado a las variables de entorno PATH)
  - AWS CLI (opcional, para inyectar en LocalStack)
#>

$ErrorActionPreference = "Stop"

$KAFKA_USER = "local-user"
$KAFKA_PASS = "local-password"
if ([string]::IsNullOrWhiteSpace($env:KAFKA_TOPIC)) { $KAFKA_TOPIC = "test-with-registries" } else { $KAFKA_TOPIC = $env:KAFKA_TOPIC }
$ALIAS = "kafka2"
$SECRET_NAME = "nu1291001-conversor-contable-dev-secret-operative-eda-com-mnt"
if ([string]::IsNullOrWhiteSpace($env:LOCALSTACK_ENDPOINT)) { $LOCALSTACK_ENDPOINT = "http://localhost:4566" } else { $LOCALSTACK_ENDPOINT = $env:LOCALSTACK_ENDPOINT }

$SCRIPT_DIR = $PSScriptRoot
$KAFKA_SECRETS_DIR = Join-Path $SCRIPT_DIR "kafka-secrets"
$REPO_ROOT = Split-Path $SCRIPT_DIR -Parent
$COMPOSE_FILE = Join-Path $REPO_ROOT "docker-compose-services.yml"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Kafka Strimzi Mock - Inicializando (Windows)"
Write-Host "  SCRIPT_DIR  : $SCRIPT_DIR"
Write-Host "  REPO_ROOT   : $REPO_ROOT"
Write-Host "  COMPOSE_FILE: $COMPOSE_FILE"
Write-Host "=============================================" -ForegroundColor Cyan

# -------------------------------------------------------
# Verificar prerequisitos
# -------------------------------------------------------
$MISSING = @()

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { $MISSING += "docker" }
if (-not (Get-Command keytool -ErrorAction SilentlyContinue)) { $MISSING += "keytool(JDK)" }

if ($MISSING.Count -gt 0) {
    Write-Host "[ERROR] Faltan dependencias en el host: $($MISSING -join ', ')" -ForegroundColor Red
    Write-Host "  - docker: Instala Docker Desktop"
    Write-Host "  - keytool (JDK): Instala Java JDK y agregalo al PATH de Windows"
    exit 1
}

if (-not (Test-Path $COMPOSE_FILE)) {
    Write-Host "[ERROR] No se encontró $COMPOSE_FILE" -ForegroundColor Red
    Write-Host "  Asegúrate de ejecutar el script desde la carpeta correcta."
    exit 1
}

# -------------------------------------------------------
# 1. Generar Keystore / Truststore
# -------------------------------------------------------
Write-Host "`n[1/5] Generando certificados SSL con keytool..."
$CERT_DIR = Join-Path $env:TEMP "kafka-certs"
if (-not (Test-Path $CERT_DIR)) { New-Item -ItemType Directory -Path $CERT_DIR | Out-Null }
Remove-Item -Path "$CERT_DIR\*" -Force -ErrorAction SilentlyContinue

$keystore = Join-Path $CERT_DIR "kafka.keystore.jks"
$truststore = Join-Path $CERT_DIR "kafka.truststore.jks"
$cert = Join-Path $CERT_DIR "kafka.cert"

& keytool -genkey -noprompt `
  -alias $ALIAS `
  -dname "CN=localhost, OU=Test, O=Test, L=Test, S=Test, C=US" `
  -keystore $keystore `
  -storepass secret `
  -keypass secret `
  -keyalg RSA `
  -validity 3650

& keytool -export -noprompt `
  -alias $ALIAS `
  -keystore $keystore `
  -storepass secret `
  -file $cert

& keytool -import -noprompt `
  -alias $ALIAS `
  -file $cert `
  -keystore $truststore `
  -storepass secret

Write-Host "[1/5] Certificados generados correctamente."

# -------------------------------------------------------
# 2. Escribir secrets en kafka-secrets/
# -------------------------------------------------------
Write-Host "`n[2/5] Configurando archivos de secretos..."
if (-not (Test-Path $KAFKA_SECRETS_DIR)) { New-Item -ItemType Directory -Path $KAFKA_SECRETS_DIR | Out-Null }

Copy-Item $keystore -Destination $KAFKA_SECRETS_DIR -Force
Copy-Item $truststore -Destination $KAFKA_SECRETS_DIR -Force

Set-Content -Path (Join-Path $KAFKA_SECRETS_DIR "ssl_keystore_password") -Value "secret" -NoNewline
Set-Content -Path (Join-Path $KAFKA_SECRETS_DIR "ssl_key_password") -Value "secret" -NoNewline
Set-Content -Path (Join-Path $KAFKA_SECRETS_DIR "ssl_truststore_password") -Value "secret" -NoNewline

$zookeeper_jaas = @"
Server {
    org.apache.zookeeper.server.auth.DigestLoginModule required
    user_kafka="kafka-secret";
};
"@
Set-Content -Path (Join-Path $KAFKA_SECRETS_DIR "zookeeper_jaas.conf") -Value $zookeeper_jaas -Encoding ASCII

$kafka_server_jaas = @"
KafkaServer {
    org.apache.kafka.common.security.scram.ScramLoginModule required;
};

Client {
    org.apache.zookeeper.server.auth.DigestLoginModule required
    username="kafka"
    password="kafka-secret";
};
"@
Set-Content -Path (Join-Path $KAFKA_SECRETS_DIR "kafka_server_jaas.conf") -Value $kafka_server_jaas -Encoding ASCII

Write-Host "[2/5] Archivos de secretos listos."

# -------------------------------------------------------
# 3. Levantar stack
# -------------------------------------------------------
if ($env:SKIP_START -eq "1") {
    Write-Host "`n============================================="
    Write-Host "  [SKIP_START=1] Solo se generaron certs."
    Write-Host "============================================="
    exit 0
}

Write-Host "`n[3/5] Levantando stack Strimzi..."
Set-Location $REPO_ROOT

# Detiene y limpia solo Strimzi
& docker compose -f docker-compose-services.yml stop kafka-strimzi-init kafka-strimzi zookeeper-strimzi kafka-ui 2>&1 | Out-Null
& docker compose -f docker-compose-services.yml rm -f kafka-strimzi-init kafka-strimzi zookeeper-strimzi 2>&1 | Out-Null

# Levanta contenedores
& docker compose -f docker-compose-services.yml up -d zookeeper-strimzi kafka-strimzi kafka-strimzi-init

Write-Host "Esperando a que Kafka esté disponible (máx 120s)..."
$KAFKA_READY = $false
for ($i = 1; $i -le 60; $i++) {
    $result = & docker exec kafka-strimzi kafka-broker-api-versions --bootstrap-server localhost:9097 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Kafka disponible en el intento $i" -ForegroundColor Green
        $KAFKA_READY = $true
        break
    }
    Write-Host "  intento $i/60..."
    Start-Sleep -Seconds 2
}

if (-not $KAFKA_READY) {
    Write-Host "[ERROR] Kafka no respondió en 120s. Últimos logs:" -ForegroundColor Red
    & docker compose -f docker-compose-services.yml logs kafka-strimzi | Select-Object -Last 20
    exit 1
}

# -------------------------------------------------------
# 4. Reiniciar kafka-ui
# -------------------------------------------------------
Write-Host "`n[4/5] Reiniciando kafka-ui..."
& docker compose -f docker-compose-services.yml up -d kafka-ui --force-recreate 2>&1 | Out-Null

# -------------------------------------------------------
# 5. Actualizar secreto en LocalStack
# -------------------------------------------------------
Write-Host "`n[5/5] Actualizando secreto en LocalStack..."
$certContent = & keytool -exportcert -alias $ALIAS -keystore "$KAFKA_SECRETS_DIR\kafka.truststore.jks" -storepass secret -noprompt -rfc 2>&1
$certContentStr = $certContent -join "`n"

$secretObj = @{
    username = $KAFKA_USER
    password = $KAFKA_PASS
    bootstrapServer = "localhost:9095"
    certificate = $certContentStr.Trim()
}
$SECRET_JSON = $secretObj | ConvertTo-Json -Depth 10 -Compress

if (Get-Command aws -ErrorAction SilentlyContinue) {
    # Ejecutamos creación. Si falla, es porque ya existe, entonces ejecutamos el update (put-secret-value)
    $createResult = & aws --endpoint-url="$LOCALSTACK_ENDPOINT" --region us-east-1 secretsmanager create-secret --name $SECRET_NAME --secret-string $SECRET_JSON 2>&1
    if ($LASTEXITCODE -ne 0) {
        & aws --endpoint-url="$LOCALSTACK_ENDPOINT" --region us-east-1 secretsmanager put-secret-value --secret-id $SECRET_NAME --secret-string $SECRET_JSON 2>&1 | Out-Null
    }
    Write-Host "  ✅ Secreto '$SECRET_NAME' actualizado en LocalStack"
} else {
    Write-Host "  ⚠️  AWS CLI no encontrado — secreto NO actualizado en LocalStack." -ForegroundColor Yellow
}

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "  ✅ Kafka Strimzi Mock listo" -ForegroundColor Green
Write-Host "---------------------------------------------"
Write-Host "  SASL_SSL  (clientes externos) -> localhost:9095"
Write-Host "  PLAINTEXT (interno/UI)        -> localhost:9097"
Write-Host "  Usuario   : $KAFKA_USER"
Write-Host "  Password  : $KAFKA_PASS"
Write-Host "  Tópico    : $KAFKA_TOPIC"
Write-Host "  Kafka UI  : http://localhost:9091  (cluster: strimzi-mock)"
Write-Host "  Secreto   : $SECRET_NAME"
Write-Host "=============================================" -ForegroundColor Cyan
