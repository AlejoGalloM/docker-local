#!/Applications/Xcode.app/Contents/Developer/usr/bin/python3
# -*- coding: utf-8 -*-

import argparse
import copy
import json
import random
import site
import sys
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path

_user_site = site.getusersitepackages() if hasattr(site, "getusersitepackages") else ""
if isinstance(_user_site, str) and _user_site and _user_site not in sys.path:
    sys.path.insert(0, _user_site)
elif isinstance(_user_site, list):
    for _sp in _user_site:
        if _sp not in sys.path:
            sys.path.insert(0, _sp)

BOOTSTRAP_SERVER = "localhost:9095"
SASL_USERNAME    = "local-user"
SASL_PASSWORD    = "local-password"
TRUSTSTORE_PATH  = Path(__file__).parent / "kafka-secrets" / "kafka.truststore.jks"
CERT_PEM_PATH    = Path(__file__).parent / "kafka-secrets" / "ca.pem"

EVENT_MAPPING = {
    "Emision.json": ["debtsecuritiesbondissueregistration.bondissueregisteredv1"],
    "LiquidacionApertura.json": ["debtsecuritiesinitialcapitalization.debtcapitalopenedv1"],
    "CausacionIntereses.json": ["debtsecuritiesinterest.interestaccruedv1"],
    "ExigibilidadIntereses.json": ["debtsecuritiesinterest.interestsettledv1"],
    "PagoIntereses.json": ["debtsecuritiesinterest.interestpaidv1"],
    "ConfirmacionPagoIntereses.json": ["paymentconfirmation.maturitypaymentconfirmedv1"],
    "Vencimiento.json": ["paymentconfirmation.maturitypaymentconfirmedv1"],
}

EXAMPLES_DIR = Path(__file__).parent / "EjemplosJson"

def extract_cert_pem() -> Path:
    import subprocess
    pem_path = CERT_PEM_PATH
    result = subprocess.run(
        [
            "keytool", "-exportcert", "-alias", "kafka2",
            "-keystore", str(TRUSTSTORE_PATH), "-storepass", "secret",
            "-noprompt", "-rfc",
        ],
        capture_output=True, text=True,
    )
    if result.returncode != 0 or "BEGIN CERTIFICATE" not in result.stdout:
        print(f"[ERROR] No se pudo exportar el certificado: {result.stderr}")
        sys.exit(1)
    pem_path.write_text(result.stdout)
    return pem_path

def build_producer(cert_pem: Path):
    try:
        from kafka import KafkaProducer
    except ImportError:
        print("[ERROR] Falta kafka-python. Instala con: pip install kafka-python")
        sys.exit(1)
    try:
        return KafkaProducer(
            bootstrap_servers=[BOOTSTRAP_SERVER],
            security_protocol="SASL_SSL",
            sasl_mechanism="SCRAM-SHA-512",
            sasl_plain_username=SASL_USERNAME,
            sasl_plain_password=SASL_PASSWORD,
            ssl_cafile=str(cert_pem),
            ssl_check_hostname=False,
            value_serializer=lambda v: json.dumps(v, ensure_ascii=False).encode("utf-8"),
            key_serializer=lambda k: k.encode("utf-8") if k else None,
            acks=1, # Para más velocidad en bulk
        )
    except Exception as e:
        print(f"[ERROR] Al crear el producer: {e}")
        sys.exit(1)

def stamp_message(payload: dict) -> dict:
    if "metadata" in payload:
        payload["metadata"]["id"] = str(uuid.uuid4())
        
    if "data" in payload:
        data = payload["data"]
        # Actualizar groupHeader.messageIdentification si existe
        if "groupHeader" in data and "messageIdentification" in data["groupHeader"]:
            data["groupHeader"]["messageIdentification"] = str(uuid.uuid4())
            
        # Actualizar transaction.identification si existe
        if "transaction" in data and "identification" in data["transaction"]:
            data["transaction"]["identification"] = str(uuid.uuid4())
            
        # Actualizar emissionId si existe
        if "securityIssuanceRequest" in data:
            try:
                data["securityIssuanceRequest"]["security"]["financialInstrumentIdentification"]["emissionId"] = f"EMISION_{uuid.uuid4().hex[:8].upper()}"
            except KeyError:
                pass

    return payload

