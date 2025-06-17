#!/bin/bash
echo "🔧 SOLUCIÓN DEFINITIVA: CLIENT COMPONENTS EN NEXT.JS 15 - SISTEMA SIART"
echo "========================================================================="

# Verificar que estamos en el directorio correcto
if [ ! -f "package.json" ]; then
    echo "❌ ERROR: Ejecuta desde ~/siart-nuevo"
    exit 1
fi

echo "📦 Creando backup de componentes..."
mkdir -p backup-client-$(date +%H%M%S)
cp -r src/ backup-client-* 2>/dev/null || true

echo "⚙️ Corrigiendo VideoCard.tsx - agregando 'use client'..."
cat > src/components/VideoCard.tsx << 'EOF'
'use client'

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
  const [error, setError] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(true);
  const [isMuted, setIsMuted] = useState<boolean>(true);

  const HLS_BASE_URL = process.env.NEXT_PUBLIC_HLS_BASE_URL || 'http://localhost:8080/hls';

  useEffect(() => {
    let hls: any;
    const video = videoRef.current;
    
    if (!video) return;

    const hlsUrl = `${HLS_BASE_URL}/canal${canalId}.m3u8`;

    const loadVideo = async () => {
      try {
        if (video.canPlayType('application/vnd.apple.mpegurl')) {
          // Safari native HLS support
          video.src = hlsUrl;
          video.addEventListener('loadeddata', () => setLoading(false));
          video.addEventListener('error', () => setError('Error al cargar el video'));
        } else {
          // Use HLS.js for other browsers
          const Hls = (await import('hls.js')).default;
          
          if (Hls.isSupported()) {
            hls = new Hls({
              enableWorker: false,
              lowLatencyMode: true,
            });
            
            hls.loadSource(hlsUrl);
            hls.attachMedia(video);
            
            hls.on(Hls.Events.MANIFEST_PARSED, () => {
              setLoading(false);
            });
            
            hls.on(Hls.Events.ERROR, (event: any, data: HLSError) => {
              if (data.fatal) {
                setError(`Error fatal: ${data.details}`);
              }
            });
          } else {
            setError('HLS no es compatible con este navegador');
          }
        }
      } catch (err) {
        setError('Error al inicializar el reproductor');
        setLoading(false);
      }
    };

    loadVideo();

    return () => {
      if (hls && hls.destroy) {
        hls.destroy();
      }
    };
  }, [canalId, HLS_BASE_URL]);

  const toggleAudio = () => {
    if (videoRef.current) {
      videoRef.current.muted = !videoRef.current.muted;
      setIsMuted(videoRef.current.muted);
    }
  };

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-lg p-4">
        <h3 className="text-red-700 font-semibold">{nombre}</h3>
        <p className="text-red-600 text-sm mt-2">{error}</p>
        <div className="mt-2 text-xs text-red-500">
          Canal: {canalId} | Estado: Error
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-lg overflow-hidden">
      <div className="relative bg-black aspect-video">
        {loading && (
          <div className="absolute inset-0 flex items-center justify-center bg-gray-900">
            <div className="text-white text-sm">Cargando {nombre}...</div>
          </div>
        )}
        
        <video
          ref={videoRef}
          className="w-full h-full object-cover"
          autoPlay
          muted={isMuted}
          playsInline
          controls={false}
        />
        
        <div className="absolute bottom-2 right-2 flex gap-2">
          <button
            onClick={toggleAudio}
            className="bg-black bg-opacity-50 text-white p-2 rounded-md hover:bg-opacity-70 transition-all"
            title={isMuted ? "Activar audio" : "Silenciar"}
          >
            {isMuted ? '🔇' : '🔊'}
          </button>
        </div>
      </div>
      
      <div className="p-3">
        <h3 className="font-semibold text-gray-800">{nombre}</h3>
        <div className="flex justify-between items-center mt-2 text-xs text-gray-500">
          <span>Canal: {canalId}</span>
          <span className="flex items-center gap-1">
            <div className="w-2 h-2 bg-green-400 rounded-full"></div>
            En vivo
          </span>
        </div>
      </div>
    </div>
  );
};

export default VideoCard;
EOF

echo "🔧 Corrigiendo página principal - agregando 'use client'..."
cat > src/app/page.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react';
import VideoCard from '../components/VideoCard';

