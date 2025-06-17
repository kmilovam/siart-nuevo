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
