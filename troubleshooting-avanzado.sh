#!/bin/bash
echo "🛠️ TROUBLESHOOTING AVANZADO - SIART HLS"
echo "======================================="

# 1. Verificar conectividad interna del contenedor
echo "1. VERIFICANDO CONECTIVIDAD INTERNA:"
echo "-----------------------------------"
docker compose exec rtmp curl -I http://localhost:8080/stat 2>/dev/null && echo "✅ HTTP interno OK" || echo "❌ HTTP interno FALLO"

# 2. Verificar estructura de directorios dentro del contenedor
echo -e "\n2. ESTRUCTURA DE DIRECTORIOS HLS:"
echo "--------------------------------"
docker compose exec rtmp find /tmp -name "*hls*" -type d 2>/dev/null || echo "No hay directorios HLS"

# 3. Crear directorio HLS manualmente si no existe
echo -e "\n3. CREANDO/VERIFICANDO DIRECTORIO HLS:"
echo "------------------------------------"
docker compose exec rtmp mkdir -p /tmp/hls
docker compose exec rtmp chmod 755 /tmp/hls
docker compose exec rtmp chown nobody:nogroup /tmp/hls 2>/dev/null || echo "Permisos aplicados"

# 4. Verificar procesos nginx dentro del contenedor
echo -e "\n4. PROCESOS NGINX:"
echo "----------------"
docker compose exec rtmp ps aux | grep nginx || echo "No hay procesos nginx visibles"

# 5. Verificar logs de nginx en tiempo real
echo -e "\n5. LOGS DE NGINX (ÚLTIMAS 20 LÍNEAS):"
echo "------------------------------------"
docker compose exec rtmp cat /var/log/nginx/error.log 2>/dev/null | tail -20 || echo "No hay logs de error disponibles"

# 6. Probar configuración nginx
echo -e "\n6. VALIDACIÓN DE CONFIGURACIÓN NGINX:"
echo "------------------------------------"
docker compose exec rtmp nginx -t 2>&1 || echo "Error en configuración nginx"

# 7. Reiniciar nginx dentro del contenedor
echo -e "\n7. REINICIANDO NGINX:"
echo "-------------------"
docker compose exec rtmp nginx -s reload 2>/dev/null && echo "✅ Nginx recargado" || echo "❌ Error al recargar nginx"

# 8. Verificar puertos internos
echo -e "\n8. PUERTOS INTERNOS ACTIVOS:"
echo "---------------------------"
docker compose exec rtmp netstat -tlnp 2>/dev/null | grep -E "(1935|8080)" || echo "Puertos no visibles con netstat"

# 9. Crear archivo de prueba HLS manual
echo -e "\n9. CREANDO ARCHIVO HLS DE PRUEBA:"
echo "--------------------------------"
docker compose exec rtmp bash -c 'echo "#EXTM3U" > /tmp/hls/test.m3u8 && echo "#EXT-X-VERSION:3" >> /tmp/hls/test.m3u8 && echo "Archivo de prueba creado"'

# 10. Probar acceso al archivo de prueba
echo -e "\n10. PROBANDO ACCESO A ARCHIVO DE PRUEBA:"
echo "---------------------------------------"
curl -s http://localhost:8080/hls/test.m3u8 && echo "✅ Acceso HLS funcionando" || echo "❌ Acceso HLS fallando"

echo -e "\n📋 DIAGNÓSTICO FINAL:"
echo "===================="
echo "Si el archivo de prueba es accesible pero canal1.m3u8 da 404:"
echo "- El problema está en la generación automática de HLS desde RTMP"
echo "- Verifica que el drone esté enviando H.264 + AAC"
echo "- Considera usar la configuración con FFmpeg exec"
echo ""
echo "Si el archivo de prueba también da 404:"
echo "- El problema está en la configuración HTTP de nginx"
echo "- Revisa el mapeo de volúmenes y permisos"
echo ""
echo "📞 Comparte estos resultados para diagnóstico específico"
