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
