#!/bin/bash
echo "📦 CREANDO BACKUP COMPLETO - SISTEMA SIART FUNCIONAL"
echo "=================================================="

# Crear directorio de backup con timestamp
BACKUP_DIR="siart-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "📁 Directorio de backup: $BACKUP_DIR"

# 1. Backup de configuración Docker
echo "🐳 Respaldando configuración Docker..."
cp docker-compose.yml "$BACKUP_DIR/"
cp Dockerfile "$BACKUP_DIR/"
cp -r nginx-config "$BACKUP_DIR/"

# 2. Backup de código fuente
echo "💻 Respaldando código fuente..."
cp -r src "$BACKUP_DIR/"
cp -r public "$BACKUP_DIR/" 2>/dev/null || true
cp package.json "$BACKUP_DIR/"
cp package-lock.json "$BACKUP_DIR/" 2>/dev/null || true
cp next.config.js "$BACKUP_DIR/" 2>/dev/null || true

# 3. Backup de variables de entorno
echo "🌐 Respaldando variables de entorno..."
cp .env.local "$BACKUP_DIR/" 2>/dev/null || true
cp .env "$BACKUP_DIR/" 2>/dev/null || true

# 4. Backup de base de datos
echo "💾 Respaldando base de datos PostgreSQL..."
docker compose exec -T db pg_dump -U siart_user siart_db > "$BACKUP_DIR/database_backup.sql"

# 5. Crear documentación del estado actual
cat > "$BACKUP_DIR/ESTADO_SISTEMA.md" << 'EOF'
# Estado del Sistema SIART - Backup Funcional

## Fecha del Backup
$(date)

## Características del Sistema
- ✅ Streaming RTMP/HLS completamente funcional
- ✅ Dashboard web adaptativo operativo
- ✅ Todos los canales (1-4) funcionando correctamente
- ✅ Delay de 6 segundos (aceptable para HLS)
- ✅ Base de datos PostgreSQL estable
- ✅ Configuración CORS habilitada
- ✅ Layout adaptativo implementado

## URLs del Sistema
- Dashboard: http://192.168.1.8:3000
- Servidor HLS: http://192.168.1.8:8080/hls
- Estadísticas RTMP: http://192.168.1.8:8080/stat
- Stream RTMP: rtmp://192.168.1.8:1935/live/canal[1-4]

## Configuración Técnica
- Next.js 15.3.3 con TypeScript
- Node.js 18-alpine
- PostgreSQL 16-alpine
- nginx-rtmp con HLS nested
- Docker multi-stage optimizado

## Componentes Clave
- VideoCard.tsx: Reproductor HLS optimizado
- AdaptiveDashboard.tsx: Layout dinámico
- nginx.conf: Configuración RTMP/HLS
- docker-compose.yml: Orquestación de servicios

## Performance
- Latencia: 6 segundos (HLS estándar)
- Fragmentos: 1 segundo
- Buffer: 5 segundos máximo
- Resolución soportada: Hasta 1080p
EOF

# 6. Crear script de restauración
cat > "$BACKUP_DIR/restaurar-backup.sh" << 'EOF'
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
EOF

chmod +x "$BACKUP_DIR/restaurar-backup.sh"

# 7. Crear archivo de verificación
cat > "$BACKUP_DIR/verificar-sistema.sh" << 'EOF'
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
EOF

chmod +x "$BACKUP_DIR/verificar-sistema.sh"

# 8. Comprimir backup
echo "🗜️ Comprimiendo backup..."
tar -czf "${BACKUP_DIR}.tar.gz" "$BACKUP_DIR"

echo "✅ BACKUP COMPLETADO"
echo "==================="
echo "📦 Archivo de backup: ${BACKUP_DIR}.tar.gz"
echo "📁 Directorio: $BACKUP_DIR"
echo "📋 Documentación: $BACKUP_DIR/ESTADO_SISTEMA.md"
echo "🔄 Script restauración: $BACKUP_DIR/restaurar-backup.sh"
echo ""
echo "💡 Para restaurar en el futuro:"
echo "   1. Extraer: tar -xzf ${BACKUP_DIR}.tar.gz"
echo "   2. Entrar: cd $BACKUP_DIR"
echo "   3. Ejecutar: ./restaurar-backup.sh"
