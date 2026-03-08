Generic single-database configuration.

Migration nedir?
Biz UserModel'i Python kodu olarak yazdık ama bu henüz veritabanında bir tablo oluşturmadı. Veritabanı hala boş.
Migration = "Python'daki model değişikliğini alıp veritabanına SQL olarak uygula" demek.
Spring Boot'ta spring.jpa.hibernate.ddl-auto=create vardı ya — Hibernate otomatik tablo oluşturuyordu.
Alembic ise bunu manuel ve versiyonlu yapıyor. Yani:
UserModel (Python) → Alembic → CREATE TABLE users (...) → PostgreSQL
Ayrıca her migration bir versiyon dosyası oluşturuyor.
İleride "bu tabloya şu kolonu ekle" dediğinde Alembic neyin ne zaman eklendiğini biliyor — Git gibi ama veritabanı için.
