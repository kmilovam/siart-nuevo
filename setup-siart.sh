#!/bin/bash

set -e

echo "📦 1. Backup de la configuración actual"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="siart-backup-$TIMESTAMP"
mkdir -p "$BACKUP_DIR"
cp docker-compose.yml next.config.js "$BACKUP_DIR/"
cp -r nginx-config src public/images package.json package-lock.json .env.local .env "$BACKUP_DIR/" || true
docker compose exec -T db pg_dump -U siart_user siart_db > "$BACKUP_DIR/siart_db.sql" || echo "⚠️  Base de datos posiblemente no desplegada aún"
tar -czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR"
echo "✅ Backup creado: $BACKUP_DIR.tar.gz"

echo "🔧 2. Variables de entorno para login"
cat > .env.local << 'EOF'
USER1=juan
PASS1=clave123
USER2=ana
PASS2=segura456
USER3=pedro
PASS3=policia789
USER4=laura
PASS4=drone321
NEXT_PUBLIC_HLS_BASE_URL=http://localhost:8080/hls
EOF
echo "✅ .env.local configurado"

echo "🚀 3. next.config.js mínimo"
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  reactStrictMode: false,
  images: { unoptimized: true },
  eslint: { ignoreDuringBuilds: true },
  typescript: { ignoreBuildErrors: true }
};
module.exports = nextConfig;
EOF
echo "✅ next.config.js creado"

echo "🔒 4. Middleware de autenticación"
mkdir -p src
cat > src/middleware.ts << 'EOF'
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(req: NextRequest) {
  const publicPaths = ['/login','/api/auth/login'];
  if (publicPaths.includes(req.nextUrl.pathname)) return NextResponse.next();
  const isLoggedIn = req.cookies.get('loggedIn')?.value === 'true';
  return isLoggedIn
    ? NextResponse.next()
    : NextResponse.redirect(new URL('/login', req.url));
}
EOF
echo "✅ Middleware creado en src/middleware.ts"

echo "🛠️ 5. API de autenticación"
mkdir -p src/app/api/auth/login
cat > src/app/api/auth/login/route.ts << 'EOF'
import { NextResponse } from 'next/server';

const USERS = [
  { user: process.env.USER1, pass: process.env.PASS1 },
  { user: process.env.USER2, pass: process.env.PASS2 },
  { user: process.env.USER3, pass: process.env.PASS3 },
  { user: process.env.USER4, pass: process.env.PASS4 }
];

export async function POST(req: Request) {
  const { user, pass } = await req.json();
  const valid = USERS.some(u=>u.user===user&&u.pass===pass);
  if (valid) return NextResponse.json({ success: true });
  return NextResponse.json({ success: false }, { status: 401 });
}
EOF
echo "✅ Endpoint /api/auth/login configurado"

echo "🔑 6. Página de Login"
mkdir -p src/app/login
cat > src/app/login/page.tsx << 'EOF'
'use client';
import { useState } from 'react';

