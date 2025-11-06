# Langkah Konfigurasi dan Uji
#  Di node Pharazon

# Pastikan DNS diarahkan ke Minastir (agar bisa resolve domain *.K09.com)
printf "nameserver 10.68.5.2\n" > /etc/resolv.conf

# Tambahkan proxy agar bisa apt-get lewat Minastir (sebagai internet gateway)
cat > /etc/apt/apt.conf.d/00proxy <<'EOF'
Acquire::http::Proxy  "http://10.68.5.2:3128";
Acquire::https::Proxy "http://10.68.5.2:3128";
EOF

# Update dan install tools untuk testing
apt update -o Acquire::ForceIPv4=true -y
apt install -y lynx curl

# Uji koneksi API Laravel dari setiap worker

# Elendil
echo "=== Testing Elendil ==="
lynx -dump http://elendil.K09.com:8001/api/airing
curl http://elendil.K09.com:8001/api/airing
echo

# Isildur
echo "=== Testing Isildur ==="
lynx -dump http://isildur.K09.com:8002/api/airing
curl http://isildur.K09.com:8002/api/airing
echo

# Anarion
echo "=== Testing Anarion ==="
lynx -dump http://anarion.K09.com:8003/api/airing
curl http://anarion.K09.com:8003/api/airing
echo
