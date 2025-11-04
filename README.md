# Laporan Praktikum Jaringan Komputer - Modul 3 2025 K09

## Praktikum Komunikasi Data & Jaringan Komputer

| Nama | NRP |
| --- | --- |
| Angga Firmansyah | 5027241062 |
| Naruna Vicrantyo Putra Gangga | 5027241105 |

---

## Nomor 1: Persiapan Node & Topologi

```bash
# Pastikan semua node sudah hidup di GNS3
# Cek konektivitas antar node dengan ping dasar
ping -c 3 <IP_NODE>
```

## Nomor 2: DHCP Server (Aldarion) & DHCP Relay (Durin)

### Langkah 1 – Konfigurasi di Aldarion (DHCP Server)
```bash
apt-get update
apt-get install isc-dhcp-server -y
# Edit interface yang digunakan
nano /etc/default/isc-dhcp-server
# INTERFACESv4="eth0"

# Edit konfigurasi DHCP
nano /etc/dhcp/dhcpd.conf
# Tambahkan konfigurasi subnet seperti soal

# Restart DHCP server
service isc-dhcp-server restart
service isc-dhcp-server status
```

### Langkah 2 – Konfigurasi di Durin (DHCP Relay)
```bash
apt-get install isc-dhcp-relay -y
nano /etc/default/isc-dhcp-relay
# SERVERS="10.68.4.2" INTERFACES="eth1 eth2 eth3 eth4 eth5" OPTIONS=""
service isc-dhcp-relay restart
service isc-dhcp-relay status
```

### Langkah 4 – Tes di Client DHCP
```bash
# Amandil dan Gilgalad
networking restart
ip a | grep inet
ping -c 3 10.68.1.1 # Amandil
ping -c 3 10.68.2.1 # Gilgalad
ping -c 3 8.8.8.8 # Test Internet
```

## Nomor 3: Internet Gateway (NAT) & DNS Forwarder

### Bagian A: Konfigurasi Internet Gateway (NAT) - Durin
```bash
# Aktifkan IP forwarding
nano /etc/sysctl.conf
# ubah baris: net.ipv4.ip_forward=1
sysctl -p

# Atur aturan NAT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

### Bagian B: Konfigurasi DNS Forwarder - Minastir
```bash
# Set IP statis 10.68.5.2
apt-get update
apt-get install bind9 -y
nano /etc/bind/named.conf.options
# Konfigurasi forwarders ke NAT dan allow-query untuk subnet internal
service bind9 restart
service bind9 status
```

## Nomor 4 & 5: DNS Master (Erendis) & Slave (Amdir)

### DNS Master - Erendis
```bash
# Instal BIND9 dan set resolv.conf sementara
apt-get update
apt-get install bind9 -y
nano /etc/bind/named.conf.options
# Tambahkan forwarders ke Minastir
nano /etc/bind/named.conf.local
# Tambahkan zona master forward & reverse
nano /etc/bind/db.k09.com
nano /etc/bind/db.10.68.3
service bind9 restart
service bind9 status
```

### DNS Slave - Amdir
```bash
# Instal BIND9
apt-get update
apt-get install bind9 -y
# Konfigurasi zona slave
nano /etc/bind/named.conf.local
service bind9 restart
service bind9 status
```

### Update DHCP Server - Aldarion
```bash
# Tambahkan nameserver kedua Amdir
nano /etc/dhcp/dhcpd.conf
service isc-dhcp-server restart
```

### Verifikasi DNS di Client
```bash
# Tes A, CNAME, PTR, TXT, dan forwarding ke internet
host elendil.k09.com
host www.k09.com
host 10.68.3.3
host -t TXT elros.k09.com
ping -c 3 google.com
```

## Nomor 6: Konfigurasi DHCP Lease Time
```bash
# Modifikasi /etc/dhcp/dhcpd.conf untuk masing-masing subnet
# Tambahkan default-lease-time dan max-lease-time sesuai soal
service isc-dhcp-server restart
# Verifikasi di client
grep "lease-time" /var/lib/dhcp/dhclient.leases
```

## Nomor 7: Setup Web Worker (Laravel) - Minastir & Clients
```bash
# Instal Squid dan konfigurasi ACL
apt update
apt install -y squid
nano /etc/squid/squid.conf
service squid restart
netstat -tlnp | grep 3128

# Set DNS & Proxy di clients (Elendil, Isildur, Anarion)
printf "nameserver 10.68.5.2\noptions timeout:2 attempts:2\n" > /etc/resolv.conf
export http_proxy=http://10.68.5.2:3128
export https_proxy=http://10.68.5.2:3128
export COMPOSER_ALLOW_SUPERUSER=1

# Instal PHP 8.4, Nginx, Composer
apt install -y php8.4-fpm php8.4-cli nginx curl git unzip
curl -sSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Clone Laravel project & konfigurasi .env
cd /var/www
git clone https://github.com/elshiraphine/laravel-simple-rest-api resource-laravel
cd resource-laravel
composer update --no-dev
cp .env.example .env
php artisan key:generate
chown -R www-data:www-data /var/www/resource-laravel
chmod -R 775 /var/www/resource-laravel/storage
chmod -R 775 /var/www/resource-laravel/bootstrap/cache

# Konfigurasi Nginx untuk masing-masing domain
# ELENDIL, ISILDUR, ANARION
nginx -t && service nginx restart && service php8.4-fpm restart

# Verifikasi akses web dari client Pharazon
lynx -dump http://elendil.k09.com
lynx -dump http://isildur.k09.com
lynx -dump http://anarion.k09.com
```

## Nomor 8: Konfigurasi Database (Palantir)
```bash
# Atur DNS & Proxy
printf "nameserver 10.68.5.2\noptions timeout:2 attempts:2\n" > /etc/resolv.conf
cat > /etc/apt/apt.conf.d/00proxy <<'EOF'
Acquire::http::Proxy "http://10.68.5.2:3128";
Acquire::https::Proxy "http://10.68.5.2:3128";
EOF

# Install MariaDB
apt install -y mariadb-server
# Konfigurasi bind-address ke 10.68.4.3
sed -i 's/^\(bind-address\s*=\s*\).*/\110.68.4.3/' /etc/mysql/mariadb.conf.d/50-server.cnf
service mariadb restart

# Setup database & user
mariadb -u root <<'EOF'
CREATE DATABASE IF NOT EXISTS laravel_db;
DROP USER IF EXISTS 'laravel_user'@'%';
CREATE USER 'zeinkeren'@'%' IDENTIFIED BY 'nandakocak';
GRANT ALL PRIVILEGES ON laravel_db.* TO 'zeinkeren'@'%';
FLUSH PRIVILEGES;
EOF

# Patch migration & seeder di clients
cd /var/www/resource-laravel
# Patch migration & seeder sesuai soal
php artisan migrate:fresh --seed
```

## Nomor 9: Pengujian API Laravel - Pharazon
```bash
# Setup DNS & Proxy
printf "nameserver 10.68.5.2\n" > /etc/resolv.conf
cat >/etc/apt/apt.conf.d/00proxy <<'EOF'
Acquire::http::Proxy "http://10.68.5.2:3128";
Acquire::https::Proxy "http://10.68.5.2:3128";
EOF
apt update -o Acquire::ForceIPv4=true -y
apt install -y lynx curl

# Uji koneksi API Laravel
lynx -dump http://elendil.k09.com/api/airing
curl http://elendil.k09.com/api/airing
lynx -dump http://isildur.k09.com/api/airing
curl http://isildur.k09.com/api/airing
lynx -dump http://anarion.k09.com/api/airing
curl http://anarion.k09.com/api/airing
```
