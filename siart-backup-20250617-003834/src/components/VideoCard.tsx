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
