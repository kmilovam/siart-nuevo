'use client'
import { useEffect, useRef, useState } from 'react'

interface VideoCardProps {
  cameraId: number
  name: string
}

export default function VideoCard({ cameraId, name }: VideoCardProps) {
  const videoRef = useRef<HTMLVideoElement>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState(false)
  
  const hlsUrl = `${process.env.NEXT_PUBLIC_HLS_BASE_URL}/canal${cameraId}.m3u8`

  useEffect(() => {
    let hls: any = null
    
    const loadVideo = async () => {
      if (!videoRef.current) return
      
      try {
        if (videoRef.current.canPlayType('application/vnd.apple.mpegurl')) {
          // Safari native HLS support
          videoRef.current.src = hlsUrl
        } else {
          // Use HLS.js for other browsers
          const Hls = await import('hls.js')
          if (Hls.default.isSupported()) {
            hls = new Hls.default()
            hls.loadSource(hlsUrl)
            hls.attachMedia(videoRef.current)
            hls.on(Hls.default.Events.ERROR, () => setError(true))
          }
        }
        setIsLoading(false)
      } catch (err) {
        setError(true)
        setIsLoading(false)
      }
    }

    loadVideo()

    return () => {
      if (hls) {
        hls.destroy()
      }
    }
  }, [hlsUrl])

  if (error) {
    return (
      <div className="bg-gray-800 rounded-lg p-4 aspect-video flex items-center justify-center">
        <p className="text-white">Error: No se pudo cargar {name}</p>
      </div>
    )
  }

  return (
    <div className="bg-gray-900 rounded-lg overflow-hidden shadow-lg">
      <div className="relative aspect-video">
        {isLoading && (
          <div className="absolute inset-0 bg-gray-700 flex items-center justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
          </div>
        )}
        <video
          ref={videoRef}
          className="w-full h-full object-cover"
          controls
          autoPlay
          muted
          playsInline
        />
      </div>
      <div className="p-3">
        <h3 className="text-white font-medium">{name}</h3>
        <div className="flex items-center justify-between mt-2">
          <span className="text-green-400 text-sm">● En vivo</span>
          <button className="text-blue-400 hover:text-blue-300 text-sm">
            Ver detalles
          </button>
        </div>
      </div>
    </div>
  )
}
