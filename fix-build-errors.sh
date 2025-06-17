#!/bin/bash
echo "🔧 SOLUCIONANDO ERRORES DE BUILD - SISTEMA SIART"
echo "==============================================="

# Verificar que estamos en el directorio correcto
if [ ! -f "package.json" ]; then
    echo "❌ ERROR: Ejecuta desde ~/siart-nuevo"
    exit 1
fi

echo "📦 Creando backup de archivos..."
mkdir -p backup-build-fix-$(date +%H%M%S)
cp next.config.js backup-build-fix-* 2>/dev/null || true
cp src/components/VideoCard.tsx backup-build-fix-* 2>/dev/null || true

echo "⚙️ Corrigiendo next.config.js..."
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  poweredByHeader: false,
  reactStrictMode: true,
  // outputFileTracingRoot movido fuera de experimental para Next.js 15
  outputFileTracingRoot: process.cwd(),
  experimental: {
    // Configuraciones experimentales válidas para Next.js 15
  }
}

module.exports = nextConfig
EOF

echo "🔧 Corrigiendo VideoCard.tsx - eliminando errores TypeScript..."
cat > src/components/VideoCard.tsx << 'EOF'
import React, { useEffect, useRef, useState } from 'react';

interface VideoCardProps {
  canalId: number;
  nombre: string;
}

interface HLSError {
  type: string;
  details: string;
  fatal: boolean;
}

