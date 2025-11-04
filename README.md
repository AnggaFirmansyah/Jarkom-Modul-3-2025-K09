Markdown

# Laporan Praktikum Jaringan Komputer

## Praktikum Komunikasi data & Jaringan Komputer

| Nama | NRP |
| --- | --- |
| Angga Firmansyah | 5027241062 |
| Naruna Vicrantyo Putra Gangga | 5027241105 |

---

## Nomor 1: Topologi

<img width="862" height="638" alt="image" src="https://github.com/user-attachments/assets/722efd5e-7451-487c-8fd6-16ef1e58e5d3" />


## Nomor 2: DHCP Server (Aldarion) & DHCP Relay (Durin)

#### 🧩 Langkah 1 – Konfigurasi di Aldarion (DHCP Server)

1.  **Install DHCP server**
    ```bash
    apt-get update
    apt-get install isc-dhcp-server -y
    ```

2.  **Edit interface yang digunakan server**
    * **File:** `/etc/default/isc-dhcp-server`
    ```ini
    INTERFACESv4="eth0"
    ```

3.  **Edit konfigurasi DHCP**
    * **File:** `/etc/dhcp/dhcpd.conf`
    ```ini
    # Konfigurasi umum
    authoritative;

    # Subnet 1 - Keluarga Manusia (Switch1)
    subnet 10.68.1.0 netmask 255.255.255.0 {
        range 10.68.1.6 10.68.1.34;
        range 10.68.1.68 10.68.1.94;
        option routers 10.68.1.1;
        option broadcast-address 10.68.1.255;
        option domain-name-servers 10.68.3.3;  # DNS Erendis (akan aktif di soal 4)
    }

    # Subnet 2 - Keluarga Peri (Switch2)
    subnet 10.68.2.0 netmask 255.255.255.0 {
        range 10.68.2.35 10.68.2.67;
        range 10.68.2.96 10.68.2.121;
        option routers 10.68.2.1;
        option broadcast-address 10.68.2.255;
        option domain-name-servers 10.68.3.3;
    }

    # Subnet 3 - Fixed address Khamul
    subnet 10.68.3.0 netmask 255.255.255.0 {
        option routers 10.68.3.1;
        option broadcast-address 10.68.3.255;
        option domain-name-servers 10.68.3.3;
    }

    # Subnet 4 (lokasi Aldarion, Palantir, Narvi)
    subnet 10.68.4.0 netmask 255.255.255.0 {
        option routers 10.68.4.1;
        option broadcast-address 10.68.4.255;
        option domain-name-servers 10.68.3.3;
    }

    # Subnet 5 (Minastir)
    subnet 10.68.5.0 netmask 255.255.255.0 {
        option routers 10.68.5.1;
        option broadcast-address 10.68.5.255;
        option domain-name-servers 10.68.3.3;
    }

    # Fixed address untuk Khamul
    host Khamul {
        hardware ethernet <MAC_ADDRESS_KHAMUL>;
        fixed-address 10.68.3.95;
    }
    ```

4.  **Restart DHCP server**
    ```bash
    service isc-dhcp-server restart
    service isc-dhcp-server status
    ```

#### 🧩 Langkah 2 – Konfigurasi di Durin (DHCP Relay)

1.  **Install DHCP relay**
    ```bash
    apt-get install isc-dhcp-relay -y
    ```

2.  **Konfigurasi file relay**
    * **File:** `/etc/default/isc-dhcp-relay`
    ```ini
    SERVERS="10.68.4.2"
    INTERFACES="eth1 eth2 eth3 eth4 eth5"
    OPTIONS=""
    ```

3.  **Restart relay service**
    ```bash
    service isc-dhcp-relay restart
    service isc-dhcp-relay status
    ```

#### 🧩 Langkah 4 – Tes di Client DHCP

Lakukan di **Amandil** dan **Gilgalad**:

```bash
# restart network
service networking restart
# cek apakah sudah dapat IP
ip a | grep inet
# ping gateway
ping -c 3 10.68.1.1  # Amandil
ping -c 3 10.68.2.1  # Gilgalad
# test internet
ping -c 3 8.8.8.8
Nomor 3: Internet Gateway (NAT) & DNS Forwarder
Bagian A: Konfigurasi Internet Gateway (NAT)
Node yang Dikerjakan: Durin
```
Aktifkan IP Forwarding

