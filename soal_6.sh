apt-get update apt-get install isc-dhcp-client -y

dhclient -r dhclient

# Modifikasi Konfigurasi DHCP
# Node yang Dikerjakan: Aldarion
# Buka file dhcpd.conf:

# Di node Aldarion
nano /etc/dhcp/dhcpd.conf

# Tambahkan Konfigurasi Lease Time: Cari konfigurasi subnet Anda, dan tambahkan baris default-lease-time dan max-lease-time seperti di bawah ini.

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


# Restart Layanan DHCP
# Di node Aldarion
service isc-dhcp-server restart
service isc-dhcp-server status
