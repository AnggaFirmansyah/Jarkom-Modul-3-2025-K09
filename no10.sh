# Langkah Konfigurasi
# Di node Elros
# Pastikan DNS diarahkan ke Minastir
printf "nameserver 10.68.5.2\n" > /etc/resolv.conf

# Tambahkan proxy jika perlu akses apt
cat > /etc/apt/apt.conf.d/00proxy <<'EOF'
Acquire::http::Proxy  "http://10.68.5.2:3128";
Acquire::https::Proxy "http://10.68.5.2:3128";
EOF

# Update dan install nginx
apt update -o Acquire::ForceIPv4=true -y
apt install -y nginx

# Backup default config
mv /etc/nginx/sites-enabled/default /root/default.bak

# Konfigurasi load balancer Laravel
cat > /etc/nginx/sites-available/laravel-lb.conf <<'EOF'
upstream laravel_backend {
    server 10.68.1.2:8001;
    server 10.68.1.3:8002;
    server 10.68.1.4:8003;
}

server {
    listen 80;
    server_name laravel.K09.com;

    location / {
        proxy_pass http://laravel_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

ln -s /etc/nginx/sites-available/laravel-lb.conf /etc/nginx/sites-enabled/
nginx -t && service nginx restart


# Tambahkan Domain di DNS Master (Erendis)
# Tambahkan satu domain baru untuk load balancer:
# Di node Erendis (DNS Master)
nano /etc/bind/zone/numenor.K09.com

# Tambahkan:
laravel  IN  A  10.68.1.7

# Lalu reload:
service bind9 restart
