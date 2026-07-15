#!/bin/bash
# =============================================================================
#  inject-event.sh  –  Inyecta eventos al Kafka Strimzi Mock (local)
#
#  Uso:
#    ./inject-event.sh                              → lista los ejemplos disponibles
#    ./inject-event.sh Emision                      → envía Emision.json
#    ./inject-event.sh CausacionIntereses           → envía CausacionIntereses.json
#    ./inject-event.sh Emision 5                    → envía Emision.json 5 veces
#    ./inject-event.sh '{"id":"x","data":{}}'       → envía JSON inline
#    TOPIC=otro-topico ./inject-event.sh Emision    → cambia el tópico destino
#
#  Ejemplos disponibles en:  ./kafka-strimzi-mock/EjemplosJson/
# =============================================================================

TOPIC="${TOPIC:-test-with-registries}"
CONTAINER="kafka-strimzi-mock"
EJEMPLOS_DIR="$(dirname "$0")/kafka-strimzi-mock/EjemplosJson"
COUNT="${2:-1}"

# Colores
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

# --------------------------------------------------
# Sin argumentos → listar ejemplos disponibles
# --------------------------------------------------
if [ -z "$1" ]; then
  echo -e "${CYAN}📂 Ejemplos disponibles en: $EJEMPLOS_DIR${NC}"
  echo ""
  i=1
  for f in "$EJEMPLOS_DIR"/*.json; do
    NAME=$(basename "$f" .json)
    SIZE=$(wc -c < "$f" | tr -d ' ')
    echo -e "  ${GREEN}$i)${NC} $NAME  ${YELLOW}(${SIZE} bytes)${NC}"
    i=$((i+1))
  done
  echo ""
  echo -e "Uso: ${CYAN}./inject-event.sh <NombreEjemplo> [cantidad]${NC}"
  echo -e "     ${CYAN}./inject-event.sh Emision${NC}"
  echo -e "     ${CYAN}./inject-event.sh CausacionIntereses 3${NC}"
  exit 0
fi

# --------------------------------------------------
# Determinar el payload
# --------------------------------------------------
# Si el argumento empieza con '{', es JSON inline
if [[ "$1" == {* ]]; then
  PAYLOAD="$1"
  PAYLOAD_NAME="(JSON inline)"
else
  # Buscar el archivo (con o sin .json)
  JSON_FILE=""
  # Búsqueda exacta primero
  if [ -f "$EJEMPLOS_DIR/$1.json" ]; then
    JSON_FILE="$EJEMPLOS_DIR/$1.json"
  elif [ -f "$EJEMPLOS_DIR/$1" ]; then
    JSON_FILE="$EJEMPLOS_DIR/$1"
  else
    # Búsqueda case-insensitive
    JSON_FILE=$(find "$EJEMPLOS_DIR" -iname "$1.json" -o -iname "$1" 2>/dev/null | head -1)
  fi

  if [ -z "$JSON_FILE" ]; then
    echo -e "${RED}❌ Ejemplo '$1' no encontrado en $EJEMPLOS_DIR${NC}"
    echo ""
    echo "Ejemplos disponibles:"
    for f in "$EJEMPLOS_DIR"/*.json; do echo "  - $(basename "$f" .json)"; done
    exit 1
  fi

  # Leer y comprimir el JSON (remover \r y saltos de línea)
  PAYLOAD=$(tr -d '\r' < "$JSON_FILE" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)))" 2>/dev/null)
  if [ -z "$PAYLOAD" ]; then
    echo -e "${RED}❌ Error al leer el JSON de '$JSON_FILE'${NC}"
    exit 1
  fi
  PAYLOAD_NAME=$(basename "$JSON_FILE")
fi

# --------------------------------------------------
# Validar que el contenedor está corriendo
# --------------------------------------------------
if ! docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null | grep -q "true"; then
  echo -e "${RED}❌ El contenedor '$CONTAINER' no está corriendo.${NC}"
  echo "   Levántalo con: docker compose -f docker-compose-services.yml up -d kafka-strimzi-mock"
  exit 1
fi

# --------------------------------------------------
# Inyectar
# --------------------------------------------------
echo -e "${CYAN}📤 Inyectando ${COUNT} evento(s) al tópico '${TOPIC}'${NC}"
echo -e "   📄 Archivo : ${YELLOW}${PAYLOAD_NAME}${NC}"
echo -e "   🐳 Container: ${CONTAINER}"
echo -e "   📡 Broker  : localhost:9097 (PLAINTEXT interno)"
echo ""

SUCCESS=0
for i in $(seq 1 "$COUNT"); do
  RESULT=$(echo "$PAYLOAD" | docker exec -i "$CONTAINER" \
    kafka-console-producer \
    --bootstrap-server localhost:9097 \
    --topic "$TOPIC" 2>&1)

  if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✅ Evento $i/$COUNT enviado OK${NC}"
    SUCCESS=$((SUCCESS + 1))
  else
    echo -e "  ${RED}❌ Evento $i/$COUNT falló: $RESULT${NC}"
  fi
done

echo ""
echo -e "${CYAN}📊 Resultado: ${GREEN}$SUCCESS${CYAN}/${COUNT} eventos enviados al tópico '${TOPIC}'${NC}"
echo ""
echo -e "${YELLOW}🔍 Para verificar que llegaron:${NC}"
echo "   docker exec -it $CONTAINER kafka-console-consumer \\"
echo "     --bootstrap-server localhost:9097 \\"
echo "     --topic $TOPIC \\"
echo "     --from-beginning \\"
echo "     --max-messages $COUNT"
