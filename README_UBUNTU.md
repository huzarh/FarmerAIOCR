# FarmerAI OCR Servisi - Ubuntu Server Kurulumu

Bu dokümantasyon, OCR servisini Ubuntu Server'da sorunsuz çalıştırmak için gerekli adımları içerir.

## Hızlı Kurulum

```bash
# 1. Projeyi klonlayın veya dosyaları sunucuya yükleyin
cd /path/to/FarmerAIOCR

# 2. Kurulum scriptini çalıştırın
sudo bash install_ubuntu.sh

# 3. Servisi başlatın
sudo systemctl start farmerai-ocr

# 4. Servisi otomatik başlatma için etkinleştirin
sudo systemctl enable farmerai-ocr
```

## Manuel Kurulum

### 1. Sistem Bağımlılıklarını Yükleyin

```bash
sudo apt-get update
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgthread-2.0-0
```

### 2. Python Virtual Environment Oluşturun

```bash
python3 -m venv venv
source venv/bin/activate
```

### 3. Python Paketlerini Yükleyin

```bash
pip install --upgrade pip
pip install -r requirements_ubuntu.txt
```

### 4. Gunicorn ile Servisi Başlatın

```bash
# Manuel başlatma (test için)
gunicorn --bind 0.0.0.0:5000 --workers 2 --threads 4 --timeout 120 ocr_easyocr_for_ubuntu:app

# Arka planda çalıştırma
nohup gunicorn --bind 0.0.0.0:5000 --workers 2 --threads 4 --timeout 120 ocr_easyocr_for_ubuntu:app > ocr.log 2>&1 &
```

### 5. Systemd Service Oluşturun

`/etc/systemd/system/farmerai-ocr.service` dosyasını oluşturun:

```ini
[Unit]
Description=FarmerAI OCR Service
After=network.target

[Service]
Type=notify
User=your_username
WorkingDirectory=/path/to/FarmerAIOCR
Environment="PATH=/path/to/FarmerAIOCR/venv/bin"
ExecStart=/path/to/FarmerAIOCR/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 2 --threads 4 --timeout 120 --access-logfile - --error-logfile - ocr_easyocr_for_ubuntu:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Service dosyasını aktif edin:

```bash
sudo systemctl daemon-reload
sudo systemctl enable farmerai-ocr
sudo systemctl start farmerai-ocr
```

## Servis Yönetimi

### Servisi Başlatma
```bash
sudo systemctl start farmerai-ocr
```

### Servisi Durdurma
```bash
sudo systemctl stop farmerai-ocr
```

### Servis Durumunu Kontrol Etme
```bash
sudo systemctl status farmerai-ocr
```

### Logları Görüntüleme
```bash
# Canlı loglar
sudo journalctl -u farmerai-ocr -f

# Son 100 satır
sudo journalctl -u farmerai-ocr -n 100
```

### Servisi Yeniden Başlatma
```bash
sudo systemctl restart farmerai-ocr
```

## Test Etme

### Health Check
```bash
curl http://localhost:5000/health
```

### OCR Test
```bash
curl -X POST -F "image=@test_image.png" http://localhost:5000/ocr
```

## Performans Ayarları

Gunicorn worker sayısını CPU çekirdek sayısına göre ayarlayın:

```bash
# CPU çekirdek sayısını öğrenin
nproc

# Worker sayısı genellikle (2 x CPU çekirdek sayısı) + 1 olmalı
# Örnek: 4 çekirdek için 9 worker
gunicorn --bind 0.0.0.0:5000 --workers 9 --threads 4 --timeout 120 ocr_easyocr_for_ubuntu:app
```

## Sorun Giderme

### Model Yükleme Hatası
EasyOCR modelleri ilk çalıştırmada otomatik indirilir. İnternet bağlantınızı kontrol edin.

### Port Kullanımda Hatası
Port 5000 kullanımda ise, farklı bir port kullanın:
```bash
# Service dosyasında portu değiştirin
ExecStart=... --bind 0.0.0.0:5001 ...
```

### Bellek Sorunları
Worker sayısını azaltın veya timeout değerini artırın.

### OpenCV Headless Hatası
`opencv-python-headless` paketinin yüklü olduğundan emin olun:
```bash
pip install opencv-python-headless
```

## Güvenlik

### Firewall Ayarları
```bash
# UFW ile port açma
sudo ufw allow 5000/tcp
```

### Nginx Reverse Proxy (Önerilen)
Nginx ile reverse proxy kullanarak servisi güvenli hale getirin.

## Notlar

- İlk çalıştırmada EasyOCR modelleri indirileceği için biraz zaman alabilir
- GPU varsa otomatik olarak kullanılacaktır
- Servis otomatik olarak yeniden başlatılır (crash durumunda)

