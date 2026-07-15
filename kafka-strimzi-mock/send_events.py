#!/Applications/Xcode.app/Contents/Developer/usr/bin/python3
# -*- coding: utf-8 -*-


import argparse
import copy
import json
import os
import site
import sys
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
CERT_PEM_PATH    = Path(__file__).parent / "kafka-secrets" / "ca.pem"   # generado abajo

EVENT_MAPPING = {
    #"Emision.json": [
    #    "debtSecuritiesBondIssueRegistration.bondIssueRegisteredv1",
    #],
    "LiquidacionApertura.json": [
        "debtSecuritiesInitialCapitalization.debtCapitalOpenedv1",
    ],
    #"CausacionIntereses.json": [
    #    "debtSecuritiesInterest.interestAccruedv1",
    #],
    #"ExigibilidadIntereses.json": [
    #    "debtSecuritiesInterest.interestSettledv",
    #],
    #"PagoIntereses.json": [
    #    "debtSecuritiesInterest.interestPaidv1",
    #],
    #"ConfirmacionPagoIntereses.json": [
    #    "paymentConfirmation.maturityPaymentConfirmedv1",
    #],
    #"Pago Intereses (GMF Gasto).json": [
    #    "debtSecuritiesInterest.interestPaidv1",
    #],
    #"Vencimiento.json": [
    #    "paymentConfirmation.maturityPaymentConfirmedv1",
    #],
}

EXAMPLES_DIR = Path(__file__).parent / "EjemplosJson"


def extract_cert_pem() -> Path:
    """Exporta el certificado del truststore JKS a un PEM temporal para kafka-python."""
    import subprocess
    pem_path = CERT_PEM_PATH
    result = subprocess.run(
        [
            "keytool", "-exportcert",
            "-alias", "kafka2",
            "-keystore", str(TRUSTSTORE_PATH),
            "-storepass", "secret",
            "-noprompt", "-rfc",
        ],
        capture_output=True, text=True,
    )
    if result.returncode != 0 or "BEGIN CERTIFICATE" not in result.stdout:
        print(f"[ERROR] No se pudo exportar el certificado del truststore: {result.stderr}")
        sys.exit(1)
    pem_path.write_text(result.stdout)
    return pem_path


def build_producer(cert_pem: Path):
    """Crea el KafkaProducer con SASL_SSL."""
    try:
        from kafka import KafkaProducer
    except ImportError:
        print("[ERROR] Falta kafka-python. Instala con:  pip install kafka-python")
        sys.exit(1)

    try:
        producer = KafkaProducer(
            bootstrap_servers=[BOOTSTRAP_SERVER],
            security_protocol="SASL_SSL",
            sasl_mechanism="SCRAM-SHA-512",
            sasl_plain_username=SASL_USERNAME,
            sasl_plain_password=SASL_PASSWORD,
            ssl_cafile=str(cert_pem),
            ssl_check_hostname=False,
            value_serializer=lambda v: json.dumps(v, ensure_ascii=False).encode("utf-8"),
            key_serializer=lambda k: k.encode("utf-8") if k else None,
            acks="all",
            retries=3,
        )
        return producer
    except Exception as e:
        if "NoBrokers" in type(e).__name__ or "connect" in str(e).lower():
            print(f"[ERROR] No se puede conectar a {BOOTSTRAP_SERVER}.")
            print("  Verifica que kafka-strimzi esté corriendo: docker ps | grep kafka-strimzi")
        else:
            print(f"[ERROR] Al crear el producer: {e}")
        sys.exit(1)


def stamp_message(payload: dict) -> dict:
    """Reemplaza el id y time del metadata para que cada envío sea único."""
    if "metadata" in payload:
        payload["metadata"]["id"] = str(uuid.uuid4())
        # payload["metadata"]["time"] = datetime.now(timezone.utc).isoformat()
    return payload


def send(producer, topic: str, payload: dict, dry_run: bool) -> None:
    msg_id = payload.get("metadata", {}).get("id", "???")
    event_type = payload.get("metadata", {}).get("type", "???")
    if dry_run:
        print(f"  [DRY-RUN]  tópico={topic}  id={msg_id}  type={event_type}")
        return

    future = producer.send(topic, key=msg_id, value=payload)
    record = future.get(timeout=10)
    print(f"  ✅  tópico={topic}  partition={record.partition}  offset={record.offset}  id={msg_id}")


def main():
    parser = argparse.ArgumentParser(description="Envía EjemplosJson al Kafka Strimzi Mock")
    parser.add_argument("--file",    help="Nombre del archivo JSON (ej: Emision.json). Sin esto envía todos.")
    parser.add_argument("--topic",   help="Tópico destino. Requerido si se usa --file.")
    parser.add_argument("--dry-run", action="store_true", help="Muestra qué se enviaría sin enviar nada.")
    args = parser.parse_args()

    if args.file and not args.topic:
        parser.error("--topic es requerido cuando se usa --file")

    if args.file:
        file_path = EXAMPLES_DIR / args.file
        if not file_path.exists():
            print(f"[ERROR] No se encontró {file_path}")
            sys.exit(1)
        jobs = [(file_path, [args.topic])]
    else:
        jobs = []
        for filename, topics in EVENT_MAPPING.items():
            fp = EXAMPLES_DIR / filename
            if fp.exists():
                jobs.append((fp, topics))
            else:
                print(f"  [WARN] No encontrado: {fp} — se omite")

    if not jobs:
        print("[ERROR] No hay archivos para enviar.")
        sys.exit(1)

    print("=" * 60)
    print(f"  Kafka Strimzi Mock — Envío de eventos")
    print(f"  Broker : {BOOTSTRAP_SERVER}")
    print(f"  Usuario: {SASL_USERNAME}")
    print(f"  Modo   : {'DRY-RUN (sin enviar)' if args.dry_run else 'PRODUCCIÓN'}")
    print("=" * 60)

    producer = None
    if not args.dry_run:
        if not TRUSTSTORE_PATH.exists():
            print(f"[ERROR] No se encontró {TRUSTSTORE_PATH}")
            print("  Ejecuta primero:  bash kafka-strimzi-mock/start.sh")
            sys.exit(1)
        cert_pem = extract_cert_pem()
        producer = build_producer(cert_pem)

    total_ok = 0
    total_err = 0

    for file_path, topics in jobs:
        print(f"\n📄 {file_path.name}")
        try:
            payload = json.loads(file_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            print(f"  [ERROR] JSON inválido en {file_path.name}: {e}")
            total_err += 1
            continue

        for topic in topics:
            stamped = stamp_message(copy.deepcopy(payload))
            try:
                send(producer, topic, stamped, args.dry_run)
                total_ok += 1
            except Exception as e:
                print(f"  ❌  tópico={topic}  error={e}")
                total_err += 1

    if producer:
        producer.flush()
        producer.close()

    print("\n" + "=" * 60)
    print(f"  Enviados OK : {total_ok}")
    print(f"  Errores     : {total_err}")
    print("=" * 60)

    if total_err:
        sys.exit(1)


if __name__ == "__main__":
    main()