Edit file /etc/sysctl.conf dan hapus tanda # pada baris net.ipv4.ip_forward=1.

Ini, TOML
```
# Ubah baris ini:
#net.ipv4.ip_forward=1
# menjadi:
net.ipv4.ip_forward=1
Terapkan perubahan:
```


sysctl -p
Atur Aturan NAT (Masquerade)

Bash

# Di node Durin
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
Bagian B: Konfigurasi Minastir sebagai DNS Forwarder
Node yang Dikerjakan: Minastir

Atur IP Statis

Minastir terhubung ke eth5 Durin (Gateway 10.68.5.1).

Kita akan beri IP statis 10.68.5.2.

Instal BIND9

Bash

# Di node Minastir
apt-get update
apt-get install bind9 -y
Konfigurasi BIND9 (Forwarder-Only)

Edit file /etc/bind/named.conf.options agar Minastir hanya meneruskan permintaan DNS.

options {
    directory "/var/cache/bind";

    // Izinkan query dari jaringan internal
    allow-query {
        localhost;
        10.68.1.0/24;
        10.68.2.0/24;
        10.68.3.0/24;
        10.68.4.0/24;
        10.68.5.0/24;
    };

    // DNS internet (dari NAT1 GNS3)
    forwarders {
        192.168.122.1;
    };

    // Memaksa Minastir untuk HANYA meneruskan
    forward only;

    dnssec-validation auto;
    listen-on-v6 { any; };
};
Restart BIND9

Bash

# Di node Minastir
service bind9 restart
service bind9 status
Nomor 4 & 5: DNS Master (Erendis) & Slave (Amdir)
Langkah 1: Konfigurasi DNS Master (Erendis)
Node yang Dikerjakan: Erendis (IP: 10.68.3.3)

Instal BIND9

Bash

# Di node Erendis
# Pastikan resolver sementara di-set agar bisa apt-get
echo "nameserver 192.168.122.1" > /etc/resolv.conf

apt-get update
apt-get install bind9 -y
Konfigurasi Forwarding (Integrasi Soal 3)

Atur Erendis agar melempar permintaan DNS eksternal ke Minastir.

File: /etc/bind/named.conf.options

options {
    directory "/var/cache/bind";
    allow-query { any; }; // Izinkan query dari semua subnet internal

    forwarders {
        10.68.5.2; // IP Minastir (DNS Forwarder dari Soal 3)
    };

    dnssec-validation auto;
    listen-on-v6 { any; };
};
Definisikan Master Zones (Forward & Reverse)

File: /etc/bind/named.conf.local

// Zona Forward untuk k09.com (Soal 4)
zone "k09.com" {
    type master;
    file "/etc/bind/db.k09.com";
    allow-transfer { 10.68.3.4; }; // Izinkan transfer ke Amdir (Slave)
};

// Zona Reverse untuk subnet 10.68.3.0/24 (Soal 5)
zone "3.68.10.in-addr.arpa" {
    type master;
    file "/etc/bind/db.10.68.3";
    allow-transfer { 10.68.3.4; }; // Izinkan transfer ke Amdir
};
Buat File Zona Forward (db.k09.com)

File: /etc/bind/db.k09.com

$TTL    604800
@       IN      SOA     k09.com. root.k09.com. (
                        2         ; Serial
                        604800    ; Refresh
                        86400     ; Retry
                        2419200   ; Expire
                        604800 )  ; Negative Cache TTL
;
; Name Servers (Soal 4)
@       IN      NS      ns1.k09.com.
@       IN      NS      ns2.k09.com.
ns1     IN      A       10.68.3.3       ; IP Erendis
ns2     IN      A       10.68.3.4       ; IP Amdir

; CNAME Record (Soal 5)
www     IN      CNAME   k09.com.

; A Records (Soal 4)
@         IN      A       10.68.4.3       ; k09.com menunjuk ke Palantir
palantir  IN      A       10.68.4.3
elros     IN      A       10.68.1.7
pharazon  IN      A       10.68.2.4
elendil   IN      A       10.68.1.2
isildur   IN      A       10.68.1.3
anarion   IN      A       10.68.1.4
galadriel IN      A       10.68.2.5
celeborn  IN      A       10.68.2.6
oropher   IN      A       10.68.2.7

; TXT Records (Soal 5)
elros     IN      TXT     "Cincin Sauron"
pharazon  IN      TXT     "Aliansi Terakhir"
Buat File Zona Reverse (db.10.68.3)

