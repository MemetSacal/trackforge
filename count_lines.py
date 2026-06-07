from pathlib import Path

ROOT = Path(__file__).parent

EXTENSIONS = {
    ".dart",
    ".java",
    ".kt",
    ".py",
    ".js",
    ".ts",
    ".html",
    ".css",
    ".sql",
    ".xml",
    ".yaml",
    ".yml",
}

IGNORE_DIRS = {
    ".git",
    ".idea",
    ".dart_tool",
    ".gradle",
    "build",
    "target",
    "node_modules",
}

stats = {
    "Flutter (Dart)": 0,
    "Backend (Java/Kotlin)": 0,
    "Python": 0,
    "Web": 0,
    "Config": 0,
}

total_lines = 0
total_files = 0
largest_files = []

for file in ROOT.rglob("*"):
    if not file.is_file():
        continue

    if any(part in IGNORE_DIRS for part in file.parts):
        continue

    ext = file.suffix.lower()

    if ext not in EXTENSIONS:
        continue

    try:
        with open(file, "r", encoding="utf-8", errors="ignore") as f:
            line_count = sum(1 for _ in f)

        total_lines += line_count
        total_files += 1

        largest_files.append(
            (line_count, str(file.relative_to(ROOT)))
        )

        if ext == ".dart":
            stats["Flutter (Dart)"] += line_count

        elif ext in [".java", ".kt"]:
            stats["Backend (Java/Kotlin)"] += line_count

        elif ext == ".py":
            stats["Python"] += line_count

        elif ext in [".js", ".ts", ".html", ".css"]:
            stats["Web"] += line_count

        else:
            stats["Config"] += line_count

    except:
        pass

largest_files.sort(reverse=True)


def progress_bar(percent, width=40):
    filled = int(width * percent / 100)
    return "█" * filled + "░" * (width - filled)


if total_lines < 5000:
    level = "🌱 KÜÇÜK PROJE"
elif total_lines < 15000:
    level = "🔥 ORTA ÖLÇEK"
elif total_lines < 30000:
    level = "🚀 BÜYÜK PROJE"
elif total_lines < 50000:
    level = "💎 PROFESYONEL ÜRÜN"
else:
    level = "👑 DEVASA YAZILIM"

print("\n")
print("█" * 70)
print("🚀 TRACKFORGE CODE ANALYZER")
print("█" * 70)

print()
print(f"📁 Toplam Dosya  : {total_files}")
print(f"📝 Toplam Satır  : {total_lines:,}")
print(f"🏆 Seviye        : {level}")

print()
print("📊 MODÜL DAĞILIMI")
print("─" * 70)

for name, count in stats.items():
    if total_lines == 0:
        percent = 0
    else:
        percent = count * 100 / total_lines

    print(
        f"{name:<24} "
        f"{count:>8,} satır   "
        f"{percent:>5.1f}%"
    )

print()
print("🏅 EN BÜYÜK 10 DOSYA")
print("─" * 70)

for i, (lines, file) in enumerate(largest_files[:10], start=1):
    print(
        f"{i:>2}. "
        f"{lines:>6,} satır  |  {file}"
    )

print()
print("📈 PROJE BÜYÜKLÜĞÜ")

max_target = 50000
percent = min(total_lines / max_target * 100, 100)

print(progress_bar(percent))
print(f"{percent:.1f}%")

print()
print("█" * 70)
print("TRACKFORGE PROJECT REPORT COMPLETED")
print("█" * 70)