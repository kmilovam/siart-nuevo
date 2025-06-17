#!/bin/bash
echo "🎨 IMPLEMENTANDO DISEÑO MODERNO SIART"
echo "==================================="

# 1. Crear directorio para assets
mkdir -p public/images

# 2. Descargar y procesar logo SIART (usuario debe colocar manualmente)
echo "📁 Coloca el logo SIART en: public/images/logo-siart.png"
echo "📁 Coloca la imagen del drone en: public/images/drone-background.jpg"

# 3. Crear HeaderInstitucional con diseño verde policial
mkdir -p src/components
cat > src/components/HeaderInstitucional.tsx << 'EOF'
'use client';
import React from 'react';

export default function HeaderInstitucional() {
  return (
    <header className="header-siart">
      <div className="header-content">
        <div className="logo-section">
          <img 
            src="/images/logo-siart.png" 
            alt="Logo SIART" 
            className="logo-siart"
          />
          <div className="title-section">
            <h1 className="main-title">S.I.A.R.T</h1>
            <p className="subtitle">SISTEMAS AÉREOS REMOTAMENTE TRIPULADOS</p>
          </div>
        </div>
        <div className="system-status">
          <div className="status-indicator">
            <span className="status-dot active"></span>
            <span className="status-text">Sistema Operativo</span>
          </div>
          <div className="current-time">
            {new Date().toLocaleTimeString('es-CO', {
              hour: '2-digit',
              minute: '2-digit',
              second: '2-digit'
            })}
          </div>
        </div>
      </div>

      <style jsx>{`
        .header-siart {
          background: linear-gradient(135deg, #006633 0%, #004d26 100%);
          color: white;
          padding: 1rem 2rem;
          box-shadow: 0 4px 20px rgba(0, 102, 51, 0.3);
          border-bottom: 3px solid #00cc66;
        }
        
        .header-content {
          display: flex;
          justify-content: space-between;
          align-items: center;
          max-width: 1400px;
          margin: 0 auto;
        }
        
        .logo-section {
          display: flex;
          align-items: center;
          gap: 1rem;
        }
        
        .logo-siart {
          width: 80px;
          height: 80px;
          object-fit: contain;
          filter: drop-shadow(0 2px 10px rgba(255, 255, 255, 0.2));
        }
        
        .title-section {
          display: flex;
          flex-direction: column;
        }
        
        .main-title {
          font-size: 2.5rem;
          font-weight: 900;
          margin: 0;
          text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.5);
          letter-spacing: 3px;
        }
        
        .subtitle {
          font-size: 0.9rem;
          margin: 0;
          opacity: 0.9;
          font-weight: 500;
          letter-spacing: 1px;
        }
        
        .system-status {
          display: flex;
          flex-direction: column;
          align-items: flex-end;
          gap: 0.5rem;
        }
        
        .status-indicator {
          display: flex;
          align-items: center;
          gap: 0.5rem;
        }
        
        .status-dot {
          width: 12px;
          height: 12px;
          border-radius: 50%;
          background: #ff4444;
        }
        
        .status-dot.active {
          background: #00ff88;
          box-shadow: 0 0 10px rgba(0, 255, 136, 0.5);
          animation: pulse 2s infinite;
        }
        
        .status-text {
          font-size: 0.9rem;
          font-weight: 500;
        }
        
        .current-time {
          font-family: 'Courier New', monospace;
          font-size: 1.1rem;
          font-weight: bold;
          background: rgba(255, 255, 255, 0.1);
          padding: 0.3rem 0.8rem;
          border-radius: 20px;
          border: 1px solid rgba(255, 255, 255, 0.2);
        }
        
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.5; }
        }
        
        @media (max-width: 768px) {
          .header-content {
            flex-direction: column;
            gap: 1rem;
          }
          
          .main-title {
            font-size: 2rem;
          }
          
          .logo-siart {
            width: 60px;
            height: 60px;
          }
        }
      `}</style>
    </header>
  );
}
EOF