File: /etc/bind/db.10.68.3

$TTL    604800
@       IN      SOA     k09.com. root.k09.com. (
                        1         ; Serial
                        604800    ; Refresh
                        86400     ; Retry
                        2419200   ; Expire
                        604800 )  ; Negative Cache TTL
;
@       IN      NS      ns1.k09.com.
@       IN      NS      ns2.k09.com.

; PTR Records (Soal 5) - "3" dan "4" adalah oktet terakhir
3       IN      PTR     ns1.k09.com.    ; 10.68.3.3
4       IN      PTR     ns2.k09.com.    ; 10.68.3.4
Restart BIND9

Bash

# Di node Erendis
service bind9 restart
service bind9 status
Langkah 2: Konfigurasi DNS Slave (Amdir)
Node yang Dikerjakan: Amdir (IP: 10.68.3.4)

Instal BIND9

Bash

# Di node Amdir
echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt-get update
apt-get install bind9 -y
Definisikan Slave Zones

File: /etc/bind/named.conf.local

// Zona Forward (Slave)
zone "k09.com" {
    type slave;
    file "db.k09.com"; // Nama file untuk menyimpan cache
    masters { 10.68.3.3; }; // IP Erendis (Master)
};

// Zona Reverse (Slave)
zone "3.68.10.in-addr.arpa" {
    type slave;
    file "db.10.68.3";
    masters { 10.68.3.3; }; // IP Erendis (Master)
};
Restart BIND9

Bash

# Di node Amdir
service bind9 restart
service bind9 status
Langkah 3: Update DHCP Server (Aldarion)
Node yang Dikerjakan: Aldarion

Edit /etc/dhcp/dhcpd.conf untuk menambahkan Amdir sebagai nameserver kedua.

Ganti baris: option domain-name-servers 10.68.3.3;

Menjadi baris: option domain-name-servers 10.68.3.3, 10.68.3.4;

Restart DHCP Server:

Bash

service isc-dhcp-server restart
4. Verifikasi dan Pengecekan
Persiapan Client (Contoh: Amandil)

Bash

# Dapatkan DNS baru dari DHCP
service networking restart

# Cek /etc/resolv.conf
cat /etc/resolv.conf
# HASIL: Pastikan menunjukkan 'nameserver 10.68.3.3' dan 'nameserver 10.68.3.4'

# Install alat tes DNS
apt-get update
apt-get install dnsutils -y
Tes Fungsional DNS

Bash

# Tes A Record (Soal 4): Cek IP Elendil
host elendil.k09.com
# HASIL YANG DIHARAPKAN: elendil.k09.com has address 10.68.1.2

