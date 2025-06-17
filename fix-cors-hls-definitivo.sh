#!/bin/bash
echo "🔧 CORRECCIÓN DEFINITIVA: CORS + HLS - SISTEMA SIART"
echo "=================================================="

# 1. Detener servicios
docker compose down

# 2. Crear configuración nginx con CORS habilitado y HLS funcional
mkdir -p nginx-config
cat > nginx-config/nginx.conf << 'EOF'
worker_processes 1;
events {
    worker_connections 1024;
}

rtmp {
    server {
        listen 1935;
        chunk_size 4000;
        
        application live {
            live on;
            
            # Configuración HLS directa (sin exec)
            hls on;
            hls_path /tmp/hls;
            hls_fragment 3s;
            hls_playlist_length 20s;
            hls_continuous on;
            hls_cleanup on;
            
            # Permitir publishing desde cualquier IP
            allow publish all;
            allow play all;
        }
    }
}

http {
    server {
        listen 8080;
        
        # Configuración CORS completa para HLS
        location /hls {
            types {
                application/vnd.apple.mpegurl m3u8;
                video/mp2t ts;
            }
            
            root /tmp;
            
            # Headers CORS esenciales
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'Range, Content-Type' always;
            add_header 'Access-Control-Expose-Headers' 'Content-Length, Content-Range' always;
            add_header 'Cache-Control' 'no-cache' always;
            
            # Manejar requests OPTIONS (preflight)
            if ($request_method = 'OPTIONS') {
                add_header 'Access-Control-Allow-Origin' '*';
                add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
                add_header 'Access-Control-Max-Age' 1728000;
                add_header 'Content-Type' 'text/plain charset=UTF-8';
                add_header 'Content-Length' 0;
                return 204;
            }
        }
        
        location /stat {
            rtmp_stat all;
            rtmp_stat_stylesheet stat.xsl;
            
            # CORS para estadísticas
            add_header 'Access-Control-Allow-Origin' '*' always;
        }
        
        # Página de bienvenida
        location / {
            return 200 'SIART RTMP Server - CORS Enabled';
            add_header Content-Type text/plain;
            add_header 'Access-Control-Allow-Origin' '*' always;
        }
    }
}
EOF

# 3. Actualizar docker-compose.yml con configuración correcta
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
      - NEXT_PUBLIC_HLS_BASE_URL=http://192.168.1.8:8080/hls
    restart: unless-stopped

volumes:
  postgres_data:

networks:
  siart-network:
    driver: bridge
EOF

# 4. Reiniciar servicios
echo "🚀 Reiniciando servicios con configuración CORS..."
docker compose up -d

# 5. Esperar inicialización
echo "⏳ Esperando inicialización (30 segundos)..."
sleep 30

# 6. Verificaciones finales
echo "✅ VERIFICACIONES FINALES:"
echo "========================="

echo "1. Estado de contenedores:"
docker compose ps

echo -e "\n2. Prueba de CORS (debe responder con headers CORS):"
curl -H "Origin: http://161.10.191.239:3000" -I http://192.168.1.8:8080/hls/test 2>/dev/null || echo "Servidor HLS iniciando..."

echo -e "\n3. Directorio HLS (debe existir):"
docker compose exec rtmp ls -la /tmp/hls/ 2>/dev/null || echo "Directorio HLS creándose..."

echo -e "\n📋 INSTRUCCIONES FINALES:"
echo "========================="
echo "1. Inicia la transmisión desde el drone: rtmp://192.168.1.8:1935/live/canal1"
echo "2. Espera 30 segundos después de iniciar la transmisión"
echo "3. Accede al dashboard: http://161.10.191.239:3000"
echo "4. El video debería aparecer sin errores CORS"
echo ""
echo "🔧 Para verificar que funciona:"
echo "   curl -I http://192.168.1.8:8080/hls/canal1.m3u8"
echo "   (debe devolver 200 OK después de iniciar transmisión)"
EOF

