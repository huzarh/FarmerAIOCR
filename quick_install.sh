#!/bin/bash

# Hızlı kurulum scripti - Python 3.14 için optimize edilmiş
# Kullanım: sudo bash quick_install.sh

echo "=========================================="
echo "Hızlı Kurulum Başlıyor..."
echo "=========================================="

# Pillow için gerekli sistem paketleri
echo "[1/4] Sistem paketleri kuruluyor..."
apt-get update
apt-get install -y \
    python3-dev \
    python3-pip \
    python3-venv \
    libjpeg-dev \
    zlib1g-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libopenjp2-7-dev \
    libtiff5-dev \
    libgl1 \
    libglib2.0-0t64 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    wget \
    curl

# Virtual environment oluştur
echo "[2/4] Virtual environment oluşturuluyor..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Virtual environment'ı aktif et
echo "[3/4] Python paketleri kuruluyor..."
source venv/bin/activate
pip install --upgrade pip setuptools wheel

# Pillow'u önce kur (Python 3.14 için güncel versiyon)
pip install pillow>=10.0.0

# Diğer paketleri kur
pip install -r requirements_ubuntu.txt

# Service dosyasını oluştur
echo "[4/4] Service dosyası oluşturuluyor..."
CURRENT_DIR=$(pwd)
USER_NAME=$(getent passwd | awk -F: '$3 >= 1000 && $1 != "nobody" {print $1; exit}')
if [ -z "$USER_NAME" ]; then
    USER_NAME="root"
fi

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