# 4. Crear VideoCard moderno sin errores HLS visibles
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
  const [loading, setLoading] = useState(true);
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;

    const hlsUrl = `${process.env.NEXT_PUBLIC_HLS_BASE_URL || 'http://192.168.1.8:8080/hls'}/canal${canalId}/index.m3u8`;

    if (video.canPlayType('application/vnd.apple.mpegurl')) {
      video.src = hlsUrl;
      video.addEventListener('loadeddata', () => {
        setLoading(false);
        setConnected(true);
      });
      video.addEventListener('error', () => {
        setLoading(false);
        setConnected(false);
      });
    } else {
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
            setLoading(false);
            setConnected(true);
          });
          
          hls.on(Hls.default.Events.ERROR, () => {
            setLoading(false);
            setConnected(false);
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

  return (
    <div className="video-card">
      <div className="card-header">
        <div className="channel-info">
          <span className="channel-name">{nombre}</span>
          <div className="signal-indicator">
            <span className={`signal-dot ${connected ? 'connected' : 'standby'}`}></span>
            <span className="signal-text">
              {loading ? 'Conectando...' : connected ? 'EN VIVO' : 'Standby'}
            </span>
          </div>
        </div>
      </div>
      
      <div className="video-container">
        {loading && (
          <div className="loading-overlay">
            <div className="spinner"></div>
            <div className="loading-text">Inicializando {nombre}</div>
          </div>
        )}
        
        {!connected && !loading && (
          <div className="standby-overlay">
            <div className="standby-content">
              <div className="drone-icon">🚁</div>
              <div className="standby-text">{nombre}</div>
              <div className="standby-subtitle">Esperando transmisión</div>
            </div>
          </div>
        )}
        
        <video
          ref={videoRef}
          autoPlay
          muted
          playsInline
          controls={connected}
          className="video-player"
        />
      </div>

      <style jsx>{`
        .video-card {
          background: linear-gradient(145deg, #1a1a1a, #2d2d2d);
          border-radius: 15px;
          overflow: hidden;
          box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
          border: 1px solid #333;
          transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        
        .video-card:hover {
          transform: translateY(-5px);
          box-shadow: 0 12px 40px rgba(0, 102, 51, 0.2);
        }
        
        .card-header {
          background: linear-gradient(90deg, #006633, #004d26);
          padding: 1rem;
          border-bottom: 2px solid #00cc66;
        }
        
        .channel-info {
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
        
        .channel-name {
          color: white;
          font-weight: 700;
          font-size: 1.1rem;
          text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.5);
        }
        
        .signal-indicator {
          display: flex;
          align-items: center;
          gap: 0.5rem;
        }
        
        .signal-dot {
          width: 10px;
          height: 10px;
          border-radius: 50%;
          background: #666;
        }
        
        .signal-dot.connected {
          background: #00ff88;
          box-shadow: 0 0 10px rgba(0, 255, 136, 0.5);
          animation: pulse 2s infinite;
        }
        
        .signal-dot.standby {
          background: #ffaa00;
          box-shadow: 0 0 10px rgba(255, 170, 0, 0.5);
        }
        
        .signal-text {
          color: white;
          font-size: 0.8rem;
          font-weight: 600;
        }
        
        .video-container {
          position: relative;
          aspect-ratio: 16/9;
          background: #000;
        }
        
        .video-player {
          width: 100%;
          height: 100%;
          object-fit: cover;
        }
        
        .loading-overlay {
          position: absolute;
          inset: 0;
          background: linear-gradient(45deg, #006633, #004d26);
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          z-index: 10;
        }
        
        .spinner {
          width: 40px;
          height: 40px;
          border: 3px solid rgba(255, 255, 255, 0.3);
          border-top: 3px solid white;
          border-radius: 50%;
          animation: spin 1s linear infinite;
          margin-bottom: 1rem;
        }
        
        .loading-text {
          color: white;
          font-weight: 600;
        }
        
        .standby-overlay {
          position: absolute;
          inset: 0;
          background: linear-gradient(135deg, #1a1a1a, #2d2d2d);
          display: flex;
          align-items: center;
          justify-content: center;
          z-index: 5;
        }
        
        .standby-content {
          text-align: center;
          color: #888;
        }
        
        .drone-icon {
          font-size: 3rem;
          margin-bottom: 1rem;
          opacity: 0.5;
        }
        
        .standby-text {
          font-size: 1.2rem;
          font-weight: 600;
          margin-bottom: 0.5rem;
        }
        
        .standby-subtitle {
          font-size: 0.9rem;
          opacity: 0.7;
        }
        
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.5; }
        }
        
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
}
EOF

# 5. Crear Dashboard principal con imagen de fondo del drone
cat > src/app/page.tsx << 'EOF'
'use client';
import React from 'react';
import HeaderInstitucional from '../components/HeaderInstitucional';
import VideoCard from '../components/VideoCard';

const canales = [
  { canalId: 1, nombre: "Canal 1" },
  { canalId: 2, nombre: "Canal 2" },
  { canalId: 3, nombre: "Canal 3" },
  { canalId: 4, nombre: "Canal 4" }
];

export default function Dashboard() {
  return (
    <div className="dashboard-siart">
      <HeaderInstitucional />
      
      <main className="main-content">
        <div className="content-overlay">
          <div className="dashboard-grid">
            {canales.map((canal) => (
              <VideoCard
                key={canal.canalId}
                canalId={canal.canalId}
                nombre={canal.nombre}
              />
            ))}
          </div>
        </div>
      </main>

      <style jsx global>{`
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        
        body {
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
          background: #0a0a0a;
          color: white;
          overflow-x: hidden;
        }
        
        .dashboard-siart {
          min-height: 100vh;
          background: 
            linear-gradient(rgba(0, 0, 0, 0.7), rgba(0, 0, 0, 0.5)),
            url('/images/drone-background.jpg') center/cover no-repeat;
          background-attachment: fixed;
        }
        
        .main-content {
          position: relative;
          min-height: calc(100vh - 120px);
          padding: 2rem;
        }
        
        .content-overlay {
          background: rgba(0, 0, 0, 0.4);
          backdrop-filter: blur(2px);
          border-radius: 20px;
          padding: 2rem;
          border: 1px solid rgba(0, 102, 51, 0.3);
        }
        
        .dashboard-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(450px, 1fr));
          gap: 2rem;
          max-width: 1400px;
          margin: 0 auto;
        }
        
        @media (max-width: 768px) {
          .main-content {
            padding: 1rem;
          }
          
          .dashboard-grid {
            grid-template-columns: 1fr;
            gap: 1.5rem;
          }
          
          .content-overlay {
            padding: 1rem;
          }
        }
        
        @media (max-width: 500px) {
          .dashboard-grid {
            grid-template-columns: 1fr;
          }
        }
      `}</style>
    </div>
  );
}
EOF

# 6. Actualizar configuración Next.js
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  reactStrictMode: false,
  images: {
    domains: ['localhost', '192.168.1.8'],
    unoptimized: true
  }
}

module.exports = nextConfig
EOF

# 7. Reconstruir servicios con nuevo diseño
echo "🚀 Reconstruyendo dashboard con diseño SIART..."
docker compose build --no-cache web
docker compose up -d web

echo "✅ DISEÑO MODERNO SIART IMPLEMENTADO"
echo "==================================="
echo "🎨 Header: Verde policial (#006633)"
echo "📱 Canales: Simplificados (Canal 1-4)"
echo "🚁 Fondo: Imagen del drone (coloca en public/images/)"
echo "🔒 Sin errores HLS visibles"
echo "📋 Logo SIART: Coloca en public/images/logo-siart.png"
echo ""
echo "📁 ARCHIVOS REQUERIDOS:"
echo "   - public/images/logo-siart.png (logo oficial)"
echo "   - public/images/drone-background.jpg (foto del drone)"
echo ""
echo "🌐 Accede a: http://192.168.1.8:3000"
