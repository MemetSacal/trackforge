import os
from collections import defaultdict

extensions = (".py", ".java", ".js", ".ts")
exclude_dirs = {"__pycache__", "venv", ".git", "alembic", "migrations", "uploads"}

total_lines = 0
file_stats = []
folder_stats = defaultdict(int)

for root, dirs, files in os.walk("."):
    dirs[:] = [d for d in dirs if d not in exclude_dirs]

    for file in files:
        if file.endswith(extensions):
            path = os.path.join(root, file)
            try:
                with open(path, "r", encoding="utf-8") as f:
                    lines = sum(1 for _ in f)
                    total_lines += lines
                    file_stats.append((path, lines))

                    # klasör bazlı
                    folder = root.split(os.sep)[1] if len(root.split(os.sep)) > 1 else root
                    folder_stats[folder] += lines
            except:
                pass

# 🔥 OUTPUT

print("\n🔥 TRACKFORGE CODE ANALYSIS 🔥\n")

print(f"🧠 Toplam Satır: {total_lines}\n")

# 📁 klasör bazlı
print("📦 Klasör Bazlı Dağılım:")
for folder, lines in sorted(folder_stats.items(), key=lambda x: x[1], reverse=True):
    print(f"   {folder:15} → {lines} satır")

# 📄 en büyük dosyalar
print("\n🏆 En Büyük 10 Dosya:")
for path, lines in sorted(file_stats, key=lambda x: x[1], reverse=True)[:10]:
    print(f"   {lines:5} satır → {path}")

# 📊 ortalama
if file_stats:
    avg = total_lines / len(file_stats)
    print(f"\n📊 Ortalama Dosya Boyutu: {int(avg)} satır")

print("\n✨ Analiz tamamlandı\n")