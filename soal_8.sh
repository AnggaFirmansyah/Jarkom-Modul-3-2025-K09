# Persiapan Palantir & Narvi
# Pastikan DNS ke Minastir
echo "nameserver 10.68.5.2" > /etc/resolv.conf

# Update package list
apt update -y

# Install MariaDB di kedua node
apt install -y mariadb-server


# Konfigurasi Palantir (Master)
# Edit file konfigurasi MariaDB
nano /etc/mysql/mariadb.conf.d/50-server.cnf

# Ubah / tambahkan baris berikut:
bind-address            = 0.0.0.0
server-id               = 1
log_bin                 = /var/log/mysql/mysql-bin.log
binlog_do_db            = laravel

# Kemudian restart:
service mariadb restart

# Masuk ke MariaDB shell:
mysql -u root -p

# Jalankan perintah berikut:
CREATE DATABASE laravel;
CREATE USER 'replica'@'10.68.4.4' IDENTIFIED BY 'replpass';
GRANT REPLICATION SLAVE ON *.* TO 'replica'@'10.68.4.4';
FLUSH PRIVILEGES;
FLUSH TABLES WITH READ LOCK;
SHOW MASTER STATUS;

# Catat hasil dari File dan Position — akan digunakan di Narvi.
Contoh output:
File: mysql-bin.000001
Position: 567


# Konfigurasi Narvi (Slave)
nano /etc/mysql/mariadb.conf.d/50-server.cnf

# Tambahkan/ubah:
bind-address            = 0.0.0.0
server-id               = 2
relay-log               = /var/log/mysql/mysql-relay-bin.log
log_bin                 = /var/log/mysql/mysql-bin.log
binlog_do_db            = laravel

# Restart service:
service mariadb restart

# Masuk ke MariaDB shell:
mysql -u root -p

# Jalankan perintah (ganti File dan Position sesuai hasil Palantir):
CHANGE MASTER TO
MASTER_HOST='10.68.4.3',
MASTER_USER='replica',
MASTER_PASSWORD='replpass',
MASTER_LOG_FILE='mysql-bin.000001',
MASTER_LOG_POS=567;
START SLAVE;
SHOW SLAVE STATUS\G

# Cek status:
# Jika Slave_IO_Running: Yes dan Slave_SQL_Running: Yes berarti replikasi berhasil.



# Koneksi Laravel ke Database
Di masing-masing worker (Elendil, Isildur, Anarion):
Edit file .env di folder Laravel:
nano /var/www/resource-laravel/.env

# Ubah bagian database menjadi:
DB_CONNECTION=mysql
DB_HOST=10.68.4.3
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=root
DB_PASSWORD=

# Simpan lalu uji koneksi:
cd /var/www/resource-laravel
php artisan migrate


