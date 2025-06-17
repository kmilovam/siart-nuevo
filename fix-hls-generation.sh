#!/bin/bash
echo "🔧 CORRIGIENDO GENERACIÓN HLS - SIART"

# Verificar y recrear directorio HLS
docker compose exec rtmp mkdir -p /tmp/hls
docker compose exec rtmp chmod 755 /tmp/hls

# Reiniciar servicio RTMP para aplicar permisos
docker compose restart rtmp

# Verificar configuración nginx
docker compose exec rtmp nginx -t

echo "✅ Corrección aplicada. Reinicia la transmisión del drone."
