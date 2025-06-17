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
