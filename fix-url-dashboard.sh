#!/bin/bash
echo "🔧 CORRIGIENDO URL PARA DASHBOARD SIART"

# Obtener IP del servidor
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "📍 IP detectada: $SERVER_IP"

# Actualizar variable de entorno
cat > .env.local << EOF
NEXT_PUBLIC_HLS_BASE_URL=http://$SERVER_IP:8080/hls
EOF

# Reconstruir dashboard
docker compose build --no-cache web
docker compose up -d web

echo "✅ CORREGIDO - Accede a: http://$SERVER_IP:3000"
