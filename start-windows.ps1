# ================================================================
# start-windows.ps1
# Script de arranque para Windows — auto-detecta el runtime
# Uso: .\start-windows.ps1 [up|down|ps|logs]
# ================================================================

param(
    [string]$Action = "up"
)

$ComposeFile = "docker-compose-services-windows.yml"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Docker Local — Windows Startup Script " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ── Detectar runtime disponible ──────────────────────────────────
$Runtime   = $null
$ComposeCli = $null

if (Get-Command "docker" -ErrorAction SilentlyContinue) {
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -eq 0) {
        $Runtime    = "docker"
        $ComposeCli = "docker compose"
        Write-Host "[OK] Runtime detectado: Docker / Rancher Desktop (dockerd)" -ForegroundColor Green
    }
}

if (-not $Runtime -and (Get-Command "nerdctl" -ErrorAction SilentlyContinue)) {
    $nerdInfo = nerdctl info 2>&1
    if ($LASTEXITCODE -eq 0) {
        $Runtime    = "nerdctl"
        $ComposeCli = "nerdctl compose"
        Write-Host "[OK] Runtime detectado: Rancher Desktop (containerd / nerdctl)" -ForegroundColor Green
    }
}

if (-not $Runtime -and (Get-Command "podman" -ErrorAction SilentlyContinue)) {
    $podmanInfo = podman info 2>&1
    if ($LASTEXITCODE -eq 0) {
        $Runtime    = "podman"
        $ComposeCli = "podman-compose"
        Write-Host "[OK] Runtime detectado: Podman Desktop" -ForegroundColor Green
    }
}

if (-not $Runtime) {
    Write-Host "[ERROR] No se encontro ningun runtime (docker, nerdctl, podman)." -ForegroundColor Red
    Write-Host "        Instala Rancher Desktop o Podman Desktop y vuelve a intentarlo." -ForegroundColor Yellow
    exit 1
}

# ── Detectar socket del daemon ────────────────────────────────────
# Dentro de WSL2 los contenedores ven el socket en rutas Unix.
# Ejecutamos wsl para detectar cual socket existe en WSL2.

$WslAvailable = Get-Command "wsl" -ErrorAction SilentlyContinue

if ($WslAvailable) {
    $DetectedSocket = wsl -- sh -c @"
for sock in /var/run/docker.sock /run/podman/podman.sock /run/user/1000/podman/podman.sock /run/k3s/containerd/containerd.sock; do
    if [ -S "\$sock" ]; then echo "\$sock"; break; fi
done
"@
    if ($DetectedSocket) {
        $DetectedSocket = $DetectedSocket.Trim()
        Write-Host "[OK] Socket detectado en WSL2: $DetectedSocket" -ForegroundColor Green
        $env:DOCKER_SOCKET = $DetectedSocket
        $env:DOCKER_HOST   = "unix://$DetectedSocket"
    } else {
        Write-Host "[WARN] No se encontro socket en WSL2. Usando fallback." -ForegroundColor Yellow
        $env:DOCKER_SOCKET = "/var/run/docker.sock"
        $env:DOCKER_HOST   = "unix:///var/run/docker.sock"
    }
} else {
    # Sin WSL2 — Rancher con dockerd nativo en Windows usa named pipe
    Write-Host "[INFO] WSL2 no disponible. Usando named pipe de Docker." -ForegroundColor Yellow
    $env:DOCKER_SOCKET = "/var/run/docker.sock"
    $env:DOCKER_HOST   = "npipe:////./pipe/docker_engine"
}

Write-Host ""
Write-Host "  DOCKER_HOST   = $($env:DOCKER_HOST)" -ForegroundColor DarkCyan
Write-Host "  DOCKER_SOCKET = $($env:DOCKER_SOCKET)" -ForegroundColor DarkCyan
Write-Host "  Compose CLI   = $ComposeCli" -ForegroundColor DarkCyan
Write-Host ""

# ── Ejecutar compose ──────────────────────────────────────────────
$ComposeArgs = switch ($Action) {
    "up"   { "-f $ComposeFile up -d" }
    "down" { "-f $ComposeFile down" }
    "ps"   { "-f $ComposeFile ps" }
    "logs" { "-f $ComposeFile logs -f" }
    default { "-f $ComposeFile $Action" }
}

Write-Host "Ejecutando: $ComposeCli $ComposeArgs" -ForegroundColor White
Write-Host ""

Invoke-Expression "$ComposeCli $ComposeArgs"