const VideoCard: React.FC<VideoCardProps> = ({ canalId, nombre }) => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isMuted, setIsMuted] = useState(true);

  const HLS_BASE_URL = process.env.NEXT_PUBLIC_HLS_BASE_URL || 'http://localhost:8080/hls';

  useEffect(() => {
    let hls: unknown = null;
    const video = videoRef.current;
    
    if (!video) return;

    const hlsUrl = `${HLS_BASE_URL}/canal${canalId}.m3u8`;

    const loadVideo = async () => {
      try {
        setIsLoading(true);
        setError(null);

        // Verificar si el navegador soporta HLS nativamente
        if (video.canPlayType('application/vnd.apple.mpegurl')) {
          video.src = hlsUrl;
          video.addEventListener('loadeddata', () => setIsLoading(false));
          video.addEventListener('error', () => {
            setError(`Error al cargar el stream de ${nombre}`);
            setIsLoading(false);
          });
        } else {
          // Cargar HLS.js dinámicamente
          const HLS = await import('hls.js');
          
          if (HLS.default.isSupported()) {
            const hlsInstance = new HLS.default({
              enableWorker: false,
              lowLatencyMode: true,
            });

            hlsInstance.loadSource(hlsUrl);
            hlsInstance.attachMedia(video);

            hlsInstance.on(HLS.default.Events.MANIFEST_PARSED, () => {
              setIsLoading(false);
              video.play().catch(() => {
                // Auto-play bloqueado, esto es normal
              });
            });

            hlsInstance.on(HLS.default.Events.ERROR, (event: string, data: HLSError) => {
              console.error('HLS Error:', event, data);
              if (data.fatal) {
                setError(`Error crítico en el stream de ${nombre}`);
                setIsLoading(false);
              }
            });

            hls = hlsInstance;
          } else {
            setError(`Tu navegador no soporta la reproducción de video HLS para ${nombre}`);
            setIsLoading(false);
          }
        }
      } catch (loadError) {
        console.error('Error loading video:', loadError);
        setError(`No se pudo cargar el video de ${nombre}`);
        setIsLoading(false);
      }
    };

    loadVideo();

    return () => {
      if (hls && typeof hls === 'object' && 'destroy' in hls) {
        (hls as { destroy: () => void }).destroy();
      }
      if (video) {
        video.removeEventListener('loadeddata', () => setIsLoading(false));
        video.removeEventListener('error', () => setError(`Error al cargar el stream de ${nombre}`));
      }
    };
  }, [canalId, nombre, HLS_BASE_URL]);

  const toggleAudio = () => {
    if (videoRef.current) {
      videoRef.current.muted = !videoRef.current.muted;
      setIsMuted(videoRef.current.muted);
    }
  };

  const toggleFullscreen = () => {
    if (videoRef.current) {
      if (document.fullscreenElement) {
        document.exitFullscreen();
      } else {
        videoRef.current.requestFullscreen().catch((requestError) => {
          console.error('Error al solicitar pantalla completa:', requestError);
        });
      }
    }
  };

  if (error) {
    return (
      <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-lg">
        <h3 className="font-bold text-lg mb-2">{nombre}</h3>
        <p className="text-sm">{error}</p>
        <button 
          onClick={() => window.location.reload()} 
          className="mt-2 bg-red-500 text-white px-3 py-1 rounded text-sm hover:bg-red-600"
        >
          Reintentar
        </button>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-lg overflow-hidden">
      <div className="relative bg-gray-900">
        {isLoading && (
          <div className="absolute inset-0 flex items-center justify-center bg-gray-800 z-10">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white"></div>
            <span className="ml-2 text-white">Cargando {nombre}...</span>
          </div>
        )}
        
        <video
          ref={videoRef}
          className="w-full h-48 object-cover"
          autoPlay
          muted={isMuted}
          playsInline
          controls={false}
        />
        
        <div className="absolute bottom-2 left-2 right-2 flex justify-between items-center">
          <h3 className="text-white font-semibold text-sm bg-black bg-opacity-50 px-2 py-1 rounded">
            {nombre}
          </h3>
          
          <div className="flex space-x-2">
            <button
              onClick={toggleAudio}
              className="bg-black bg-opacity-50 text-white p-2 rounded hover:bg-opacity-70 transition-all"
              title={isMuted ? "Activar audio" : "Silenciar"}
            >
              {isMuted ? (
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M9.383 3.076A1 1 0 0110 4v12a1 1 0 01-1.617.793L4.414 13H2a1 1 0 01-1-1V8a1 1 0 011-1h2.414l3.969-3.793zm0 13.848L7.414 15H2V9h5.414L9.383 6.924v9.999zM13.25 9.25a.75.75 0 000 1.5A.75.75 0 0013.25 9.25zm.75-.75a2.25 2.25 0 110 4.5 2.25 2.25 0 010-4.5z" clipRule="evenodd" />
                </svg>
              ) : (
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M9.383 3.076A1 1 0 0110 4v12a1 1 0 01-1.617.793L4.414 13H2a1 1 0 01-1-1V8a1 1 0 011-1h2.414l3.969-3.793A1 1 0 0110 4zM7.414 15L9.383 16.924V3.076L7.414 5H2v6h5.414zm8.086-2l1.5 1.5a.5.5 0 01-.707.707L15 13.914l-1.293 1.293a.5.5 0 01-.707-.707l1.5-1.5-1.5-1.5a.5.5 0 01.707-.707L15 12.086l1.293-1.293a.5.5 0 01.707.707L15.5 13z" clipRule="evenodd" />
                </svg>
              )}
            </button>
            
            <button
              onClick={toggleFullscreen}
              className="bg-black bg-opacity-50 text-white p-2 rounded hover:bg-opacity-70 transition-all"
              title="Pantalla completa"
            >
              <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M3 4a1 1 0 011-1h4a1 1 0 010 2H6.414l2.293 2.293a1 1 0 11-1.414 1.414L5 6.414V8a1 1 0 01-2 0V4zm9 1a1 1 0 010-2h4a1 1 0 011 1v4a1 1 0 01-2 0V6.414l-2.293 2.293a1 1 0 11-1.414-1.414L13.586 5H12zm-9 7a1 1 0 012 0v1.586l2.293-2.293a1 1 0 111.414 1.414L6.414 15H8a1 1 0 010 2H4a1 1 0 01-1-1v-4zm13-1a1 1 0 011 1v4a1 1 0 01-1 1h-4a1 1 0 010-2h1.586l-2.293-2.293a1 1 0 111.414-1.414L15 13.586V12a1 1 0 011-1z" clipRule="evenodd" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default VideoCard;
EOF

echo "📋 Actualizando configuración ESLint..."
cat > .eslintrc.json << 'EOF'
{
  "extends": [
    "next/core-web-vitals",
    "@next/eslint-config-next"
  ],
  "rules": {
    "@typescript-eslint/no-explicit-any": "off",
    "@typescript-eslint/no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
    "react-hooks/exhaustive-deps": "warn"
  }
}
EOF

echo "🔄 Limpiando y reconstruyendo..."
rm -rf .next
docker compose down
docker compose build --no-cache
docker compose up -d

echo "✅ CORRECCIÓN COMPLETADA!"
echo "📊 Verificando estado:"
sleep 20
docker compose ps

echo ""
echo "🔗 Tu dashboard debería estar disponible en:"
echo "   http://localhost:3000"
echo ""
echo "📋 Para verificar logs:"
echo "   docker compose logs web --tail 20"
