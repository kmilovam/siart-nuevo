#!/bin/bash
echo "📋 DEBUGGING AVANZADO - DASHBOARD WEB"
echo "===================================="

cat > public/debug-hls.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Debug HLS SIART</title>
    <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
</head>
<body>
    <h2>Test HLS Stream - SIART</h2>
    <video id="video" controls autoplay muted style="width: 100%; max-width: 640px;"></video>
    <div id="debug"></div>
    
    <script>
        const video = document.getElementById('video');
        const debug = document.getElementById('debug');
        const hlsUrl = 'http://localhost:8080/hls/canal1.m3u8';
        
        function log(message) {
            console.log(message);
            debug.innerHTML += '<div>' + message + '</div>';
        }
        
        log('🎥 Iniciando test HLS...');
        log('URL: ' + hlsUrl);
        
        if (video.canPlayType('application/vnd.apple.mpegurl')) {
            log('✅ Soporte nativo HLS detectado');
            video.src = hlsUrl;
        } else if (Hls.isSupported()) {
            log('✅ HLS.js soportado');
            const hls = new Hls({debug: true});
            hls.loadSource(hlsUrl);
            hls.attachMedia(video);
            
            hls.on(Hls.Events.MANIFEST_PARSED, () => {
                log('✅ Manifest parseado correctamente');
            });
            
            hls.on(Hls.Events.ERROR, (event, data) => {
                log('❌ Error HLS: ' + JSON.stringify(data));
            });
        } else {
            log('❌ HLS no soportado');
        }
    </script>
</body>
</html>
EOF

echo "✅ Archivo de debugging creado"
echo "🌐 Accede a: http://161.10.191.239:3000/debug-hls.html"
echo "🔍 Este archivo te mostrará exactamente qué está fallando"
