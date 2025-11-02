#!/bin/bash
# =========================================================
# Soal 8 - Database Palantir & Integrasi Laravel Workers
# =========================================================
# Node: Palantir (Database Master)
# Worker: Elendil, Isildur, Anarion
# =========================================================
set -e

#  --- BAGIAN PALANTIR (DATABASE SERVER) ---
if [ "$(hostname)" = "palantir" ]; then
    echo "[INFO] Konfigurasi Database Server di Palantir..."

    # DNS dan Proxy via Minastir
    cat > /etc/resolv.conf <<EOF
nameserver 10.68.5.2
options timeout:2 attempts:2
EOF

    cat > /etc/apt/apt.conf.d/00proxy <<EOF
Acquire::http::Proxy "http://10.68.5.2:3128";
Acquire::https::Proxy "http://10.68.5.2:3128";
EOF

    # Instalasi MariaDB
    apt update -o Acquire::ForceIPv4=true -y
    apt install -y mariadb-server

    # Ubah konfigurasi agar bisa diakses dari luar
    sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
    systemctl restart mariadb

    # Setup database dan user
    mariadb -u root <<'SQL'
CREATE DATABASE IF NOT EXISTS laravel_db;
DROP USER IF EXISTS 'laravel_user'@'%';
CREATE USER 'laravel_user'@'%' IDENTIFIED BY 'password_laravel';
GRANT ALL PRIVILEGES ON laravel_db.* TO 'laravel_user'@'%';
FLUSH PRIVILEGES;
SQL

    echo "[SUCCESS] Database laravel_db siap di Palantir (10.68.4.3)"
fi


#  --- BAGIAN WORKER (Elendil, Isildur, Anarion) ---
if [[ "$(hostname)" =~ ^(elendil|isildur|anarion)$ ]]; then
    echo "[INFO] Konfigurasi Laravel Worker di $(hostname)..."

    cd /var/www/laravel-app || exit 1

    # 🔧 Tambahkan migrasi & seeder baru
    echo "[INFO] Menambahkan struktur database..."
    mkdir -p database/migrations database/seeders

    cat > database/migrations/2025_11_02_000000_create_airings_table.php <<'EOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up() {
        Schema::create('airings', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->string('status');
            $table->date('start_date');
            $table->timestamps();
        });
    }
    public function down() {
        Schema::dropIfExists('airings');
    }
};
EOF

    cat > database/seeders/airing.json <<'EOF'
{
  "data": [
    {"title": "Attack on Titan", "status": "Finished Airing", "start_date": "2013-04-07"},
    {"title": "One Piece", "status": "Currently Airing", "start_date": "1999-10-20"},
    {"title": "Jujutsu Kaisen", "status": "Finished Airing", "start_date": "2020-10-03"}
  ]
}
EOF

    cat > database/seeders/AiringSeeder.php <<'EOF'
<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use App\Models\Airing;
use Illuminate\Support\Facades\File;
class AiringSeeder extends Seeder {
    public function run() {
        $json = File::get(database_path('seeders/airing.json'));
        $data = json_decode($json, true);
        Airing::truncate();
        foreach ($data['data'] ?? [] as $item) {
            Airing::create([
                'title' => $item['title'],
                'status' => $item['status'],
                'start_date' => $item['start_date'],
            ]);
        }
    }
}
EOF

    cat > database/seeders/DatabaseSeeder.php <<'EOF'
<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
class DatabaseSeeder extends Seeder {
    public function run() {
        $this->call([
            AiringSeeder::class
        ]);
    }
}
EOF

    #  Update konfigurasi database di .env
    sed -i "s/^DB_HOST=.*/DB_HOST=10.68.4.3/" .env
    sed -i "s/^DB_DATABASE=.*/DB_DATABASE=laravel_db/" .env
    sed -i "s/^DB_USERNAME=.*/DB_USERNAME=laravel_user/" .env
    sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=password_laravel/" .env

    #  Migrasi dan seeding database
    php artisan migrate:fresh --seed

    #  Nginx per-node
    echo "[INFO] Menyusun konfigurasi Nginx..."

    IP=""
    PORT=""
    DOMAIN=""

    case "$(hostname)" in
        elendil) IP="10.68.1.2"; PORT="8001"; DOMAIN="elendil.k09.com" ;;
        isildur) IP="10.68.1.3"; PORT="8002"; DOMAIN="isildur.k09.com" ;;
        anarion) IP="10.68.1.4"; PORT="8003"; DOMAIN="anarion.k09.com" ;;
    esac

    cat > /etc/nginx/sites-available/laravel.conf <<EOF
# Blokir akses langsung via IP
server {
    listen ${IP}:${PORT} default_server;
    server_name _;
    return 403;
}

# Hanya izinkan akses via domain
server {
    listen ${IP}:${PORT};
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
}
EOF

    ln -sf /etc/nginx/sites-available/laravel.conf /etc/nginx/sites-enabled/laravel.conf
    nginx -t && systemctl restart nginx && systemctl restart php8.4-fpm

    echo "[SUCCESS] Worker Laravel di $(hostname) siap diakses di http://${DOMAIN}:${PORT}/api/airing"
fi


# --- PENGUJIAN DI PHARAZON (OPSIONAL) ---
if [ "$(hostname)" = "pharazon" ]; then
    echo "[INFO] Testing koneksi Laravel Workers..."

    echo "nameserver 10.68.5.2" > /etc/resolv.conf
    apt update -o Acquire::ForceIPv4=true -y
    apt install -y lynx

    lynx -dump http://10.68.1.2:8001 || echo "[WARN] IP Elendil diblokir"
    lynx -dump http://10.68.1.3:8002 || echo "[WARN] IP Isildur diblokir"
    lynx -dump http://10.68.1.4:8003 || echo "[WARN] IP Anarion diblokir"

    lynx -dump http://elendil.k09.com:8001/api/airing
    lynx -dump http://isildur.k09.com:8002/api/airing
    lynx -dump http://anarion.k09.com:8003/api/airing
fi
