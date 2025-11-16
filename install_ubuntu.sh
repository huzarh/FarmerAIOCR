#!/bin/bash

# Ubuntu Server için OCR servisi kurulum scripti
# Kullanım: sudo bash install_ubuntu.sh

set -e

echo "=========================================="
echo "FarmerAI OCR Servisi Kurulumu Başlıyor..."
echo "=========================================="

# Sistem güncellemesi
echo "[1/6] Sistem paketleri güncelleniyor..."
apt-get update

# Sistem bağımlılıkları
echo "[2/6] Sistem bağımlılıkları kuruluyor..."
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgthread-2.0-0 \
    wget \
    curl

# Python virtual environment oluştur
echo "[3/6] Python virtual environment oluşturuluyor..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Virtual environment'ı aktif et
echo "[4/6] Virtual environment aktif ediliyor..."
source venv/bin/activate

# Python paketlerini yükle
echo "[5/6] Python paketleri kuruluyor..."
pip install --upgrade pip
pip install -r requirements_ubuntu.txt

# Systemd service dosyasını kopyala
echo "[6/6] Systemd service dosyası oluşturuluyor..."
CURRENT_DIR=$(pwd)
USER_NAME=${SUDO_USER:-$USER}

# Service dosyasını oluştur
cat > /etc/systemd/system/farmerai-ocr.service << EOF
[Unit]
Description=FarmerAI OCR Service
After=network.target

[Service]
Type=simple
User=$USER_NAME
WorkingDirectory=$CURRENT_DIR
Environment="PATH=$CURRENT_DIR/venv/bin"
ExecStart=$CURRENT_DIR/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 2 --threads 4 --timeout 120 --access-logfile - --error-logfile - ocr_easyocr_for_ubuntu:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Systemd'yi yeniden yükle
systemctl daemon-reload

echo "=========================================="
echo "Kurulum tamamlandı!"
echo "=========================================="
echo ""
echo "Servisi başlatmak için:"
echo "  sudo systemctl start farmerai-ocr"
echo ""
echo "Servisi otomatik başlatmak için:"
echo "  sudo systemctl enable farmerai-ocr"
echo ""
echo "Servis durumunu kontrol etmek için:"
echo "  sudo systemctl status farmerai-ocr"
echo ""
echo "Logları görmek için:"
echo "  sudo journalctl -u farmerai-ocr -f"
echo ""

