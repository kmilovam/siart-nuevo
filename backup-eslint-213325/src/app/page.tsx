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
