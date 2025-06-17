#!/bin/bash
echo "🔧 CORRIGIENDO COMPONENTE VIDEOCARD - DASHBOARD SIART"
echo "=================================================="

# Crear componente VideoCard con debugging avanzado
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
  const [hlsSupported, setHlsSupported] = useState(false);
  const [debugInfo, setDebugInfo] = useState<string>('Inicializando...');

  useEffect(() => {
    const video = videoRef.current;
    if (!video) {
      setError('Elemento video no encontrado');
      return;
    }

    const hlsUrl = `${process.env.NEXT_PUBLIC_HLS_BASE_URL || 'http://localhost:8080/hls'}/canal${canalId}.m3u8`;
    
    console.log('🎥 VideoCard Debug:', {
      canalId,
      hlsUrl,
      videoElement: video,
      canPlayHLS: video.canPlayType('application/vnd.apple.mpegurl')
    });

    setDebugInfo(`Cargando: ${hlsUrl}`);

    // Verificar soporte nativo primero (Safari)
    if (video.canPlayType('application/vnd.apple.mpegurl')) {
      console.log('✅ Usando soporte nativo HLS (Safari)');
      setDebugInfo('Usando soporte nativo HLS');
      video.src = hlsUrl;
      
      const handleLoadedData = () => {
        console.log('✅ Video cargado correctamente (nativo)');
        setLoading(false);
        setDebugInfo('Video cargado (nativo)');
      };
      
      const handleError = (e: any) => {
        console.error('❌ Error en video nativo:', e);
        setError(`Error nativo: ${e.target?.error?.message || 'Error desconocido'}`);
        setLoading(false);
      };

      video.addEventListener('loadeddata', handleLoadedData);
      video.addEventListener('error', handleError);

      return () => {
        video.removeEventListener('loadeddata', handleLoadedData);
        video.removeEventListener('error', handleError);
      };
    } 
    // Usar HLS.js para otros navegadores
    else {
      console.log('🔄 Cargando HLS.js...');
      setDebugInfo('Cargando HLS.js...');
      
      import('hls.js').then((Hls) => {
        if (Hls.default.isSupported()) {
          console.log('✅ HLS.js soportado');
          setHlsSupported(true);
          setDebugInfo('HLS.js soportado, inicializando...');
          
          const hls = new Hls.default({
            debug: true, // Habilitar debug de HLS.js
            enableWorker: false, // Deshabilitar worker para debugging
            lowLatencyMode: true,
            maxBufferLength: 30,
            maxMaxBufferLength: 60
          });
          
          hlsRef.current = hls;
          
          hls.loadSource(hlsUrl);
          hls.attachMedia(video);
          
          hls.on(Hls.default.Events.MANIFEST_PARSED, () => {
            console.log('✅ Manifest HLS parseado correctamente');
            setLoading(false);
            setDebugInfo('Manifest HLS cargado');
          });
          
          hls.on(Hls.default.Events.ERROR, (event, data) => {
            console.error('❌ Error HLS.js:', event, data);
            if (data.fatal) {
              setError(`Error HLS: ${data.details || 'Error fatal'}`);
              setLoading(false);
            }
          });
          
          hls.on(Hls.default.Events.MEDIA_ATTACHED, () => {
            console.log('✅ Media attachada a HLS.js');
            setDebugInfo('Media attachada');
          });
          
        } else {
          console.error('❌ HLS.js no soportado');
          setError('HLS.js no soportado en este navegador');
          setLoading(false);
        }
      }).catch((err) => {
        console.error('❌ Error cargando HLS.js:', err);
        setError(`Error cargando HLS.js: ${err.message}`);
        setLoading(false);
      });
    }

    return () => {
      if (hlsRef.current) {
        console.log('🧹 Limpiando HLS.js');
        hlsRef.current.destroy();
        hlsRef.current = null;
      }
    };
  }, [canalId]); // Solo depender de canalId

  if (error) {
    return (
      <div className="bg-red-900 rounded-lg p-4 text-center border border-red-700">
        <div className="text-red-400 text-sm mb-2">❌ Error de carga</div>
        <div className="text-red-300 text-xs mb-2">{error}</div>
        <div className="text-gray-400 text-xs">{nombre}</div>
        <button 
          onClick={() => window.location.reload()} 
          className="mt-2 px-3 py-1 bg-red-700 text-white text-xs rounded hover:bg-red-600"
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
          <div className="absolute inset-0 bg-gray-700 flex flex-col items-center justify-center z-10">
            <div className="text-blue-400 mb-2">🔄 {debugInfo}</div>
            <div className="text-xs text-gray-400">Cargando {nombre}...</div>
          </div>
        )}
        <video
          ref={videoRef}
          autoPlay
          muted
          playsInline
          controls
          className="w-full h-48 object-cover bg-black"
          style={{ minHeight: '192px' }}
        />
      </div>
      <div className="p-3">
        <div className="text-white font-medium text-sm">{nombre}</div>
        <div className="text-gray-400 text-xs mt-1">
          📹 Solo Video | {hlsSupported ? 'HLS.js' : 'Nativo'}
        </div>
        {debugInfo && (
          <div className="text-blue-400 text-xs mt-1">Debug: {debugInfo}</div>
        )}
      </div>
    </div>
  );
}
EOF

# Reconstruir contenedor web con componente corregido
echo "🔄 Reconstruyendo dashboard..."
docker compose build --no-cache web
docker compose up -d web

echo "✅ COMPONENTE VIDEOCARD CORREGIDO"
echo "================================="
echo "🌐 Accede a: http://161.10.191.239:3000"
echo "🔍 Abre la consola del navegador (F12) para ver los logs de debugging"
echo "📱 El componente ahora muestra información detallada de debugging"
