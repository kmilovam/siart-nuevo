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