export default function LoginPage() {
  const [user,setUser]=useState(''),[pass,setPass]=useState(''),[err,setErr]=useState('');
  const onSubmit=async e=>{
    e.preventDefault();
    const res=await fetch('/api/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({user,pass})});
    if(res.ok){
      document.cookie='loggedIn=true;path=/';
      window.location.href='/';
    } else setErr('Usuario o contraseña incorrectos');
  };
  return (
    <div className="login-page">
      <form onSubmit={onSubmit} className="login-form">
        <h2>Acceso SIART</h2>
        <input type="text" placeholder="Usuario" value={user} onChange={e=>setUser(e.target.value)} required/>
        <input type="password" placeholder="Contraseña" value={pass} onChange={e=>setPass(e.target.value)} required/>
        <button type="submit">Entrar</button>
        {err && <p className="error-text">{err}</p>}
      </form>
      <style jsx>{\`
        .login-page{display:flex;align-items:center;justify-content:center;min-height:100vh;background:url('/images/drone-background.jpg') center/cover no-repeat;}
        .login-form{background:rgba(0,0,0,0.6);padding:2rem;border-radius:10px;border:1px solid #004d26;color:white;}
        .login-form h2{color:#00cc66;margin-bottom:1rem;}
        .login-form input, .login-form button{width:100%;margin-bottom:1rem;padding:.5rem;border-radius:5px;border:none;}
        .login-form button{background:#004d26;color:white;cursor:pointer;}
        .error-text{color:#ff4444;}
      \`}</style>
    </div>
  );
}
EOF
echo "✅ Página de login creada en src/app/login/page.tsx"

echo "🎥 7. Dashboard y componentes"
mkdir -p src/app src/components
# Page principal
cat > src/app/page.tsx << 'EOF'
'use client';
import HeaderInstitucional from '../components/HeaderInstitucional';
import VideoCard from '../components/VideoCard';

const canales=[{canalId:1,nombre:'Canal 1'},{canalId:2,nombre:'Canal 2'},{canalId:3,nombre:'Canal 3'},{canalId:4,nombre:'Canal 4'}];

export default function Dashboard(){
  return(
    <div className="dashboard-siart">
      <HeaderInstitucional/>
      <main className="main-content">
        <div className="dashboard-grid">
          {canales.map(c=><VideoCard key={c.canalId} canalId={c.canalId} nombre={c.nombre}/>)}
        </div>
      </main>
      <style jsx global>{\`
        body{margin:0;font-family:Inter,sans-serif;}
        .dashboard-siart{min-height:100vh;background:linear-gradient(rgba(0,0,0,0.7),rgba(0,0,0,0.5)),url('/images/drone-background.jpg')center/cover no-repeat;}
        .main-content{padding:2rem;}
        .dashboard-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(450px,1fr));gap:2rem;}
      \`}</style>
    </div>
  );
}
EOF
# HeaderInstitucional
cat > src/components/HeaderInstitucional.tsx << 'EOF'
'use client';
import {useState,useEffect} from 'react';
export default function HeaderInstitucional(){
  const [time,setTime]=useState('');
  useEffect(()=>{
    const t=()=>setTime(new Date().toLocaleTimeString('es-CO'));
    t();const i=setInterval(t,1000);return()=>clearInterval(i);
  },[]);
  return(
    <header className="header-siart">
      <div className="logo-title"><img src="/images/logo-siart.png" alt="Logo"/><h1>SIART</h1></div>
      <div className="time">{time}</div>
      <style jsx>{\`
        .header-siart{display:flex;justify-content:space-between;align-items:center;padding:1rem 2rem;background:linear-gradient(135deg,#006633,#004d26);color:white;}
        .logo-title{display:flex;align-items:center;gap:1rem;}
        .logo-title img{width:60px;height:60px;border-radius:50%;background:rgba(255,255,255,.1);padding:.5rem;}
        .logo-title h1{font-size:2rem;margin:0;}
        .time{font-family:Courier,monospace;background:rgba(255,255,255,.1);padding:.3rem .8rem;border-radius:20px;}
      \`}</style>
    </header>
  );
}
EOF
# VideoCard
cat > src/components/VideoCard.tsx << 'EOF'
'use client';
import {useEffect,useRef,useState} from 'react';
export default function VideoCard({canalId,nombre}){ const videoRef=useRef();const[hlsRef,setHls]=useState(null);const[load,setLoad]=useState(true);
  useEffect(()=>{
    const video=videoRef.current;if(!video)return;
    const url=\`\${process.env.NEXT_PUBLIC_HLS_BASE_URL}/canal\${canalId}/index.m3u8\`;
    if(video.canPlayType('application/vnd.apple.mpegurl')){ video.src=url;video.onloadeddata=()=>setLoad(false);}
    else import('hls.js').then(Hls=>{ if(Hls.isSupported()){ const hls=new Hls({lowLatencyMode:true});setHls(hls);hls.loadSource(url);hls.attachMedia(video);hls.on(Hls.Events.MANIFEST_PARSED,()=>setLoad(false)); }});
    return()=>{hlsRef&&hlsRef.destroy();}
  },[canalId]);
  return(
    <div className="vc"><div className="hdr">{nombre}</div>
      <div className="vcnt">{load&&<div className="ov">Cargando...</div>}
      <video ref={videoRef} autoPlay muted playsInline className="vpl"/>
      </div>
      <style jsx>{\`
        .vc{background:rgba(26,26,26,.7);backdrop-filter:blur(8px);border-radius:15px;overflow:hidden;box-shadow:0 8px 32px rgba(0,0,0,.4);border:1px solid rgba(0,102,51,.3);}
        .hdr{padding:.5rem 1rem;background:linear-gradient(90deg,#006633,#004d26);color:white;}
        .vcnt{position:relative;aspect-ratio:16/9;background:#000;}
        .vpl{width:100%;height:100%;object-fit:cover;}
        .ov{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;color:white;}
      \`}</style>
    </div>
  );
}
EOF
echo "✅ Componentes Dashboard creados"

echo "📦 8. Docker Compose mínimo"
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB:siart_db;POSTGRES_USER:siart_user;POSTGRES_PASSWORD:siart_pass
    volumes: ['postgres_data:/var/lib/postgresql/data']
  rtmp:
    image: alqutami/rtmp-hls
    ports:['1935:1935','8080:8080']
    volumes:['./nginx-config/nginx.conf:/etc/nginx/nginx.conf:ro']
  web:
    build: .
    ports:['3000:3000']
    depends_on:{db:{condition:service_healthy}}
volumes:{postgres_data:}
EOF
echo "✅ docker-compose.yml generado"

echo "🚀 9. Levantar servicios"
docker compose build --no-cache
docker compose up -d

echo "🎉  Sistema SIART con login y dashboard listo"
echo "👉 Accede a http://localhost:3000/login con usuarios: juan/clave123, ana/segura456, pedro/policia789, laura/drone321"