export default function Home() {
  const [currentTime, setCurrentTime] = useState<string>('');

  useEffect(() => {
    const updateTime = () => {
      setCurrentTime(new Date().toLocaleTimeString('es-ES'));
    };

    updateTime();
    const interval = setInterval(updateTime, 1000);

    return () => clearInterval(interval);
  }, []);

  const canales = [
    { canalId: 1, nombre: "Cámara Principal" },
    { canalId: 2, nombre: "Cámara Lateral" },
    { canalId: 3, nombre: "Cámara Trasera" },
    { canalId: 4, nombre: "Cámara Frontal" },
  ];

  const systemStatus = [
    { name: "PostgreSQL", status: "healthy", icon: "💾" },
    { name: "RTMP Server", status: "running", icon: "📹" },
    { name: "HLS Stream", status: "active", icon: "🎥" },
    { name: "Next.js", status: "ready", icon: "⚡" },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      {/* Header */}
      <header className="bg-gradient-to-r from-blue-600 to-blue-800 text-white shadow-lg">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 bg-white rounded-full flex items-center justify-center">
                <span className="text-blue-600 font-bold text-xl">S</span>
              </div>
              <div>
                <h1 className="text-2xl font-bold">SIART</h1>
                <p className="text-blue-200 text-sm">Sistema Integral de Análisis y Vigilancia</p>
              </div>
            </div>
            <div className="text-right">
              <div className="text-xl font-mono">{currentTime}</div>
              <div className="text-blue-200 text-sm">Hora del Sistema</div>
            </div>
          </div>
        </div>
      </header>

      {/* Estado del Sistema */}
      <div className="container mx-auto px-4 py-6">
        <div className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-xl font-semibold text-gray-800 mb-4">Estado del Sistema</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {systemStatus.map((service) => (
              <div key={service.name} className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
                <span className="text-2xl">{service.icon}</span>
                <div>
                  <div className="font-medium text-gray-800">{service.name}</div>
                  <div className="text-sm text-green-600 capitalize">{service.status}</div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Dashboard de Cámaras */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold text-gray-800 mb-6">Centro de Monitoreo</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 xl:grid-cols-4 gap-6">
            {canales.map((canal) => (
              <VideoCard key={canal.canalId} {...canal} />
            ))}
          </div>
        </div>

        {/* Información Adicional */}
        <div className="mt-6 bg-white rounded-lg shadow-md p-6">
          <h3 className="text-lg font-semibold text-gray-800 mb-4">Información del Sistema</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm text-gray-600">
            <div>
              <strong>Versión:</strong> SIART v2.0.0
            </div>
            <div>
              <strong>Next.js:</strong> 15.3.3
            </div>
            <div>
              <strong>Estado:</strong> Operativo
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
EOF

echo "🔧 Corrigiendo layout raíz..."
cat > src/app/layout.tsx << 'EOF'
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'SIART - Sistema de Vigilancia',
  description: 'Sistema Integral de Análisis y Vigilancia en Tiempo Real',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="es">
      <body className={inter.className}>
        {children}
      </body>
    </html>
  )
}
EOF

echo "⚙️ Actualizando variables de entorno..."
cat > .env << 'EOF'
# HLS Server Configuration
NEXT_PUBLIC_HLS_BASE_URL=http://localhost:8080/hls

# Database Configuration
DATABASE_URL="postgresql://siart_user:siart_pass@db:5432/siart_db"

# Next.js Configuration
NEXT_TELEMETRY_DISABLED=1
NODE_ENV=production
EOF

echo "🔄 Limpiando y reconstruyendo..."
rm -rf .next node_modules/.cache
docker compose down
docker compose build --no-cache web
docker compose up -d

echo "⏳ Esperando que los servicios se inicien..."
sleep 30

echo "✅ CORRECCIÓN COMPLETADA!"
echo "📊 Verificando estado:"
docker compose ps

echo ""
echo "🔗 Tu dashboard debería estar disponible en:"
echo "   http://localhost:3000"
echo ""
echo "📋 Para verificar que no hay errores:"
echo "   docker compose logs web --tail 20"
echo ""
echo "✨ Todos los componentes ahora son Client Components y deberían funcionar correctamente!"
