'use client';
import React, { useState, useEffect, useMemo } from 'react';
import VideoCard from './VideoCard';

interface Canal {
  canalId: number;
  nombre: string;
  activo: boolean;
}

export default function AdaptiveDashboard() {
  const [canalesActivos, setCanalesActivos] = useState<Canal[]>([]);
  
  const todosLosCanales: Canal[] = useMemo(() => [
    { canalId: 1, nombre: "Canal 1", activo: false },
    { canalId: 2, nombre: "Canal 2", activo: false },
    { canalId: 3, nombre: "Canal 3", activo: false },
    { canalId: 4, nombre: "Canal 4", activo: false }
  ], []);

  useEffect(() => {
    const verificarCanales = async () => {
      const canalesVerificados = await Promise.all(
        todosLosCanales.map(async (canal) => {
          try {
            const response = await fetch(
              `http://192.168.1.8:8080/hls/canal${canal.canalId}/index.m3u8`,
              { method: 'HEAD' }
            );
            return { ...canal, activo: response.ok };
          } catch {
            return { ...canal, activo: false };
          }
        })
      );
      setCanalesActivos(canalesVerificados.filter(canal => canal.activo));
    };

    verificarCanales();
    const intervalo = setInterval(verificarCanales, 10000);
    return () => clearInterval(intervalo);
  }, [todosLosCanales]);

  const getGridStyle = (numCamaras: number) => {
    if (numCamaras === 1) {
      return {
        display: 'grid',
        gridTemplateColumns: '1fr',
        gap: '20px',
        height: '80vh'
      };
    } else if (numCamaras <= 4) {
      return {
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))',
        gap: '20px',
        height: '80vh'
      };
    } else {
      return {
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
        gap: '15px',
        height: '80vh'
      };
    }
  };

  return (
    <div className="adaptive-dashboard p-6">
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-white mb-2">
          Centro de Monitoreo SIART
        </h1>
        <div className="text-blue-400">
          📹 {canalesActivos.length} cámara(s) activa(s) | 
          Layout: {canalesActivos.length === 1 ? 'Pantalla Completa' : 'Grid Adaptativo'}
        </div>
      </div>
      
      {canalesActivos.length === 0 ? (
        <div className="text-center text-gray-400 mt-20">
          <div className="text-6xl mb-4">📡</div>
          <div className="text-xl">Esperando transmisiones...</div>
          <div className="text-sm mt-2">Inicia tu drone para ver video en vivo</div>
        </div>
      ) : (
        <div style={getGridStyle(canalesActivos.length)}>
          {canalesActivos.map((canal) => (
            <VideoCard
              key={canal.canalId}
              canalId={canal.canalId}
              nombre={canal.nombre}
            />
          ))}
        </div>
      )}
    </div>
  );
}