# Tes CNAME (Soal 5): Cek alias www
host [www.k09.com](https://www.k09.com)
# HASIL YANG DIHARAPKAN: [www.k09.com](https://www.k09.com) is an alias for k09.com.

# Tes PTR (Soal 5): Cek IP Erendis
host 10.68.3.3
# HASIL YANG DIHARAPKAN: 3.3.68.10.in-addr.arpa domain name pointer ns1.k09.com.

# Tes TXT (Soal 5): Cek pesan rahasia Elros
host -t TXT elros.k09.com
# HASIL YANG DIHARAPKAN: elros.k09.com descriptive text "Cincin Sauron"

# Tes Forwarding ke Minastir -> Internet
ping -c 3 google.com
Nomor 6: Konfigurasi DHCP Lease Time
Langkah 1: Modifikasi Konfigurasi DHCP
Node yang Dikerjakan: Aldarion

File: /etc/dhcp/dhcpd.conf

Ini, TOML

# File: /etc/dhcp/dhcpd.conf
# Konfigurasi umum
authoritative;

# TAMBAHKAN INI (Soal 6 - Batas Maksimal 1 jam)
max-lease-time 3600;

# Subnet 1 - Keluarga Manusia (Switch1)
subnet 10.68.1.0 netmask 255.255.255.0 {
    range 10.68.1.6 10.68.1.34;
    range 10.68.1.68 10.68.1.94;
    option routers 10.68.1.1;
    option broadcast-address 10.68.1.255;
    option domain-name-servers 10.68.3.3, 10.68.3.4; # Sesuai Soal 4

    # TAMBAHKAN INI (Soal 6 - Setengah jam)
    default-lease-time 1800;
}

# Subnet 2 - Keluarga Peri (Switch2)
subnet 10.68.2.0 netmask 255.255.255.0 {
    range 10.68.2.35 10.68.2.67;
    range 10.68.2.96 10.68.2.121;
    option routers 10.68.2.1;
    option broadcast-address 10.68.2.255;
    option domain-name-servers 10.68.3.3, 10.68.3.4; # Sesuai Soal 4

    # TAMBAHKAN INI (Soal 6 - Seperenam jam / 10 menit)
    default-lease-time 600;
}
# ... (sisa konfigurasi subnet 3, 4, 5, dan host Khamul) ...
Langkah 2: Restart Layanan DHCP
Bash

# Di node Aldarion
service isc-dhcp-server restart
service isc-dhcp-server status
4. Verifikasi dan Pengecekan
Verifikasi di Keluarga Manusia (Amandil)

Bash

# Paksa minta ulang IP
service networking restart
# Cek file lease di client
grep "lease-time" /var/lib/dhcp/dhclient.leases
# Hasil yang Diharapkan: default-lease-time 1800;
Verifikasi di Keluarga Peri (Gilgalad)

Bash

# Paksa minta ulang IP
service networking restart
# Cek file lease di client
grep "lease-time" /var/lib/dhcp/dhclient.leases
# Hasil yang Diharapkan: default-lease-time 600;
Nomor 7: Setup Web Worker (Laravel)
(Setup Proxy di Minastir - Diperlukan untuk Soal 7)
Node: Minastir

Install Squid

Bash

apt update -o Acquire::ForceIPv4=true
apt install -y squid
Konfigurasi Squid

File: /etc/squid/squid.conf

Tambahkan sebelum http_access deny all:

Ini, TOML

acl mynetwork src 10.68.0.0/16
http_access allow mynetwork
Restart Squid

Bash

service squid restart
netstat -tlnp | grep 3128
Persiapan di Elendil, Isildur, dan Anarion
Atur DNS & Proxy agar bisa konek internet

Bash

printf "nameserver 10.68.5.2\noptions timeout:2 attempts:2\n" > /etc/resolv.conf
export http_proxy=[http://10.68.5.2:3128](http://10.68.5.2:3128)
export https_proxy=[http://10.68.5.2:3128](http://10.68.5.2:3128)
export COMPOSER_ALLOW_SUPERUSER=1
Instalasi dependensi dasar (PHP 8.4 & Nginx)

Bash

apt update -o Acquire::ForceIPv4=true -y
apt install -y curl git unzip ca-certificates lsb-release gnupg apt-transport-https

# Tambahkan repo PHP 8.4 (sury.org)
curl -fsSL [https://packages.sury.org/php/apt.gpg](https://packages.sury.org/php/apt.gpg) | tee /etc/apt/trusted.gpg.d/sury.gpg >/dev/null
echo "deb [https://packages.sury.org/php](https://packages.sury.org/php) $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/sury.list
apt update -o Acquire::ForceIPv4=true -y

# Instal PHP dan nginx
apt install -y \
    php8.4-fpm php8.4-cli php8.4-common php8.4-curl php8.4-mbstring php8.4-xml \
    php8.4-zip php8.4-gd php8.4-intl php8.4-bcmath php8.4-mysql php8.4-sqlite3 \
    nginx
Instal composer

Bash

curl -o composer-setup.php [https://getcomposer.org/installer](https://getcomposer.org/installer)
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm -f composer-setup.php
Clone proyek Laravel

Bash

mkdir -p /var/www
cd /var/www
rm -rf resource-laravel
git clone [https://github.com/elshiraphine/laravel-simple-rest-api](https://github.com/elshiraphine/laravel-simple-rest-api) resource-laravel
cd resource-laravel
composer update --no-dev
cp .env.example .env
php artisan key:generate
Atur izin folder

Bash

chown -R www-data:www-data /var/www/resource-laravel
chmod -R 775 /var/www/resource-laravel/storage
chmod -R 775 /var/www/resource-laravel/bootstrap/cache
Konfigurasi Nginx (Dijalankan di setiap worker)

Untuk ELENDIL:

Bash

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
Untuk ISILDUR:

Bash

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
Untuk ANARION:

Bash

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
Verifikasi di Klien (Pharazon)

Bash

printf "nameserver 10.68.5.2\noptions timeout:2 attempts:2\n" >/etc/resolv.conf
apt update -o Acquire::ForceIPv4=true -y
apt install -y lynx

lynx -dump [http://elendil.k09.com](http://elendil.k09.com)
lynx -dump [http://isildur.k09.com](http://isildur.k09.com)
lynx -dump [http://anarion.k09.com](http://anarion.k09.com)
Nomor 8: Konfigurasi Database (Palantir)
Setup di Palantir

Bash

# Atur DNS dan Proxy
printf "nameserver 10.68.5.2\noptions timeout:2 attempts:2\n" > /etc/resolv.conf
cat > /etc/apt/apt.conf.d/00proxy <<'EOF'
Acquire::http::Proxy  "[http://10.68.5.2:3128](http://10.68.5.2:3128)";
Acquire::https::Proxy "[http://10.68.5.2:3128](http://10.68.5.2:3128)";
EOF

# Install MariaDB
apt update -o Acquire::ForceIPv4=true -y
apt install -y mariadb-server
Konfigurasi MariaDB agar bisa diakses dari luar

Bash

# Ubah bind address agar listen di IP-nya (10.68.4.3)
sed -i 's/^\(bind-address\s*=\s*\).*/\10.68.4.3/' /etc/mysql/mariadb.conf.d/50-server.cnf
service mariadb restart
Setup database dan user

SQL

mariadb -u root <<'EOF'
CREATE DATABASE IF NOT EXISTS laravel_db;
DROP USER IF EXISTS 'laravel_user'@'%';
CREATE USER 'zeinkeren'@'%' IDENTIFIED BY 'nandakocak';
GRANT ALL PRIVILEGES ON laravel_db.* TO 'zeinkeren'@'%';
FLUSH PRIVILEGES;
EOF
Konfigurasi di Elendil, Isildur, dan Anarion

(Catatan: File migrasi dan seeder di-patch sesuai konfigurasi file Anda)

Bash

# Di Elendil, Isildur, Anarion
cd /var/www/resource-laravel

# Patch migration
cat > database/migrations/2023_02_08_103126_create_airings_table.php <<'EOF'
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

# Seeder dan konfigurasi
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
use App\Models\Airing;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\File;
class AiringSeeder extends Seeder {
public function run() {
$json = File::get(database_path('seeders/airing.json'));
$data = json_decode($json, true);
Airing::truncate();
if (isset($data['data'])) {
foreach ($data['data'] as $item) {
Airing::create([
'title' => $item['title'],
'status' => $item['status'],
'start_date' => $item['start_date'],
]);
}
}
}
}
EOF

# Update DatabaseSeeder.php
cat > database/seeders/DatabaseSeeder.php <<'EOF'
<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
class DatabaseSeeder extends Seeder {
public function run() {
$this->call([AiringSeeder::class]);
}
}
EOF

# Konfigurasi .env
sed -i "s/DB_HOST=127.0.0.1/DB_HOST=10.68.4.3/" .env
sed -i "s/DB_DATABASE=laravel/DB_DATABASE=laravel_db/" .env
sed -i "s/^DB_USERNAME=.*/DB_USERNAME=zeinkeren/" .env
sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=nandakocak/" .env
Migrasi dan Seeding (Hanya di Elendil)

Bash

php artisan migrate:fresh --seed
Nomor 9: Pengujian API Laravel
Node yang Dikerjakan: Pharazon

Bash

# Setup DNS dan Proxy
printf "nameserver 10.68.5.2\n" > /etc/resolv.conf
cat >/etc/apt/apt.conf.d/00proxy <<'EOF'
Acquire::http::Proxy  "[http://10.68.5.2:3128](http://10.68.5.2:3128)";
Acquire::https::Proxy "[http://10.68.5.2:3128](http://10.68.5.2:3128)";
EOF

apt update -o Acquire::ForceIPv4=true -y
apt install -y lynx curl

# Uji koneksi Laravel API
lynx -dump [http://elendil.k09.com/api/airing](http://elendil.k09.com/api/airing)
curl [http://elendil.k09.com/api/airing](http://elendil.k09.com/api/airing)

lynx -dump [http://isildur.k09.com/api/airing](http://isildur.k09.com/api/airing)
curl [http://isildur.k09.com/api/airing](http://isildur.k09.com/api/airing)

lynx -dump [http://anarion.k09.com/api/airing](http://anarion.k09.com/api/airing)
curl [http://anarion.k09.com/api/airing](http://anarion.k09.com/api/airing)
