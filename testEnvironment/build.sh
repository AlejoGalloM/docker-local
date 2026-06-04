#!/bin/bash

echo "======================================"
echo "Reconstruyendo imagen de Go con nuevos mensajes"
echo "======================================"

# 1. Detener y eliminar el contenedor de Go si está corriendo
echo ""
echo "🛑 Deteniendo contenedor de Go..."
docker-compose -f mq-go-compose.yaml stop gonu0145001_iastacceleratorgateway_mr
docker-compose -f mq-go-compose.yaml rm -f gonu0145001_iastacceleratorgateway_mr

# 2. Eliminar la imagen anterior
echo ""
echo "🗑️  Eliminando imagen anterior..."
docker rmi gonu0145001_iastacceleratorgateway_mr:test 2>/dev/null || echo "ℹ️  No hay imagen anterior para eliminar"

# 3. Construir nueva imagen con los mensajes actualizados
echo ""
echo "🔨 Construyendo nueva imagen de Go (la compilación se hace dentro del Docker)..."
docker build --platform linux/amd64 -t gonu0145001_iastacceleratorgateway_mr:test -f Dockerfile_go .

if [ $? -ne 0 ]; then
    echo "❌ Error al construir la imagen Docker"
    exit 1
fi

echo "✅ Imagen construida exitosamente"

# 4. Levantar el contenedor nuevamente
echo ""
echo "🚀 Levantando contenedor de Go..."
docker-compose -f mq-go-compose.yaml up -d gonu0145001_iastacceleratorgateway_mr

if [ $? -ne 0 ]; then
    echo "❌ Error al levantar el contenedor"
    exit 1
fi

echo ""
echo "======================================"
echo "✅ Proceso completado exitosamente"
echo "======================================"
echo ""
echo "📊 Estado de los contenedores:"
docker-compose -f mq-go-compose.yaml ps

echo ""
echo "📝 Para ver los logs del contenedor de Go:"
echo "   docker logs -f gonu0145001_iastacceleratorgateway_mr"