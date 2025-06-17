#!/bin/bash
echo "🔧 CORRIGIENDO ERROR URL HLS - SISTEMA SIART"
echo "==========================================="

# 1. Detener servicios
echo "🛑 Deteniendo servicios..."
docker compose down

# 2. Crear configuración nginx corregida
echo "⚙️ Creando configuración nginx optimizada..."
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
            hls on;
            hls_path /tmp/hls;
            hls_fragment 1s;
            hls_playlist_length 3s;
            hls_nested on;
            hls_cleanup on;
            allow publish all;
            allow play all;
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
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Cache-Control' 'no-cache' always;
        }
        
        location /stat {
            rtmp_stat all;
            rtmp_stat_stylesheet stat.xsl;
        }
    }
}
EOF

# 3. Corregir componente VideoCard con URL correcta
echo "🔄 Corrigiendo componente VideoCard..."
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
  const hlsRef = useRef<any>(null);
  const [error, setError] = useState<string>('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;

    // URL CORREGIDA: incluye subdirectorio y index.m3u8
    const hlsUrl = `${process.env.NEXT_PUBLIC_HLS_BASE_URL || 'http://192.168.1.8:8080/hls'}/canal${canalId}/index.m3u8`;
    
    console.log('🎥 Cargando stream desde:', hlsUrl);

    if (video.canPlayType('application/vnd.apple.mpegurl')) {
      // Safari nativo
      video.src = hlsUrl;
      video.addEventListener('loadeddata', () => setLoading(false));
      video.addEventListener('error', () => setError('Error nativo'));
    } else {
      // HLS.js para otros navegadores
      import('hls.js').then((Hls) => {
        if (Hls.default.isSupported()) {
          const hls = new Hls.default({
            debug: false,
            lowLatencyMode: true,
            maxBufferLength: 5,
            backBufferLength: 2
          });
          
          hlsRef.current = hls;
          hls.loadSource(hlsUrl);
          hls.attachMedia(video);
          
          hls.on(Hls.default.Events.MANIFEST_PARSED, () => {
            console.log('✅ Stream HLS cargado correctamente');
            setLoading(false);
          });
          
          hls.on(Hls.default.Events.ERROR, (event, data) => {
            console.error('❌ Error HLS:', data);
            if (data.fatal) {
              setError(`Error HLS: ${data.details}`);
            }
          });
        } else {
          setError('HLS.js no soportado');
        }
      });
    }

    return () => {
      if (hlsRef.current) {
        hlsRef.current.destroy();
      }
    };
  }, [canalId]);

  if (error) {
    return (
      <div className="bg-red-900 rounded-lg p-4 text-center">
        <div className="text-red-400 text-sm">❌ {error}</div>
        <div className="text-red-300 text-xs">{nombre}</div>
        <button 
          onClick={() => window.location.reload()} 
          className="mt-2 px-3 py-1 bg-red-700 text-white text-xs rounded"
        >
          Recargar
        </button>
      </div>
    );
  }

  return (
    <div className="bg-gray-800 rounded-lg overflow-hidden shadow-lg">
      <div className="relative">
        {loading && (
          <div className="absolute inset-0 bg-gray-700 flex items-center justify-center z-10">
            <div className="text-blue-400">🔄 Cargando {nombre}...</div>
          </div>
        )}
        <video
          ref={videoRef}
          autoPlay
          muted
          playsInline
          controls
          className="w-full h-48 object-cover bg-black"
        />
      </div>
      <div className="p-3">
        <div className="text-white font-medium text-sm">{nombre}</div>
        <div className="text-gray-400 text-xs mt-1">📹 Stream HLS Activo</div>
      </div>
    </div>
  );
}
EOF

# 4. Actualizar variables de entorno
echo "🌐 Configurando variables de entorno..."
cat > .env.local << 'EOF'
NEXT_PUBLIC_HLS_BASE_URL=http://192.168.1.8:8080/hls
EOF

# 5. Reconstruir servicios
echo "🚀 Reconstruyendo servicios..."
docker compose build --no-cache web
docker compose up -d

# 6. Configurar permisos HLS
echo "🔧 Configurando permisos..."
sleep 10
docker compose exec rtmp mkdir -p /tmp/hls
docker compose exec rtmp chmod 777 /tmp/hls

echo "✅ CORRECCIÓN COMPLETADA"
echo "======================="
echo "🎥 URL HLS corregida: /canal1/index.m3u8"
echo "🌐 Dashboard: http://192.168.1.8:3000"
echo "📱 Inicia transmisión: rtmp://192.168.1.8:1935/live/canal1"
echo ""
echo "🔍 Verificación:"
echo "docker compose exec rtmp ls -la /tmp/hls/canal1"
echo "curl -I http://192.168.1.8:8080/hls/canal1/index.m3u8"
EOF
