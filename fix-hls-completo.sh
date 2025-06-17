#!/bin/bash
echo "🔧 CORRECCIÓN COMPLETA HLS - TRANSMISIÓN DRONE SIART"
echo "=================================================="

# 1. Crear backup de configuración actual
echo "📦 Creando backup de configuración actual..."
mkdir -p backup-$(date +%H%M%S)
cp nginx-config/nginx.conf backup-*/nginx.conf.bak 2>/dev/null || echo "No hay configuración previa"

# 2. Crear configuración nginx optimizada para drone
echo "⚙️ Creando configuración nginx optimizada para drone..."
mkdir -p nginx-config
cat > nginx-config/nginx.conf << 'EOF'
worker_processes 1;
error_log /var/log/nginx/error.log info;

events {
    worker_connections 1024;
}

rtmp {
    server {
        listen 1935;
        chunk_size 4000;
        
        # Aplicación para recibir stream del drone
        application live {
            live on;
            wait_key on;         # Esperar keyframe para iniciar
            wait_video on;       # Esperar video antes de procesar
            
            # Configuración HLS directa (sin FFmpeg)
            hls on;
            hls_path /tmp/hls;
            hls_fragment 3s;     # Fragmentos de 3 segundos
            hls_playlist_length 15s;  # Lista de 15 segundos
            hls_continuous on;   # Mantener stream continuo
            hls_cleanup on;      # Limpiar archivos antiguos
            hls_nested on;       # Crear subdirectorios por stream
            
            # Solo para depuración
            access_log /var/log/nginx/rtmp_access.log;
        }
    }
}

http {
    access_log /var/log/nginx/access.log;
    
    server {
        listen 8080;
        
        # Servir archivos HLS
        location /hls {
            types {
                application/vnd.apple.mpegurl m3u8;
                video/mp2t ts;
            }
            root /tmp;
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
            add_header Access-Control-Allow-Methods GET;
        }
        
        # Estadísticas del servidor RTMP
        location /stat {
            rtmp_stat all;
            rtmp_stat_stylesheet stat.xsl;
        }
        
        # Página de prueba
        location / {
            return 200 'SIART RTMP Server - HLS Ready';
            add_header Content-Type text/plain;
        }
    }
}
EOF

# 3. Actualizar docker-compose.yml
echo "🐳 Actualizando docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
services:
  db:
    image: postgres:16-alpine
    container_name: siart-nuevo-db
    environment:
      POSTGRES_DB: siart_db
      POSTGRES_USER: siart_user
      POSTGRES_PASSWORD: siart_pass
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - siart-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U siart_user"]
      interval: 10s
      timeout: 5s
      retries: 5

  rtmp:
    image: alqutami/rtmp-hls:latest
    container_name: siart-nuevo-rtmp
    ports:
      - "1935:1935"
      - "8080:8080"
    volumes:
      - ./nginx-config/nginx.conf:/etc/nginx/nginx.conf:ro
    networks:
      - siart-network
    restart: unless-stopped
    
  web:
    build: .
    container_name: siart-nuevo-web
    ports:
      - "3000:3000"
    depends_on:
      db:
        condition: service_healthy
    networks:
      - siart-network
    environment:
      - DATABASE_URL=postgresql://siart_user:siart_pass@db:5432/siart_db
      - NEXT_PUBLIC_HLS_BASE_URL=http://localhost:8080/hls
    restart: unless-stopped

volumes:
  postgres_data:

networks:
  siart-network:
    driver: bridge
EOF

# 4. Reiniciar servicios con nueva configuración
echo "🔄 Reiniciando servicios con nueva configuración..."
docker compose down
sleep 5
docker compose up -d

# 5. Esperar inicio de servicios
echo "⏳ Esperando inicio de servicios (30 segundos)..."
sleep 30

# 6. Verificar que todo esté funcionando
echo "✅ VERIFICACIÓN POST-CORRECCIÓN:"
echo "================================"
echo "Estado de contenedores:"
docker compose ps

echo -e "\nProbando acceso HLS:"
sleep 10
curl -I http://localhost:8080/hls/canal1.m3u8 2>/dev/null && echo "✅ HLS accesible" || echo "⚠️ HLS aún no disponible (normal si no hay stream activo)"

echo -e "\nEstadísticas del servidor:"
curl -s http://localhost:8080/stat | grep -E "(application|stream|publishing)" || echo "Sin streams activos"

echo -e "\n📹 INSTRUCCIONES PARA EL DRONE:"
echo "==============================="
echo "URL RTMP: rtmp://$(hostname -I | awk '{print $1}'):1935/live/canal1"
echo "o también: rtmp://localhost:1935/live/canal1"
echo ""
echo "Una vez que inicies la transmisión desde el drone:"
echo "- URL HLS: http://localhost:8080/hls/canal1.m3u8"
echo "- Dashboard: http://localhost:3000"
echo ""
echo "🔧 Si persisten problemas, ejecuta: ./troubleshooting-avanzado.sh"
