# TrackForge — Geliştirici Cheatsheet

---

## 1. Projeyi Başlatma
```bash
# Önce Docker'ı başlat (PostgreSQL + pgAdmin)
docker-compose up -d

# Sonra uvicorn'u başlat
uvicorn app.main:app --reload
```

---

## 2. Swagger UI — API Test
```
Swagger adresi:
http://localhost:8000/docs

Token almak için:
POST /api/v1/auth/login → Try it out →
{
  "email": "test@trackforge.com",
  "password": "test123"
}
→ Execute → access_token'ı kopyala
→ Sağ üstteki Authorize butonuna yapıştır
→ Artık tüm endpointleri test edebilirsin
```

HTTP Status Kodları:
```
200 → Başarılı
400 → İş mantığı hatası (aynı gün tekrar kayıt gibi)
401 → Token eksik veya geçersiz
404 → Kayıt bulunamadı
422 → Request body'de hata var (trailing comma, eksik alan vs.)
```

---

## 3. pgAdmin — Veritabanı Arayüzü
```
Tarayıcıda aç:
http://localhost:5050

Giriş bilgileri:
Email    : admin@trackforge.com
Password : admin123

Sunucu bağlantısı (ilk girişte "Add New Server"):
General    → Name: TrackForge
Connection → Host    : db
             Port    : 5432
             Username: trackforge
             Password: trackforge123

Tabloları görmek için:
TrackForge → Databases → trackforge_db → Schemas → public → Tables
```

---

## 4. Alembic — Migration
```bash
alembic revision --autogenerate -m "açıklama"  # Yeni migration oluştur
alembic upgrade head                            # Migration'ı uygula
alembic downgrade -1                            # Son migration'ı geri al
alembic history                                 # Migration geçmişini gör
```

---

## 5. Git — Branch Akışı
```bash
# Yeni feature başlatmak için
git checkout develop
git checkout -b feature/xxx

# Geliştirme bitti, push et
git add .
git commit -m "feat: açıklama"
git push origin feature/xxx

# develop ve main'e merge et
git checkout develop
git merge feature/xxx
git push origin develop
git checkout main
git merge develop
git push origin main
```

---

## 6. Docker
```bash
docker-compose up -d          # Tüm servisleri başlat
docker-compose up -d pgadmin  # Sadece pgAdmin başlat
docker-compose down           # Tüm servisleri durdur
docker-compose ps             # Çalışan servisleri göster
```

---

## 7. Uvicorn
```bash
uvicorn app.main:app --reload  # Başlat
Ctrl + C                       # Durdur
```