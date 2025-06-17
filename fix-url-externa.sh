#!/bin/bash
echo "🔧 CORRIGIENDO URL EXTERNA PARA HLS - SIART"
echo "==========================================="

# 1. Obtener IP del servidor
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "📍 IP del servidor detectada: $SERVER_IP"

# 2. Actualizar docker-compose.yml con IP externa
cat > docker-compose.yml << EOF
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
      - NEXT_PUBLIC_HLS_BASE_URL=http://$SERVER_IP:8080/hls
    restart: unless-stopped

volumes:
  postgres_data:

networks:
  siart-network:
    driver: bridge
EOF

# 3. Crear archivo .env.local para development
cat > .env.local << EOF
NEXT_PUBLIC_HLS_BASE_URL=http://$SERVER_IP:8080/hls
EOF

# 4. Reconstruir contenedor web con nueva configuración
echo "🔄 Reconstruyendo contenedor web..."
docker compose build --no-cache web
docker compose up -d web

echo "✅ CORRECCIÓN APLICADA"
echo "====================="
echo "🌐 Nueva URL HLS: http://$SERVER_IP:8080/hls"
echo "📱 Dashboard: http://$SERVER_IP:3000"
echo "🎥 Ahora el navegador podrá acceder al servidor RTMP correctamente"
