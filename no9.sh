#!/bin/bash
# =========================================================
# Soal 9 - Uji API Laravel Worker dari Pharazon
# Node: Pharazon (Load Balancer - PHP)
# =========================================================
set -e

echo "[INFO] Memulai pengujian API Laravel dari Pharazon..."

#  Konfigurasi DNS dan Proxy agar konek ke internet via Minastir
echo "[SETUP] Menetapkan resolver DNS ke Minastir..."
cat > /etc/resolv.conf <<EOF
nameserver 10.68.5.2
options timeout:2 attempts:2
EOF

# Tambahkan proxy untuk APT
cat > /etc/apt/apt.conf.d/00proxy <<EOF
Acquire::http::Proxy "http://10.68.5.2:3128";
Acquire::https::Proxy "http://10.68.5.2:3128";
EOF

#  Instalasi utilitas dasar
echo "[INSTALL] Memasang lynx dan curl..."
apt update -o Acquire::ForceIPv4=true -y
apt install -y lynx curl

#  Definisikan target Laravel Workers
WORKERS=(
  "elendil.k09.com:8001"
  "isildur.k09.com:8002"
  "anarion.k09.com:8003"
)

#  Looping pengecekan API untuk setiap worker
for worker in "${WORKERS[@]}"; do
    echo "-------------------------------------------"
    echo "[TEST] Mengecek koneksi ke http://$worker/api/airing"
    echo "-------------------------------------------"

    echo "[LYNX OUTPUT]"
    lynx -dump "http://$worker/api/airing" || echo "[WARN] Gagal akses via lynx!"

    echo "[CURL OUTPUT]"
    curl -s "http://$worker/api/airing" || echo "[WARN] Gagal akses via curl!"

    echo "==========================================="
    echo ""
done

echo "[SUCCESS] Semua worker Laravel telah diuji dari Pharazon!"
