from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename
import easyocr
import os
import json
import cv2
import numpy as np
from PIL import Image
import io

app = Flask(__name__)

# İzin verilen dosya uzantıları
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'}

# GPU kontrolü
def check_gpu():
    try:
        import torch
        return torch.cuda.is_available()
    except:
        return False

# EasyOCR reader'ı global olarak oluştur (bir kez yüklenir)
print("EasyOCR modeli yükleniyor...")
use_gpu = check_gpu()
print(f"GPU kullanımı: {'Evet' if use_gpu else 'Hayır'}")
reader = easyocr.Reader(['tr', 'en'], gpu=use_gpu, verbose=False)
print("Model yüklendi!")

def preprocess_image(image_bytes, max_width=1920):
    """Görüntüyü optimize et - küçült ve gri tonlamaya çevir"""
    try:
        # Bytes'tan görüntüyü oku
        image = Image.open(io.BytesIO(image_bytes))
        
        # Gri tonlamaya çevir (daha hızlı işleme için)
        if image.mode != 'L':
            image = image.convert('L')
        
        # Genişlik kontrolü - çok büyükse küçült
        if image.width > max_width:
            ratio = max_width / image.width
            new_height = int(image.height * ratio)
            # Pillow versiyon uyumluluğu için
            try:
                resample = Image.Resampling.LANCZOS
            except AttributeError:
                resample = Image.LANCZOS
            image = image.resize((max_width, new_height), resample)
        
        # NumPy array'e çevir
        img_array = np.array(image)
        
        # Kontrast artırma (OCR kalitesini artırabilir)
        img_array = cv2.convertScaleAbs(img_array, alpha=1.2, beta=10)
        
        return img_array
    except Exception as e:
        print(f"Görüntü ön işleme hatası: {e}")
        return None

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/ocr', methods=['POST'])
def ocr_endpoint():
    try:
        # Resim dosyası kontrolü
        if 'image' not in request.files:
            return jsonify({'error': 'Resim dosyası bulunamadı. "image" adında bir dosya gönderin.'}), 400
        
        file = request.files['image']
        
        if file.filename == '':
            return jsonify({'error': 'Dosya seçilmedi.'}), 400
        
        if not allowed_file(file.filename):
            return jsonify({'error': f'Geçersiz dosya formatı. İzin verilen formatlar: {", ".join(ALLOWED_EXTENSIONS)}'}), 400
        
        # Dosyayı memory'de oku
        file_bytes = file.read()
        filename = secure_filename(file.filename)
        
        # Görüntüyü ön işle
        processed_image = preprocess_image(file_bytes)
        if processed_image is None:
            return jsonify({'error': 'Görüntü işlenemedi.'}), 400
        
        # OCR işlemi - optimize edilmiş parametrelerle
        print(f"Resimden text okunuyor: {filename}")
        results = reader.readtext(
            processed_image,
            paragraph=False,  # Paragraf algılama kapalı (daha hızlı)
            width_ths=0.7,    # Genişlik eşiği
            height_ths=0.7,   # Yükseklik eşiği
            detail=1          # Confidence bilgisi için detail=1 gerekli
        )
        
        # Sonuçları birleştir
        all_text = []
        
        for (bbox, text, confidence) in results:
            all_text.append(text)
        
        # Metni birleştir ve JSON body olarak döndür
        combined_text = ' '.join(all_text)
        
        return jsonify({'text': combined_text})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'ok', 'message': 'OCR servisi çalışıyor'})

if __name__ == '__main__':
    # Production için threaded=True kullan (daha hızlı)
    app.run(debug=False, host='0.0.0.0', port=5000, threaded=True)

