# Persiapan di Elendil, Isildur, dan Anarion
# Set DNS agar bisa resolve lewat Minastir
echo "nameserver 10.68.5.2" > /etc/resolv.conf

# Update dan install dependensi dasar
apt update -y
apt install -y curl git unzip ca-certificates lsb-release gnupg apt-transport-https

# Tambahkan repo PHP 8.4 (sury.org)
curl -fsSL https://packages.sury.org/php/apt.gpg | tee /etc/apt/trusted.gpg.d/sury.gpg >/dev/null
echo "deb https://packages.sury.org/php $(lsb_release -sc) main" > /etc/apt/sources.list.d/sury.list
apt update -y

# Install PHP dan Nginx
apt install -y php8.4-fpm php8.4-cli php8.4-common php8.4-curl php8.4-mbstring \
php8.4-xml php8.4-zip php8.4-gd php8.4-intl php8.4-bcmath php8.4-mysql php8.4-sqlite3 nginx

# Install composer
curl -o composer-setup.php https://getcomposer.org/installer
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm -f composer-setup.php
composer --version

# Clone project Laravel
mkdir -p /var/www
cd /var/www
rm -rf resource-laravel
git clone https://github.com/elshiraphine/laravel-simple-rest-api resource-laravel

cd resource-laravel
composer update --no-dev

# Salin file .env dan generate key
cp .env.example .env
php artisan key:generate

# Atur izin folder
chown -R www-data:www-data /var/www/resource-laravel
chmod -R 775 /var/www/resource-laravel/storage
chmod -R 775 /var/www/resource-laravel/bootstrap/cache


# Konfigurasi Nginx di Elendil
DOMAIN="elendil.k09.com"
rm -f /etc/nginx/sites-enabled/default

cat >/etc/nginx/sites-available/laravel.conf <<EOF
server {
    listen 80;
    server_name ${DOMAIN};
    root /var/www/resource-laravel/public;
    index index.php index.html;
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}
EOF

ln -sf /etc/nginx/sites-available/laravel.conf /etc/nginx/sites-enabled/laravel.conf
nginx -t && service nginx restart && service php8.4-fpm restart


# Konfigurasi Nginx di Isildur
DOMAIN="isildur.k09.com"
rm -f /etc/nginx/sites-enabled/default

cat >/etc/nginx/sites-available/laravel.conf <<EOF
server {
    listen 80;
    server_name ${DOMAIN};
    root /var/www/resource-laravel/public;
    index index.php index.html;
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}
EOF

ln -sf /etc/nginx/sites-available/laravel.conf /etc/nginx/sites-enabled/laravel.conf
nginx -t && service nginx restart && service php8.4-fpm restart


# Konfigurasi Nginx di Anarion
DOMAIN="anarion.k09.com"
rm -f /etc/nginx/sites-enabled/default

cat >/etc/nginx/sites-available/laravel.conf <<EOF
server {
    listen 80;
    server_name ${DOMAIN};
    root /var/www/resource-laravel/public;
    index index.php index.html;
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}
EOF

ln -sf /etc/nginx/sites-available/laravel.conf /etc/nginx/sites-enabled/laravel.conf
nginx -t && service nginx restart && service php8.4-fpm restart


 Testing (di Pharazon)
# Pastikan DNS ke Minastir
echo "nameserver 10.68.5.2" > /etc/resolv.conf

# Install lynx
apt update -y && apt install -y lynx

# Cek apakah web Laravel dapat diakses
lynx -dump http://elendil.k09.com
lynx -dump http://isildur.k09.com
lynx -dump http://anarion.k09.com
