import requests

with open('kupenumara.png', 'rb') as f:
    response = requests.post('http://localhost:5000/ocr', files={'image': f})
    print(response.json())