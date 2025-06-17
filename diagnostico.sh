#!/bin/bash
echo "🔍 DIAGNÓSTICO DASHBOARD WEB - TRANSMISIÓN DRONE"
echo "==============================================="

# 1. Verificar que el stream HLS esté disponible
echo "1. VERIFICANDO STREAM HLS DISPONIBLE:"
curl -I http://localhost:8080/hls/canal1.m3u8 && echo "✅ Stream HLS disponible" || echo "❌ Stream HLS no disponible"

# 2. Verificar dashboard web
echo -e "\n2. VERIFICANDO DASHBOARD WEB:"
curl -I http://localhost:3000 && echo "✅ Dashboard accesible" || echo "❌ Dashboard no accesible"

# 3. Verificar logs del contenedor web
echo -e "\n3. LOGS DEL DASHBOARD:"
docker compose logs web --tail 10

echo -e "\n📋 SIGUIENTE PASO: Abre la consola del navegador en http://161.10.191.239:3000"
echo "y comparte los errores de JavaScript que aparezcan."
