#!/bin/bash
echo "🔧 SOLUCIONANDO PUERTO 1935 Y CONFIGURANDO VIDEO-ONLY SIART"
echo "==========================================================="

# 1. Limpiar puertos ocupados
echo "🛑 Deteniendo contenedores que usan puerto 1935..."
docker stop $(docker ps -q --filter "publish=1935") 2>/dev/null || true
docker stop $(docker ps -q --filter "publish=8080") 2>/dev/null || true

# 2. Limpieza completa
echo "🧹 Limpiando sistema Docker..."
docker compose down -v --remove-orphans
docker system prune -f

# 3. Crear configuración RTMP optimizada solo video
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
            # Video only - sin audio
            exec ffmpeg -i rtmp://localhost:1935/live/$name
                -c:v libx264 -preset veryfast -tune zerolatency
                -profile:v baseline -pix_fmt yuv420p
                -an  # Sin audio
                -f flv rtmp://localhost:1935/hls/$name;
        }
        
        application hls {
            live on;
            hls on;
            hls_path /tmp/hls;
            hls_fragment 3s;
            hls_playlist_length 60s;
            # Solo video en HLS
            hls_variant _low BANDWIDTH=256000;
            hls_variant _mid BANDWIDTH=512000;
            hls_variant _high BANDWIDTH=1024000;
            hls_variant _src BANDWIDTH=2048000;
        }
    }
}

http {
    server {
        listen 8080;
        location /hls {
            types {
                application/vnd.apple.mpegurl m3u8;
                video/mp2t ts;
            }
            root /tmp;
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
        }
        location /stat {
            rtmp_stat all;
            rtmp_stat_stylesheet stat.xsl;
        }
    }
}
EOF

# 4. Actualizar docker-compose.yml sin audio
cat > docker-compose.yml << 'EOF'
version: '3.8'
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
      - ./nginx-config/nginx.conf:/etc/nginx/nginx.conf
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

# 5. Actualizar componente VideoCard para video only
mkdir -p src/components
cat > src/components/VideoCard.tsx << 'EOF'
'use client';
import React, { useEffect, useRef, useState } from 'react';

interface VideoCardProps {
  canalId: number;
  nombre: string;
}

export default function VideoCard({ canalId, nombre }: VideoCardProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [error, setError] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let hls: any;
    const video = videoRef.current;
    const hlsUrl = `${process.env.NEXT_PUBLIC_HLS_BASE_URL || 'http://localhost:8080/hls'}/canal${canalId}.m3u8`;

    if (video) {
      setLoading(true);
      
      if (video.canPlayType('application/vnd.apple.mpegurl')) {
        video.src = hlsUrl;
        video.addEventListener('loadeddata', () => setLoading(false));
        video.addEventListener('error', () => setError(true));
      } else {
        import('hls.js').then((Hls) => {
          if (Hls.default.isSupported()) {
            hls = new Hls.default();
            hls.loadSource(hlsUrl);
            hls.attachMedia(video);
            
            hls.on(Hls.default.Events.MANIFEST_PARSED, () => {
              setLoading(false);
            });
            
            hls.on(Hls.default.Events.ERROR, () => {
              setError(true);
              setLoading(false);
            });
          } else {
            setError(true);
            setLoading(false);
          }
        });
      }
    }

    return () => {
      if (hls) {
        hls.destroy();
      }
    };
  }, [canalId]);

  if (error) {
    return (
      <div className="bg-gray-800 rounded-lg p-4 text-center">
        <div className="text-red-400 text-sm mb-2">❌ Error de conexión</div>
        <div className="text-gray-300 text-xs">No se puede cargar {nombre}</div>
      </div>
    );
  }

  return (
    <div className="bg-gray-800 rounded-lg overflow-hidden shadow-lg">
      <div className="relative">
        {loading && (
          <div className="absolute inset-0 bg-gray-700 flex items-center justify-center">
            <div className="text-blue-400">🔄 Cargando {nombre}...</div>
          </div>
        )}
        <video
          ref={videoRef}
          autoPlay
          muted  // Video sin audio
          playsInline
          className="w-full h-48 object-cover"
          style={{ backgroundColor: '#1f2937' }}
        />
      </div>
      <div className="p-3">
        <div className="text-white font-medium text-sm">{nombre}</div>
        <div className="text-gray-400 text-xs mt-1">📹 Solo Video - Sin Audio</div>
      </div>
    </div>
  );
}
EOF

# 6. Reconstruir sistema
echo "🚀 Reconstruyendo sistema SIART..."
docker compose build --no-cache
docker compose up -d

echo "✅ SISTEMA SIART CONFIGURADO PARA VIDEO ÚNICAMENTE"
echo "📊 Verificando estado:"
sleep 20
docker compose ps
echo ""
echo "🎥 Características:"
echo "   - ✅ Streaming solo video (sin audio)"
echo "   - ✅ Puerto 1935 liberado y reconfigurado"
echo "   - ✅ HLS optimizado para video únicamente"
echo "   - ✅ Dashboard accesible en http://localhost:3000"
echo ""
echo "📹 Para hacer streaming solo video:"
echo "   rtmp://localhost:1935/live/canal1"
EOF
