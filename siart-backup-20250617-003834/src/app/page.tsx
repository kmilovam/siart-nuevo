'use client'

import { useState, useEffect } from 'react'
import VideoCard from '../components/VideoCard'

export default function Dashboard() {
  const [currentTime, setCurrentTime] = useState('')

  useEffect(() => {
    const updateTime = () => {
      setCurrentTime(new Date().toLocaleTimeString())
    }
    
    updateTime()
    const interval = setInterval(updateTime, 1000)
    
    return () => clearInterval(interval)
  }, [])

  const canales = [
    { canalId: 1, nombre: 'Cámara Principal' },
    { canalId: 2, nombre: 'Cámara Lateral' },
    { canalId: 3, nombre: 'Cámara Trasera' },
    { canalId: 4, nombre: 'Cámara Exterior' },
  ]

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      {/* Header */}
      <header className="bg-gradient-to-r from-blue-600 to-blue-800 text-white shadow-lg">
        <div className="container mx-auto px-4 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <div className="w-12 h-12 bg-white rounded-lg flex items-center justify-center">
                <svg className="w-8 h-8 text-blue-600" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M4 3a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V5a2 2 0 00-2-2H4zm12 12H4l4-8 3 6 2-4 3 6z"/>
                </svg>
              </div>
              <div>
                <h1 className="text-2xl font-bold">SISTEMA SIART</h1>
                <p className="text-blue-200">Sistema Integrado de Análisis y Respuesta en Tiempo Real</p>
              </div>
            </div>
            <div className="text-right">
              <div className="text-xl font-mono">{currentTime}</div>
              <div className="text-blue-200">Estado: Operativo</div>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8">
        {/* Estado del Sistema */}
        <div className="bg-white rounded-lg shadow-md p-6 mb-8">
          <h2 className="text-xl font-semibold text-gray-800 mb-4">Estado del Sistema</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="flex items-center space-x-2">
              <div className="w-3 h-3 bg-green-500 rounded-full"></div>
              <span className="text-gray-700">PostgreSQL</span>
            </div>
            <div className="flex items-center space-x-2">
              <div className="w-3 h-3 bg-green-500 rounded-full"></div>
              <span className="text-gray-700">Servidor RTMP</span>
            </div>
            <div className="flex items-center space-x-2">
              <div className="w-3 h-3 bg-green-500 rounded-full"></div>
              <span className="text-gray-700">Streaming HLS</span>
            </div>
            <div className="flex items-center space-x-2">
              <div className="w-3 h-3 bg-green-500 rounded-full"></div>
              <span className="text-gray-700">Dashboard Web</span>
            </div>
          </div>
        </div>

        {/* Grid de Cámaras */}
        <div className="mb-8">
          <h2 className="text-2xl font-semibold text-gray-800 mb-6">Centro de Monitoreo</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-6">
            {canales.map((canal) => (
              <VideoCard
                key={canal.canalId}
                canalId={canal.canalId}
                nombre={canal.nombre}
              />
            ))}
          </div>
        </div>

        {/* Información del Sistema */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-lg font-semibold text-gray-800 mb-3">Información del Sistema</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm text-gray-600">
            <div>
              <strong>Version:</strong> SIART v2.0
            </div>
            <div>
              <strong>Framework:</strong> Next.js 15.3.3
            </div>
            <div>
              <strong>Estado:</strong> Completamente Operativo
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}
