#!/bin/bash
echo "🚀 OPTIMIZACIÓN ULTRA LOW LATENCY - SISTEMA SIART"
echo "==============================================="

# 1. Detener servicios
docker compose down

# 2. Crear configuración nginx optimizada para latencia mínima
mkdir -p nginx-config
cat > nginx-config/nginx.conf << 'EOF'
worker_processes 1;
events {
    worker_connections 1024;
}

rtmp {
    server {
        listen 1935;
        chunk_size 1024;          # Reducir chunk size para menor latency
        buflen 50ms;              # Buffer mínimo para ultra low latency
        publish_time_fix off;     # Mejorar sincronización temporal
        
        application live {
            live on;
            
            # Configuración HLS ultra low latency
            hls on;
            hls_path /tmp/hls;
            hls_fragment 1s;       # Fragmentos de 1 segundo
            hls_playlist_length 3s; # Lista de solo 3 segundos
            hls_continuous on;
            hls_cleanup on;
            hls_nested on;
            
            # Configuraciones adicionales para latencia
            wait_key on;           # Esperar keyframe
            wait_video on;         # Esperar video
            idle_streams off;      # No mantener streams inactivos
            
            allow publish all;
            allow play all;
        }
    }
}

http {
    sendfile off;
    tcp_nopush on;
    tcp_nodelay on;
    directio 512;
    
    server {
        listen 8080;
        
        location /hls {
            types {
                application/vnd.apple.mpegurl m3u8;
                video/mp2t ts;
            }
            
            root /tmp;
            
            # Headers optimizados para low latency
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Cache-Control' 'no-cache, no-store, must-revalidate' always;
            add_header 'Pragma' 'no-cache' always;
            add_header 'Expires' '0' always;
            
            # Configuración de buffering mínimo
            proxy_buffering off;
            proxy_cache off;
        }
        
        location /stat {
            rtmp_stat all;
            rtmp_stat_stylesheet stat.xsl;
        }
    }
}
EOF

# 3. Actualizar componente VideoCard con configuración low latency
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
  const [latency, setLatency] = useState<number>(0);

  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;

    const hlsUrl = `${process.env.NEXT_PUBLIC_HLS_BASE_URL || 'http://192.168.1.8:8080/hls'}/canal${canalId}.m3u8`;

    if (video.canPlayType('application/vnd.apple.mpegurl')) {
      // Safari nativo con configuración low latency
      video.src = hlsUrl;
      video.addEventListener('loadeddata', () => setLoading(false));
      video.addEventListener('error', () => setError('Error nativo'));
    } else {
      // HLS.js con configuración ultra low latency
      import('hls.js').then((Hls) => {
        if (Hls.default.isSupported()) {
          const hls = new Hls.default({
            // Configuración optimizada para latencia mínima
            maxBufferLength: 5,        // Buffer máximo 5 segundos
            backBufferLength: 2,       // Buffer trasero 2 segundos
            maxBufferSize: 0,          // Sin límite por tamaño
            maxBufferHole: 0.2,        // Agujeros máximos 200ms
            lowLatencyMode: true,      // Modo low latency
            enableWorker: false,       // Deshabilitar worker para menos overhead
            
            // Políticas de carga agresivas
            manifestLoadPolicy: {
              default: {
                maxTimeToFirstByteMs: 2000,
                maxLoadTimeMs: 5000,
                timeoutRetry: {
                  maxNumRetry: 1,
                  retryDelayMs: 0,
                  maxRetryDelayMs: 0
                }
              }
            },
            
            playlistLoadPolicy: {
              default: {
                maxTimeToFirstByteMs: 1000,
                maxLoadTimeMs: 3000,
                timeoutRetry: {
                  maxNumRetry: 1,
                  retryDelayMs: 0,
                  maxRetryDelayMs: 0
                }
              }
            },
            
            fragLoadPolicy: {
              default: {
                maxTimeToFirstByteMs: 1000,
                maxLoadTimeMs: 5000,
                timeoutRetry: {
                  maxNumRetry: 2,
                  retryDelayMs: 0,
                  maxRetryDelayMs: 0
                }
              }
            }
          });
          
          hlsRef.current = hls;
          hls.loadSource(hlsUrl);
          hls.attachMedia(video);
          
          hls.on(Hls.default.Events.MANIFEST_PARSED, () => {
            setLoading(false);
            // Iniciar reproducción inmediatamente
            video.play().catch(() => {});
          });
          
          // Monitorear latencia
          hls.on(Hls.default.Events.FRAG_LOADED, () => {
            const buffered = video.buffered;
            if (buffered.length > 0) {
              const currentTime = video.currentTime;
              const bufferEnd = buffered.end(buffered.length - 1);
              setLatency(Math.round((bufferEnd - currentTime) * 1000));
            }
          });
          
          hls.on(Hls.default.Events.ERROR, (event, data) => {
            if (data.fatal) {
              setError(`Error HLS: ${data.details}`);
            }
          });
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
        <div className="text-red-400 text-sm">{error}</div>
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
            <div className="text-blue-400">⚡ Optimizando latencia...</div>
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
        <div className="text-gray-400 text-xs mt-1">
          ⚡ Ultra Low Latency | Buffer: {latency}ms
        </div>
      </div>
    </div>
  );
}
EOF

# 4. Reconstruir servicios
echo "🔄 Aplicando optimizaciones..."
docker compose build --no-cache web
docker compose up -d

echo "✅ OPTIMIZACIÓN COMPLETADA"
echo "========================="
echo "🎯 Latencia objetivo: 2-4 segundos"
echo "⚡ Fragmentos HLS: 1 segundo"
echo "📱 Buffer optimizado: 5 segundos máximo"
echo ""
echo "📋 INSTRUCCIONES PARA EL DRONE:"
echo "1. Configura keyframe interval a 1 segundo en DJI Fly"
echo "2. Usa bitrate 2-3 Mbps para estabilidad"
echo "3. Resolución recomendada: 720p para menor latencia"
EOF
