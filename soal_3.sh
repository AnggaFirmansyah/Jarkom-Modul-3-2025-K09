#  Konfigurasi Internet Gateway (NAT)

# Node yang Dikerjakan: Durin
# Aktifkan IP Forwarding
Edit file /etc/sysctl.conf dan hapus tanda # pada baris net.ipv4.ip_forward=1.

# Di node Durin
nano /etc/sysctl.conf

# Cari dan ubah baris ini:
#net.ipv4.ip_forward=1
# menjadi:
net.ipv4.ip_forward=1

# Terapkan perubahan:
sysctl -p

# Atur Aturan NAT (Masquerade)

# Di node Durin
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Konfigurasi Minastir sebagai DNS Forwarder

# Node yang Dikerjakan: Minastir
# Atur IP Statis
Minastir terhubung ke eth5 Durin (Gateway 10.68.5.1). Kita akan beri IP statis 10.68.5.2.

# Instal BIND9
# Di node Minastir
apt-get update
apt-get install bind9 -y

# Konfigurasi BIND9 (Forwarder-Only)
#Edit file named.conf.options agar Minastir hanya meneruskan semua permintaan DNS yang diterimanya.

# Di node Minastir
nano /etc/bind/named.conf.options

#Ubah isinya menjadi seperti ini:
options {
    directory "/var/cache/bind";

    // Izinkan query dari Erendis (dan jaringan internal lainnya)
    allow-query { 
        localhost;
        10.68.1.0/24;
        10.68.2.0/24;
        10.68.3.0/24;
        10.68.4.0/24;
        10.68.5.0/24;
    };

    // Ini adalah DNS internet (dari NAT1 GNS3)
    forwarders {
        192.168.122.1;
    };

    // Baris ini krusial:
    // Memaksa Minastir untuk HANYA meneruskan, tidak mencari sendiri.
    forward only; 

    dnssec-validation auto;
    listen-on-v6 { any; };
};

# Restart BIND9
# Di node Minastir
service bind9 restart
service bind9 status
