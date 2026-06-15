# ── health_report_pdf.py (v7) — Doktor/Diyetisyen PDF Raporu ──
# "Doktorum verilerimi sordu" anına tek dokunuş cevap.
# Saf veri agregasyonu — AI çağrısı YOK, kotasız.
# Türkçe karakter desteği: DejaVuSans repo'ya gömülü
# (app/assets/fonts/) — Render'da sistem fontuna bağımlılık yok.
import os
from datetime import date, timedelta

from fpdf import FPDF

FONT_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "fonts")

ACCENT = (255, 107, 43)     # TrackForge turuncu
DARK = (26, 18, 8)
GRAY = (120, 124, 140)
LIGHT_BG = (245, 246, 250)


class HealthReportPDF(FPDF):
    def __init__(self):
        super().__init__(orientation="P", unit="mm", format="A4")
        self.add_font("DejaVu", "", os.path.join(FONT_DIR, "DejaVuSans.ttf"))
        self.add_font("DejaVu", "B", os.path.join(FONT_DIR, "DejaVuSans-Bold.ttf"))
        self.set_auto_page_break(auto=True, margin=18)

    def header(self):
        self.set_font("DejaVu", "B", 10)
        self.set_text_color(*ACCENT)
        self.cell(0, 8, "TRACKFORGE — SAĞLIK RAPORU", align="L")
        self.set_font("DejaVu", "", 8)
        self.set_text_color(*GRAY)
        self.cell(0, 8, f"Oluşturma: {date.today().strftime('%d.%m.%Y')}",
                  align="R", new_x="LMARGIN", new_y="NEXT")
        self.set_draw_color(*ACCENT)
        self.line(10, self.get_y() + 1, 200, self.get_y() + 1)
        self.ln(5)

    def footer(self):
        self.set_y(-14)
        self.set_font("DejaVu", "", 7)
        self.set_text_color(*GRAY)
        self.cell(0, 6,
                  "Bu rapor TrackForge uygulamasındaki kullanıcı kayıtlarından otomatik üretilmiştir; "
                  "tıbbi belge niteliği taşımaz.",
                  align="C")

    def section_title(self, text: str):
        self.set_font("DejaVu", "B", 12)
        self.set_text_color(*DARK)
        self.cell(0, 9, text, new_x="LMARGIN", new_y="NEXT")
        self.ln(1)

    def kv_row(self, key: str, value: str):
        self.set_font("DejaVu", "", 9.5)
        self.set_text_color(*GRAY)
        self.cell(58, 7, key)
        self.set_text_color(*DARK)
        self.set_font("DejaVu", "B", 9.5)
        self.cell(0, 7, value, new_x="LMARGIN", new_y="NEXT")

    def table(self, headers: list, rows: list, widths: list):
        self.set_font("DejaVu", "B", 8.5)
        self.set_fill_color(*LIGHT_BG)
        self.set_text_color(*DARK)
        for h, w in zip(headers, widths):
            self.cell(w, 7, h, border=0, fill=True)
        self.ln()
        self.set_font("DejaVu", "", 8.5)
        for row in rows:
            for v, w in zip(row, widths):
                self.cell(w, 6.5, str(v))
            self.ln()
        self.ln(2)


