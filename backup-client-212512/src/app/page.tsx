import VideoCard from '@/components/VideoCard'

const cameras = [
  { id: 1, name: 'Cámara Principal' },
  { id: 2, name: 'Cámara Entrada' },
  { id: 3, name: 'Cámara Parking' },
  { id: 4, name: 'Cámara Trasera' }
]

export default function Dashboard() {
  return (
    <div className="min-h-screen bg-gray-950">
      {/* Header */}
      <header className="bg-blue-900 shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <h1 className="text-2xl font-bold text-white">SIART - Sistema de Vigilancia</h1>
            <div className="text-white text-sm">
              {new Date().toLocaleString('es-ES')}
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-6">
          <h2 className="text-xl font-semibold text-white mb-2">Centro de Comando</h2>
          <div className="flex space-x-4 text-sm">
            <span className="text-green-400">● PostgreSQL: Conectado</span>
            <span className="text-green-400">● RTMP Server: Activo</span>
            <span className="text-green-400">● Sistema: Operativo</span>
          </div>
        </div>

        {/* Video Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
          {cameras.map((camera) => (
            <VideoCard 
              key={camera.id} 
              cameraId={camera.id} 
              name={camera.name} 
            />
          ))}
        </div>
      </main>
    </div>
  )
}