def main():
    parser = argparse.ArgumentParser(description="Envía un flujo constante de eventos para medir Consume Rate")
    parser.add_argument("--rate", type=int, default=50, help="Eventos por segundo")
    parser.add_argument("--duration", type=int, default=30, help="Duración de la prueba en segundos")
    args = parser.parse_args()

    # Cargar todos los payloads en memoria
    available_jobs = []
    for filename, topics in EVENT_MAPPING.items():
        fp = EXAMPLES_DIR / filename
        if fp.exists():
            try:
                payload = json.loads(fp.read_text(encoding="utf-8"))
                for topic in topics:
                    available_jobs.append((topic, payload))
            except Exception:
                pass

    if not available_jobs:
        print("[ERROR] No se encontraron archivos JSON válidos.")
        sys.exit(1)

    print("=" * 60)
    print("  🚀 Prueba de Carga Kafka Strimzi Mock 🚀")
    print(f"  Rate     : {args.rate} msg/seg")
    print(f"  Duración : {args.duration} segundos")
    print(f"  Total    : {args.rate * args.duration} eventos esperados")
    print("=" * 60)

    if not TRUSTSTORE_PATH.exists():
        print(f"[ERROR] No se encontró {TRUSTSTORE_PATH}")
        sys.exit(1)
    
    cert_pem = extract_cert_pem()
    producer = build_producer(cert_pem)

    total_sent = 0
    total_duplicates = 0
    total_errors_sent = 0
    original_events_sent = 0
    start_time = time.time()
    end_time = start_time + args.duration
    sleep_interval = 1.0 / args.rate

    try:
        while time.time() < end_time:
            loop_start = time.time()
            
            # Elegir un evento al azar
            topic, payload = random.choice(available_jobs)
            stamped = stamp_message(copy.deepcopy(payload))
            msg_id = stamped.get("metadata", {}).get("id", "bulk")
            
            producer.send(topic, key=msg_id, value=stamped)
            total_sent += 1
            original_events_sent += 1
            
            # Cada 50 eventos originales, enviar entre 1 y 5 repetidos
            if original_events_sent % 50 == 0:
                duplicates_to_send = random.randint(1, 5)
                for _ in range(duplicates_to_send):
                    producer.send(topic, key=msg_id, value=stamped)
                    total_sent += 1
                    total_duplicates += 1
                    
            # Cada 100 eventos originales, enviar uno malo (sin metadata)
            if original_events_sent % 100 == 0:
                bad_payload = copy.deepcopy(stamped)
                if "metadata" in bad_payload:
                    del bad_payload["metadata"]
                producer.send(topic, key="error-no-metadata", value=bad_payload)
                total_sent += 1
                total_errors_sent += 1
            
            # Imprimir progreso cada 100 mensajes originales
            if original_events_sent % 100 == 0:
                print(f"  -> {total_sent} eventos enviados (incluyendo duplicados y errores)...")
                
            # Mantener la tasa constante
            elapsed = time.time() - loop_start
            if elapsed < sleep_interval:
                time.sleep(sleep_interval - elapsed)
                
    except KeyboardInterrupt:
        print("\n[WARN] Detenido por el usuario.")

    print("\n[INFO] Haciendo flush final (esperando a que Kafka reciba todo)...")
    producer.flush()
    producer.close()

    actual_duration = time.time() - start_time
    print("=" * 60)
    print(f"  ✅ Prueba terminada")
    print(f"  Total Enviados : {total_sent}")
    print(f"  Total Originales: {original_events_sent}")
    print(f"  Total Repetidos: {total_duplicates}")
    print(f"  Total Errores  : {total_errors_sent}")
    print(f"  Tiempo Real    : {actual_duration:.2f} segundos")
    print(f"  Rate Promedio  : {total_sent / actual_duration:.2f} msg/seg")
    print("=" * 60)

if __name__ == "__main__":
    main()