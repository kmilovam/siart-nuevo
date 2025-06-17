#!/bin/bash
echo "✅ VERIFICACIÓN RÁPIDA - SISTEMA SIART"
echo "====================================="

# Verificar estado de contenedores
echo "📊 Estado de contenedores:"
docker compose ps

echo ""
echo "📋 Logs del servicio web (últimas 10 líneas):"
docker compose logs web --tail 10

echo ""
echo "🌐 Probando conectividad del dashboard:"
if curl -s -I http://localhost:3000 | grep -q "200 OK"; then
    echo "✅ Dashboard accesible en http://localhost:3000"
else
    echo "⚠️ Dashboard no responde correctamente"
fi

echo ""
echo "📹 Verificando servidor RTMP:"
if nc -z localhost 1935 2>/dev/null; then
    echo "✅ Puerto RTMP 1935 abierto"
else
    echo "⚠️ Puerto RTMP 1935 no accesible"
fi

echo ""
echo "🎥 Verificando servidor HLS:"
if curl -s http://localhost:8080/stat | grep -q "nginx_version"; then
    echo "✅ Servidor HLS funcionando"
else
    echo "⚠️ Servidor HLS no responde"
fi

echo ""
echo "📱 Para acceder al dashboard:"
echo "   Navegador: http://localhost:3000"
echo ""
echo "🔧 Si hay problemas, ejecuta:"
echo "   docker compose logs web --tail 50"
