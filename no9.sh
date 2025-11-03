# Di Pharazon
printf "nameserver 10.68.5.2\n" > /etc/resolv.conf
cat >/etc/apt/apt.conf.d/00proxy <<'EOF'
Acquire::http::Proxy  "http://10.68.5.2:3128";
Acquire::https::Proxy "http://10.68.5.2:3128";
EOF

apt update -o Acquire::ForceIPv4=true -y
apt install -y lynx curl

# Uji koneksi Laravel API
lynx -dump http://elendil.k09.com/api/airing
curl http://elendil.k09.com/api/airing

lynx -dump http://isildur.k09.com/api/airing
curl http://isildur.k09.com/api/airing

lynx -dump http://anarion.k09.com/api/airing
curl http://anarion.k09.com/api/airing



