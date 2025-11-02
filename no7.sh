#!/bin/bash
# =========================================================
# Soal 7 - Setup Laravel Worker Nodes (Elendil, Isildur, Anarion)
# =========================================================
# Tiap node worker akan menjalankan aplikasi Laravel sederhana
# dengan PHP 8.4 + Nginx dan menggunakan resource GitHub.
# =========================================================

set -e

# 1️⃣ Konfigurasi konektivitas dasar
echo "[INFO] Menyiapkan koneksi DNS & proxy..."
cat > /etc/resolv.conf <<EOF
nameserver 10.68.5.2
options timeout:2 attempts:2
EOF

# Proxy agar apt & composer bisa internet
export http_proxy="http://10.68.5.2:3128"
export https_proxy="http://10.68.5.2:3128"
export COMPOSER_ALLOW_SUPERUSER=1

# 2️⃣ Instal dependensi sistem & PHP
echo "[INFO] Menginstal dependensi dasar..."
apt update -o Acquire::ForceIPv4=true -y
apt install -y curl git unzip ca-certificates lsb-release gnupg apt-transport-https

# Tambah repo PHP 8.4 dari sury.org
if [ ! -f /etc/apt/sources.list.d/sury.list ]; then
    curl -fsSL https://packages.sury.org/php/apt.gpg | tee /etc/apt/trusted.gpg.d/sury.gpg >/dev/null
    echo "deb https://packages.sury.org/php $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/sury.list
fi

apt update -o Acquire::ForceIPv4=true -y
apt install -y nginx php8.4-fpm php8.4-cli php8.4-common \
    php8.4-curl php8.4-mbstring php8.4-xml php8.4-zip php8.4-gd \
    php8.4-intl php8.4-bcmath php8.4-mysql php8.4-sqlite3

# 3️⃣ Instal Composer
echo "[INFO] Menginstal Composer..."
curl -sS https://getcomposer.org/installer -o composer-setup.php
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm -f composer-setup.php
composer --version

# 4️⃣ Deploy project Laravel
echo "[INFO] Mengunduh proyek Laravel dari GitHub..."
mkdir -p /var/www
cd /var/www

rm -rf laravel-app || true
git clone https://github.com/elshiraphine/laravel-simple-rest-api laravel-app

cd laravel-app
composer install --no-dev

cp .env.example .env
php artisan key:generate

# Atur izin agar bisa diakses web server
chown -R www-data:www-data /var/www/laravel-app
chmod -R 775 storage bootstrap/cache

# 5️⃣ Konfigurasi Nginx per node
echo "[INFO] Mengonfigurasi Nginx untuk node ini..."

# Tentukan domain berdasarkan hostname
HOST=$(hostname)
case $HOST in
    elendil) DOMAIN="elendil.lordoftherings.k09.com" ;;
    isildur) DOMAIN="isildur.lordoftherings.k09.com" ;;
    anarion) DOMAIN="anarion.lordoftherings.k09.com" ;;
    *) DOMAIN="worker-unknown.local" ;;
esac

# Bersihkan konfigurasi default
rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

# Buat konfigurasi vhost Laravel
cat >/etc/nginx/sites-available/laravel.conf <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    root /var/www/laravel-app/public;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }

    error_log /var/log/nginx/${DOMAIN}_error.log;
    access_log /var/log/nginx/${DOMAIN}_access.log;
}
EOF

ln -sf /etc/nginx/sites-available/laravel.conf /etc/nginx/sites-enabled/laravel.conf
nginx -t && systemctl restart nginx && systemctl restart php8.4-fpm

echo "[SUCCESS] Worker Laravel siap diakses pada http://${DOMAIN}"

# 6️⃣ Tes ringan (opsional)
echo "[INFO] Menjalankan tes sederhana..."
curl -I "http://${DOMAIN}" || echo "[WARN] Tes gagal — pastikan DNS sudah mengarah dengan benar."
