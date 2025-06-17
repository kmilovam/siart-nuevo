#!/bin/bash
echo "🔄 RESTAURANDO SISTEMA SIART DESDE BACKUP"
echo "========================================"

# Detener servicios actuales
docker compose down -v

# Restaurar archivos de configuración
cp docker-compose.yml ../
cp Dockerfile ../
cp -r nginx-config ../
cp -r src ../
cp -r public ../ 2>/dev/null || true
cp package.json ../
cp package-lock.json ../ 2>/dev/null || true
cp next.config.js ../ 2>/dev/null || true
cp .env.local ../ 2>/dev/null || true
cp .env ../ 2>/dev/null || true

# Reconstruir servicios
cd ..
docker compose build --no-cache
docker compose up -d

# Esperar que la base de datos esté lista
echo "⏳ Esperando inicialización de servicios..."
sleep 30

# Restaurar base de datos
echo "💾 Restaurando base de datos..."
docker compose exec -T db psql -U siart_user -d siart_db < database_backup.sql

echo "✅ RESTAURACIÓN COMPLETADA"
echo "========================="
echo "🌐 Dashboard: http://192.168.1.8:3000"
echo "📱 Sistema restaurado al estado funcional"
