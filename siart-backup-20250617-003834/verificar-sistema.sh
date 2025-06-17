#!/bin/bash
echo "🔍 VERIFICACIÓN DEL SISTEMA SIART"
echo "================================"

echo "1. Estado de contenedores:"
docker compose ps

echo -e "\n2. Verificación de servicios:"
curl -I http://192.168.1.8:8080/hls/canal1/index.m3u8 2>/dev/null && echo "✅ HLS funcionando" || echo "❌ HLS no disponible"
curl -I http://192.168.1.8:3000 2>/dev/null && echo "✅ Dashboard funcionando" || echo "❌ Dashboard no disponible"

echo -e "\n3. Logs recientes:"
docker compose logs web --tail 5
docker compose logs rtmp --tail 5

echo -e "\n📋 Si todos los servicios muestran ✅, el sistema está operativo"
