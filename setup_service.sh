#!/bin/bash

# Service dosyasını manuel oluşturma scripti
# Kullanım: sudo bash setup_service.sh

CURRENT_DIR=$(pwd)

# Kullanıcı adını bul
if [ "$EUID" -eq 0 ]; then
    if [ -n "$SUDO_USER" ]; then
        USER_NAME=$SUDO_USER
    else
        USER_NAME=$(getent passwd | awk -F: '$3 >= 1000 && $1 != "nobody" {print $1; exit}')
    fi
else
    USER_NAME=$USER
fi

echo "Service kullanıcısı: $USER_NAME"
echo "Çalışma dizini: $CURRENT_DIR"

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

echo "Service dosyası oluşturuldu!"
echo ""
echo "Servisi başlatmak için:"
echo "  sudo systemctl start farmerai-ocr"
echo ""
echo "Servisi otomatik başlatmak için:"
echo "  sudo systemctl enable farmerai-ocr"

