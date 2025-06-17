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
