#!/usr/bin/env bash
# ================================================================
# start-windows.sh
# Script de arranque para WSL2 / bash en Windows
# Auto-detecta runtime (docker, nerdctl, podman) y socket correcto
#
# Uso:
#   bash start-windows.sh [up|down|ps|logs]
#   chmod +x start-windows.sh && ./start-windows.sh
# ================================================================

set -euo pipefail

ACTION="${1:-up}"
COMPOSE_FILE="docker-compose-services-windows.yml"

echo ""
echo "========================================"
echo "  Docker Local — Windows Startup Script"
echo "========================================"
echo ""

# ── Detectar socket disponible ────────────────────────────────────
detect_socket() {
    for sock in \
        /var/run/docker.sock \
        /run/podman/podman.sock \
        "/run/user/$(id -u)/podman/podman.sock" \
        /run/k3s/containerd/containerd.sock; do
        if [ -S "$sock" ]; then
            echo "$sock"
            return
        fi
    done
    echo ""
}

DOCKER_SOCKET="$(detect_socket)"

if [ -z "$DOCKER_SOCKET" ]; then
    echo "[ERROR] No se encontro ningun socket de contenedor activo."
    echo "        Asegurate de que Rancher Desktop o Podman Desktop esten corriendo."
    exit 1
fi

export DOCKER_SOCKET
export DOCKER_HOST="unix://$DOCKER_SOCKET"

echo "[OK] Socket detectado: $DOCKER_SOCKET"
echo "     DOCKER_HOST = $DOCKER_HOST"
echo ""

# ── Detectar runtime y CLI de compose ────────────────────────────
RUNTIME=""
COMPOSE_CLI=""

if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    RUNTIME="docker"
    COMPOSE_CLI="docker compose"
    echo "[OK] Runtime: Docker / Rancher Desktop (dockerd)"
elif command -v nerdctl &>/dev/null && nerdctl info &>/dev/null 2>&1; then
    RUNTIME="nerdctl"
    COMPOSE_CLI="nerdctl compose"
    echo "[OK] Runtime: Rancher Desktop (containerd / nerdctl)"
elif command -v podman &>/dev/null && podman info &>/dev/null 2>&1; then
    RUNTIME="podman"
    COMPOSE_CLI="podman-compose"
    echo "[OK] Runtime: Podman Desktop"
else
    echo "[ERROR] No se encontro runtime disponible (docker, nerdctl, podman)."
    exit 1
fi

echo "     Compose CLI = $COMPOSE_CLI"
echo ""

# ── Ejecutar compose ──────────────────────────────────────────────
case "$ACTION" in
    up)
        echo "Levantando servicios en background..."
        $COMPOSE_CLI -f "$COMPOSE_FILE" up -d
        ;;
    down)
        echo "Bajando servicios..."
        $COMPOSE_CLI -f "$COMPOSE_FILE" down
        ;;
    ps)
        $COMPOSE_CLI -f "$COMPOSE_FILE" ps
        ;;
    logs)
        $COMPOSE_CLI -f "$COMPOSE_FILE" logs -f
        ;;
    *)
        $COMPOSE_CLI -f "$COMPOSE_FILE" "$@"
        ;;
esac
