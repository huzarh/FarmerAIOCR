#!/bin/bash

# Pillow kurulum sorununu çözen script
# Python 3.13+ için optimize edilmiş

echo "Pillow kurulum sorunu çözülüyor..."

# Virtual environment aktif et
source venv/bin/activate

# pip, setuptools ve wheel'i güncelle
echo "Build araçları güncelleniyor..."
pip install --upgrade pip setuptools wheel

# Pillow için gerekli sistem paketleri
echo "Sistem paketleri kontrol ediliyor..."
apt-get install -y python3-dev libjpeg-dev zlib1g-dev libfreetype6-dev liblcms2-dev libopenjp2-7-dev libtiff5-dev 2>/dev/null || true

# Önce önceden derlenmiş wheel'i dene
echo "Pillow kuruluyor (önceden derlenmiş wheel)..."
pip install --only-binary=:all: "pillow>=10.0.0,<11.0.0" || {
    echo "Önceden derlenmiş wheel bulunamadı, kaynak koddan derleniyor..."
    # Eğer wheel yoksa, kaynak koddan derle
    pip install "pillow>=10.0.0,<11.0.0"
}

echo "Pillow kurulumu tamamlandı!"

