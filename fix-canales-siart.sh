#!/bin/bash
echo "🔧 SOLUCIONANDO CANALES NO VISIBLES - DASHBOARD SIART"
echo "=================================================="

# 1. Crear página principal simplificada que siempre muestre los 4 canales
echo "📱 Creando dashboard principal simplificado..."
mkdir -p src/app
cat > src/app/page.tsx << 'EOF'
'use client';
import React from 'react';
import HeaderInstitucional from '../components/HeaderInstitucional';
import VideoCard from '../components/VideoCard';

// Array fijo de canales - SIEMPRE se mostrarán
const canales = [
  { canalId: 1, nombre: "Canal 1" },
  { canalId: 2, nombre: "Canal 2" },
  { canalId: 3, nombre: "Canal 3" },
  { canalId: 4, nombre: "Canal 4" }
];

export default function Dashboard() {
  console.log('🎥 Renderizando dashboard con canales:', canales);
  
  return (
    <div className="dashboard-siart">
      <HeaderInstitucional />
      
      <main className="main-content">
        <div className="content-overlay">
          <div className="dashboard-title">
            <h2>Centro de Monitoreo SIART</h2>
            <p>📹 {canales.length} canales configurados</p>
          </div>
          
          <div className="dashboard-grid">
            {canales.map((canal) => {
              console.log('🔄 Renderizando canal:', canal);
              return (
                <VideoCard
                  key={canal.canalId}
                  canalId={canal.canalId}
                  nombre={canal.nombre}
                />
              );
            })}
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
          max-width: 1400px;
          margin: 0 auto;
        }
        
        .dashboard-title {
          text-align: center;
          margin-bottom: 2rem;
        }
        
        .dashboard-title h2 {
          font-size: 2rem;
          font-weight: 700;
          color: white;
          margin-bottom: 0.5rem;
          text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.5);
        }
        
        .dashboard-title p {
          color: #00cc66;
          font-size: 1rem;
          font-weight: 500;
        }
        
        .dashboard-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(450px, 1fr));
          gap: 2rem;
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
          
          .dashboard-title h2 {
            font-size: 1.5rem;
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

# 2. Crear VideoCard funcional y siempre visible
echo "🎥 Creando VideoCard simplificado..."
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
  const [connected, setConnected] = useState(false);

  console.log(`🎬 VideoCard ${nombre} iniciando...`);

  useEffect(() => {
    const video = videoRef.current;
    if (!video) {
      console.log(`❌ Video element no encontrado para ${nombre}`);
      return;
    }

    // URL HLS con estructura correcta
    const hlsUrl = `${process.env.NEXT_PUBLIC_HLS_BASE_URL || 'http://192.168.1.8:8080/hls'}/canal${canalId}/index.m3u8`;
    
    console.log(`🔗 Intentando cargar ${nombre} desde:`, hlsUrl);

    if (video.canPlayType('application/vnd.apple.mpegurl')) {
      // Safari nativo
      console.log(`🍎 Usando soporte nativo para ${nombre}`);
      video.src = hlsUrl;
      video.addEventListener('loadeddata', () => {
        console.log(`✅ ${nombre} cargado correctamente (nativo)`);
        setLoading(false);
        setConnected(true);
      });
      video.addEventListener('error', () => {
        console.log(`❌ Error nativo en ${nombre}`);
        setLoading(false);
        setConnected(false);
      });
    } else {
      // HLS.js para otros navegadores
      console.log(`🔧 Cargando HLS.js para ${nombre}...`);
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
            console.log(`✅ ${nombre} - Manifest HLS parseado correctamente`);
            setLoading(false);
            setConnected(true);
          });
          
          hls.on(Hls.default.Events.ERROR, (event: any, data: any) => {
            console.log(`⚠️ ${nombre} - Error HLS:`, data);
            if (data.fatal) {
              setError(`Error HLS: ${data.details}`);
              setLoading(false);
            }
          });
        } else {
          console.log(`❌ HLS.js no soportado para ${nombre}`);
          setError('HLS.js no soportado');
          setLoading(false);
        }
      }).catch(err => {
        console.error(`❌ Error cargando HLS.js para ${nombre}:`, err);
        setError('Error cargando HLS.js');
        setLoading(false);
      });
    }

    return () => {
      if (hlsRef.current) {
        console.log(`🧹 Limpiando HLS para ${nombre}`);
        hlsRef.current.destroy();
      }
    };
  }, [canalId, nombre]);

  // SIEMPRE retornar el componente - nunca null
  return (
    <div className="video-card">
      <div className="card-header">
        <span className="channel-name">{nombre}</span>
        <div className="signal-indicator">
          <span className={`signal-dot ${connected ? 'connected' : loading ? 'loading' : 'standby'}`}></span>
          <span className="signal-text">
            {loading ? 'Conectando...' : connected ? 'EN VIVO' : error ? 'Error' : 'Standby'}
          </span>
        </div>
      </div>
      
      <div className="video-container">
        {loading && (
          <div className="overlay">
            <div className="loading-content">
              <div className="spinner"></div>
              <div>Inicializando {nombre}</div>
            </div>
          </div>
        )}
        
        {error && !loading && (
          <div className="overlay error-overlay">
            <div className="error-content">
              <div className="error-icon">⚠️</div>
              <div className="error-text">{error}</div>
              <button onClick={() => window.location.reload()}>
                Reintentar
              </button>
            </div>
          </div>
        )}
        
        {!connected && !loading && !error && (
          <div className="overlay standby-overlay">
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
          background: rgba(26, 26, 26, 0.8);
          backdrop-filter: blur(10px);
          border-radius: 15px;
          overflow: hidden;
          box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
          border: 1px solid rgba(0, 102, 51, 0.3);
          transition: all 0.3s ease;
          min-height: 300px;
        }
        
        .video-card:hover {
          transform: translateY(-5px);
          box-shadow: 0 12px 40px rgba(0, 102, 51, 0.3);
          border-color: rgba(0, 255, 136, 0.5);
        }
        
        .card-header {
          background: linear-gradient(90deg, #006633, #004d26);
          padding: 1rem;
          border-bottom: 2px solid #00cc66;
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
        
        .signal-dot.loading {
          background: #ffaa00;
          animation: pulse 1s infinite;
        }
        
        .signal-dot.standby {
          background: #666;
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
          min-height: 200px;
        }
        
        .video-player {
          width: 100%;
          height: 100%;
          object-fit: cover;
        }
        
        .overlay {
          position: absolute;
          inset: 0;
          display: flex;
          align-items: center;
          justify-content: center;
          z-index: 5;
        }
        
        .loading-content, .error-content, .standby-content {
          text-align: center;
          color: white;
        }
        
        .spinner {
          width: 40px;
          height: 40px;
          border: 3px solid rgba(255, 255, 255, 0.3);
          border-top: 3px solid white;
          border-radius: 50%;
          animation: spin 1s linear infinite;
          margin: 0 auto 1rem;
        }
        
        .drone-icon {
          font-size: 3rem;
          margin-bottom: 1rem;
          opacity: 0.5;
        }
        
        .error-icon {
          font-size: 3rem;
          margin-bottom: 1rem;
        }
        
        .error-overlay {
          background: rgba(139, 0, 0, 0.8);
        }
        
        .standby-overlay {
          background: linear-gradient(135deg, #1a1a1a, #2d2d2d);
        }
        
        button {
          background: #006633;
          color: white;
          border: none;
          padding: 0.5rem 1rem;
          border-radius: 5px;
          cursor: pointer;
          margin-top: 1rem;
        }
        
        button:hover {
          background: #004d26;
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

# 3. Verificar que HeaderInstitucional esté correcto
echo "🎨 Verificando HeaderInstitucional..."
cat > src/components/HeaderInstitucional.tsx << 'EOF'
'use client';
import React, { useState, useEffect } from 'react';

export default function HeaderInstitucional() {
  const [currentTime, setCurrentTime] = useState('');

  useEffect(() => {
    const updateTime = () => {
      setCurrentTime(new Date().toLocaleTimeString('es-CO', {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      }));
    };

    updateTime();
    const interval = setInterval(updateTime, 1000);
    return () => clearInterval(interval);
  }, []);

  return (
    <header className="header-siart">
      <div className="header-content">
        <div className="logo-section">
          <div className="logo-container">
            <img 
              src="/images/logo-siart.png" 
              alt="Logo SIART" 
              className="logo-siart"
              onError={(e) => {
                console.log('❌ Error cargando logo SIART');
                (e.target as HTMLImageElement).style.display = 'none';
              }}
            />
          </div>
          <div className="title-section">
            <h1 className="main-title">SIART</h1>
            <p className="subtitle">SISTEMAS AÉREOS REMOTAMENTE TRIPULADOS</p>
          </div>
        </div>
        <div className="system-status">
          <div className="status-indicator">
            <span className="status-dot active"></span>
            <span className="status-text">Sistema Operativo</span>
          </div>
          <div className="current-time">
            {currentTime}
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
        
        .logo-container {
          width: 80px;
          height: 80px;
          background: rgba(255, 255, 255, 0.1);
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          border: 2px solid rgba(255, 255, 255, 0.2);
          box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
        }
        
        .logo-siart {
          width: 60px;
          height: 60px;
          object-fit: contain;
          filter: drop-shadow(0 2px 10px rgba(255, 255, 255, 0.3));
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
          
          .logo-container {
            width: 60px;
            height: 60px;
          }
          
          .logo-siart {
            width: 45px;
            height: 45px;
          }
        }
      `}</style>
    </header>
  );
}
EOF

# 4. Reconstruir servicios
echo "🚀 Reconstruyendo dashboard..."
docker compose build --no-cache web
docker compose up -d web

echo "✅ CANALES RESTAURADOS - DASHBOARD SIART"
echo "======================================="
echo "📱 Los 4 canales ahora se muestran SIEMPRE"
echo "🎥 No depende de verificaciones externas"
echo "🔧 Logs de debugging en consola del navegador"
echo "⚡ Componentes simplificados y robustos"
echo ""
echo "🌐 Accede a: http://192.168.1.8:3000"
echo "🔍 Abre F12 para ver logs de debugging"
EOF
