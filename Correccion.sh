#!/bin/bash
echo "🔧 CORRIGIENDO STREAMING DE VIDEO - SISTEMA SIART"

# Actualizar VideoCard con ruta correcta y eventos HLS
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
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;

    // RUTA CORREGIDA: incluye subdirectorio y index.m3u8
    const hlsUrl = `${process.env.NEXT_PUBLIC_HLS_BASE_URL || 'http://192.168.1.8:8080/hls'}/canal${canalId}/index.m3u8`;
    
    console.log('🎥 Cargando stream desde:', hlsUrl);

    if (video.canPlayType('application/vnd.apple.mpegurl')) {
      // Safari nativo
      video.src = hlsUrl;
      video.addEventListener('loadeddata', () => {
        setLoading(false);
        setConnected(true);
      });
      video.addEventListener('error', () => {
        setError('Error nativo');
        setLoading(false);
      });
    } else {
      // HLS.js para otros navegadores
      import('hls.js').then((Hls) => {
        if (Hls.default.isSupported()) {
          const hls = new Hls.default({
            debug: true,
            lowLatencyMode: true,
            maxBufferLength: 5,
            backBufferLength: 2
          });
          
          hlsRef.current = hls;
          hls.loadSource(hlsUrl);
          hls.attachMedia(video);
          
          // EVENTOS CORREGIDOS
          hls.on(Hls.Events.MANIFEST_PARSED, () => {
            console.log('✅ Stream HLS cargado correctamente');
            setLoading(false);
            setConnected(true);
            video.play().catch(err => console.error('Error al reproducir:', err));
          });
          
          hls.on(Hls.Events.ERROR, (event, data) => {
            console.error('❌ Error HLS:', data);
            if (data.fatal) {
              setError(`Error HLS: ${data.details}`);
              setLoading(false);
            }
          });
        } else {
          setError('HLS.js no soportado');
          setLoading(false);
        }
      }).catch(err => {
        console.error('Error cargando HLS.js:', err);
        setError('Error cargando HLS.js');
        setLoading(false);
      });
    }

    return () => {
      if (hlsRef.current) {
        hlsRef.current.destroy();
      }
    };
  }, [canalId]);

  // Resto del componente igual...
}
EOF

echo "✅ Componente VideoCard actualizado con ruta correcta"
echo "🔄 Reconstruyendo servicios..."
docker compose build --no-cache web
docker compose up -d web
