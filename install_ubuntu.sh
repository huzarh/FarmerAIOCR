#!/bin/bash

# Ubuntu Server için OCR servisi kurulum scripti
# Kullanım: sudo bash install_ubuntu.sh

echo "=========================================="
echo "FarmerAI OCR Servisi Kurulumu Başlıyor..."
echo "=========================================="

# Sistem güncellemesi
echo "[1/6] Sistem paketleri güncelleniyor..."
apt-get update || { echo "Paket listesi güncellenemedi!"; exit 1; }

# Sistem bağımlılıkları
echo "[2/6] Sistem bağımlılıkları kuruluyor..."
# Temel paketler
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    wget \
    curl

# OpenCV ve görüntü işleme için gerekli paketler (Ubuntu versiyonuna göre)
# Ubuntu 24.04+ için libgl1-mesa-glx yerine libgl1 kullanılır
if apt-cache show libgl1-mesa-glx > /dev/null 2>&1; then
    apt-get install -y libgl1-mesa-glx
else
    echo "libgl1-mesa-glx bulunamadı, alternatif paketler kuruluyor..."
    apt-get install -y libgl1 libglib2.0-0t64 || apt-get install -y libgl1 libglib2.0-0
fi

# Diğer bağımlılıklar
apt-get install -y \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgthread-2.0-0t64 2>/dev/null || apt-get install -y libgthread-2.0-0 || true

# Python virtual environment oluştur
echo "[3/6] Python virtual environment oluşturuluyor..."
if [ ! -d "venv" ]; then
    python3 -m venv venv || { echo "Virtual environment oluşturulamadı!"; exit 1; }
fi

# Virtual environment'ı aktif et
echo "[4/6] Virtual environment aktif ediliyor..."
source venv/bin/activate || { echo "Virtual environment aktif edilemedi!"; exit 1; }

# Python paketlerini yükle
echo "[5/6] Python paketleri kuruluyor..."
pip install --upgrade pip || { echo "pip güncellenemedi!"; exit 1; }
pip install -r requirements_ubuntu.txt || { echo "Python paketleri kurulamadı!"; exit 1; }

# Systemd service dosyasını kopyala
echo "[6/6] Systemd service dosyası oluşturuluyor..."
CURRENT_DIR=$(pwd)
# Root kullanıcı ise, normal kullanıcıyı bul
if [ "$EUID" -eq 0 ]; then
    if [ -n "$SUDO_USER" ]; then
        USER_NAME=$SUDO_USER
    else
        # Eğer SUDO_USER yoksa, home dizininden kullanıcı adını al
        USER_NAME=$(basename $(dirname $HOME))
    fi
else
    USER_NAME=$USER
fi

# Eğer hala root ise, ilk normal kullanıcıyı bul
if [ "$USER_NAME" = "root" ] || [ -z "$USER_NAME" ]; then
    USER_NAME=$(getent passwd | awk -F: '$3 >= 1000 && $1 != "nobody" {print $1; exit}')
fi

echo "Service kullanıcısı: $USER_NAME"

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
systemctl daemon-reload || { echo "Systemd daemon-reload başarısız!"; exit 1; }

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

