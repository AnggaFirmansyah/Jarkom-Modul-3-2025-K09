# Persiapan di Elendil, Isildur, dan Anarion
# Atur DNS & Proxy agar bisa konek internet
printf "nameserver 10.68.5.2\noptions timeout:2 attempts:2\n" > /etc/resolv.conf
export http_proxy=http://10.68.5.2:3128
export https_proxy=http://10.68.5.2:3128
export COMPOSER_ALLOW_SUPERUSER=1

# Instalasi dependensi dasar
apt update -o Acquire::ForceIPv4=true -y
apt install -y curl git unzip ca-certificates lsb-release gnupg apt-transport-https

# Tambahkan repo PHP 8.4 (sury.org)
curl -fsSL https://packages.sury.org/php/apt.gpg | tee /etc/apt/trusted.gpg.d/sury.gpg >/dev/null
echo "deb https://packages.sury.org/php $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/sury.list
apt update -o Acquire::ForceIPv4=true -y

# Instal PHP dan nginx
apt install -y \
  php8.4-fpm php8.4-cli php8.4-common php8.4-curl php8.4-mbstring php8.4-xml \
  php8.4-zip php8.4-gd php8.4-intl php8.4-bcmath php8.4-mysql php8.4-sqlite3 \
  nginx

# Instal composer
curl -o composer-setup.php https://getcomposer.org/installer
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm -f composer-setup.php
composer --version

# Clone proyek Laravel
export http_proxy=http://10.68.5.2:3128
export https_proxy=http://10.68.5.2:3128

mkdir -p /var/www
cd /var/www
rm -rf resource-laravel
git clone https://github.com/elshiraphine/laravel-simple-rest-api resource-laravel

cd resource-laravel
composer update --no-dev
cp .env.example .env
php artisan key:generate

# Atur izin folder
chown -R www-data:www-data /var/www/resource-laravel
chmod -R 775 /var/www/resource-laravel/storage
chmod -R 775 /var/www/resource-laravel/bootstrap/cache

# ========================================
# Konfigurasi Nginx untuk setiap worker
# ========================================

# ELENDIL
DOMAIN="elendil.k09.com"
rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
cat >/etc/nginx/sites-available/laravel.conf <<EOF
server {
    listen 80;
    server_name ${DOMAIN};
    root /var/www/resource-laravel/public;
    index index.php index.html;
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}
EOF
ln -sf /etc/nginx/sites-available/laravel.conf /etc/nginx/sites-enabled/laravel.conf
nginx -t && service nginx restart && service php8.4-fpm restart

# ISILDUR
DOMAIN="isildur.k09.com"
rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
cat >/etc/nginx/sites-available/laravel.conf <<EOF
server {
    listen 80;
    server_name ${DOMAIN};
    root /var/www/resource-laravel/public;
    index index.php index.html;
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}
EOF
ln -sf /etc/nginx/sites-available/laravel.conf /etc/nginx/sites-enabled/laravel.conf
nginx -t && service nginx restart && service php8.4-fpm restart

# ANARION
DOMAIN="anarion.k09.com"
rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
cat >/etc/nginx/sites-available/laravel.conf <<EOF
server {
    listen 80;
    server_name ${DOMAIN};
    root /var/www/resource-laravel/public;
    index index.php index.html;
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}
EOF
ln -sf /etc/nginx/sites-available/laravel.conf /etc/nginx/sites-enabled/laravel.conf
nginx -t && service nginx restart && service php8.4-fpm restart

# Verifikasi di klien Pharazon
printf "nameserver 10.68.5.2\noptions timeout:2 attempts:2\n" >/etc/resolv.conf
apt update -o Acquire::ForceIPv4=true -y
apt install -y lynx

lynx -dump http://elendil.k09.com
lynx -dump http://isildur.k09.com
lynx -dump http://anarion.k09.com
