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
