cat > nginx-config/nginx.conf << 'EOF'
worker_processes 1;
events {
    worker_connections 1024;
}

rtmp {
    server {
        listen 1935;
        chunk_size 4000;
        
        application live {
            live on;
            hls on;
            hls_path /tmp/hls;
            hls_fragment 1s;
            hls_playlist_length 3s;
            hls_nested on;  # Organiza archivos por canal
            hls_cleanup on;
        }
    }
}

http {
    server {
        listen 8080;
        
        location /hls {
            types {
                application/vnd.apple.mpegurl m3u8;
                video/mp2t ts;
            }
            root /tmp;
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header Cache-Control no-cache;
        }
    }
}
EOF