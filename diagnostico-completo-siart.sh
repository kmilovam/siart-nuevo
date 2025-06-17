#!/bin/bash
echo "🔍 DIAGNÓSTICO COMPLETO TRANSMISIÓN DRONE - SIART"
echo "================================================"

# 1. Verificar estado de contenedores
echo "1. ESTADO DE CONTENEDORES:"
echo "-------------------------"
docker compose ps

# 2. Verificar logs RTMP con patrones específicos
echo -e "\n2. LOGS RTMP (ÚLTIMAS 30 LÍNEAS):"
echo "--------------------------------"
docker compose logs rtmp --tail 30

# 3. Verificar estadísticas del servidor RTMP
echo -e "\n3. ESTADÍSTICAS RTMP:"
echo "--------------------"
curl -s http://localhost:8080/stat 2>/dev/null || echo "Error: No se puede acceder a estadísticas"

# 4. Verificar archivos HLS generados
echo -e "\n4. CONTENIDO DIRECTORIO HLS:"
echo "---------------------------"
docker compose exec rtmp ls -la /tmp/hls/ 2>/dev/null || echo "Error: No se puede acceder al directorio HLS"

# 5. Verificar permisos del directorio HLS
echo -e "\n5. PERMISOS Y PROPIETARIO HLS:"
echo "-----------------------------"
docker compose exec rtmp stat /tmp/hls/ 2>/dev/null || echo "Error: No se puede verificar permisos"

# 6. Probar acceso directo a archivos HLS
echo -e "\n6. PRUEBA DE ACCESO HLS:"
echo "----------------------"
echo "Intentando acceder a canal1.m3u8..."
curl -I http://localhost:8080/hls/canal1.m3u8 2>/dev/null || echo "Error: Archivo HLS no encontrado"

# 7. Verificar configuración nginx actual
echo -e "\n7. CONFIGURACIÓN NGINX ACTUAL:"
echo "-----------------------------"
docker compose exec rtmp nginx -T 2>/dev/null | grep -A 20 "application\|hls" || echo "Error: No se puede verificar configuración"

# 8. Verificar procesos FFmpeg activos
echo -e "\n8. PROCESOS FFMPEG:"
echo "-----------------"
docker compose exec rtmp ps aux | grep ffmpeg || echo "No hay procesos FFmpeg activos"

echo -e "\n📋 RESUMEN DE PROBLEMAS DETECTADOS:"
echo "===================================="
echo "- Si /tmp/hls está vacío: Problema de generación HLS"
echo "- Si no hay procesos FFmpeg: Falta configuración exec"
echo "- Si nginx -T falla: Error de configuración"
echo "- Si stats no muestra streams: Problema de recepción RTMP"

echo -e "\n🔧 EJECUTA SIGUIENTE SCRIPT: ./fix-hls-completo.sh"
