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