def build_health_report(data: dict) -> bytes:
    """data sözlüğünden PDF üretir. Beklenen anahtarlar:
    user{full_name,email}, prefs{...}, measurements[...],
    workout{...}, nutrition{...}, fasting_mode, plateau"""
    pdf = HealthReportPDF()
    pdf.add_page()

    # ── Kişi bilgisi ──
    pdf.section_title("Kişisel Bilgiler")
    u, p = data.get("user", {}), data.get("prefs", {})
    pdf.kv_row("Ad Soyad", u.get("full_name") or "-")
    if p.get("age"):
        pdf.kv_row("Yaş", str(p["age"]))
    if p.get("gender"):
        pdf.kv_row("Cinsiyet", {"male": "Erkek", "female": "Kadın"}.get(p["gender"], p["gender"]))
    if p.get("height_cm"):
        pdf.kv_row("Boy", f"{p['height_cm']} cm")
    goal_tr = {"weight_loss": "Kilo verme", "muscle_gain": "Kas kazanımı",
               "maintenance": "Koruma"}.get(p.get("fitness_goal"), p.get("fitness_goal") or "-")
    pdf.kv_row("Hedef", goal_tr)
    if p.get("allergies"):
        pdf.kv_row("Alerjiler", ", ".join(p["allergies"]))
    if p.get("diseases"):
        pdf.kv_row("Bilinen rahatsızlıklar", ", ".join(p["diseases"]))
    if data.get("fasting_mode"):
        pdf.kv_row("Beslenme düzeni", "Oruç/Ramazan modu aktif (iftar-sahur düzeni)")
    pdf.ln(3)

    # ── Kilo / ölçüm geçmişi ──
    measurements = data.get("measurements", [])
    if measurements:
        pdf.section_title("Vücut Ölçümleri (son kayıtlar)")
        first, last = measurements[-1], measurements[0]
        if first.get("weight_kg") and last.get("weight_kg"):
            change = round(last["weight_kg"] - first["weight_kg"], 1)
            arrow = "↓" if change < 0 else "↑" if change > 0 else "→"
            pdf.kv_row("Dönem değişimi",
                       f"{first['weight_kg']} kg → {last['weight_kg']} kg ({arrow} {abs(change)} kg)")
        if data.get("plateau"):
            pl = data["plateau"]
            pdf.kv_row("Not", f"Kilo ~{pl['weeks']} haftadır {pl['weight_kg']} kg civarında sabit (plato)")
        pdf.ln(1)
        rows = []
        for m in measurements[:10]:
            rows.append([
                m.get("date", "-"),
                f"{m['weight_kg']} kg" if m.get("weight_kg") else "-",
                f"%{m['body_fat_pct']}" if m.get("body_fat_pct") else "-",
                f"{m['waist_cm']} cm" if m.get("waist_cm") else "-",
            ])
        pdf.table(["Tarih", "Kilo", "Yağ oranı", "Bel"], rows, [40, 35, 35, 35])

    # ── Antrenman özeti ──
    w = data.get("workout", {})
    if w:
        pdf.section_title("Antrenman Özeti (son 4 hafta)")
        pdf.kv_row("Toplam seans", str(w.get("sessions", 0)))
        if w.get("plan_sessions") is not None:
            pdf.kv_row("Dağılım", f"{w['plan_sessions']} plan seansı + {w['free_sessions']} serbest seans")
        pdf.kv_row("Toplam süre", f"{w.get('minutes', 0)} dk")
        pdf.kv_row("Yakılan kalori", f"~{w.get('calories', 0)} kcal")
        if w.get("top_exercises"):
            pdf.kv_row("En sık egzersizler", ", ".join(w["top_exercises"][:5]))
        pdf.ln(3)

    # ── Beslenme özeti (3-durumlu adil hesap) ──
    n = data.get("nutrition", {})
    if n:
        pdf.section_title("Beslenme Takibi (son 4 hafta)")
        pdf.kv_row("Kalori girilen gün", str(n.get("tracked_days", 0)))
        pdf.kv_row("Hedefe uyulan gün", str(n.get("complied_days", 0)))
        pdf.kv_row("Hedeften sapılan gün", str(n.get("deviated_days", 0)))
        pdf.kv_row("Kayıt girilmeyen gün", f"{n.get('no_data_days', 0)} (uyumsuzluk sayılmaz)")
        if n.get("avg_calories"):
            pdf.kv_row("Ortalama günlük alım", f"~{n['avg_calories']} kcal")
        pdf.ln(3)

    return bytes(pdf.output())
