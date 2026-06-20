# Claude API ile bağlantı kuran merkezi client — tüm AI modülleri bunu kullanır
import anthropic
from backend.app.core.config import get_settings

settings = get_settings()

def get_claude_client() -> anthropic.Anthropic:
    # Anthropic client'ı oluştur — API key .env'den okunur
    return anthropic.Anthropic(api_key=settings.ANTHROPIC_API_KEY)


# Kullanılacak model — Sonnet 4.5'in KANONİK pinned snapshot'ı.
# NOT: Tarihsiz 'claude-sonnet-4-5' alias'ı yerine tarihli ID kullanıyoruz:
# pinned snapshot her zaman geçerli (alias bazı durumlarda 400 verebiliyor),
# chat modeli zaten tarihli (-20251001) — tutarlılık için generation da öyle.
CLAUDE_MODEL = "claude-sonnet-4-5-20250929"

# v1.1: Sohbet asistanı için ucuz/hızlı model — plan üretimindeki ağır
# Sonnet yerine Haiku. Sohbet sık ve kısa olduğu için maliyet kritik.
CLAUDE_CHAT_MODEL = "claude-haiku-4-5-20251001"

# Token limitleri
MAX_TOKENS_SUMMARY = 1500      # Haftalık özet için
MAX_TOKENS_WORKOUT = 4000      # Antrenman planı için
MAX_TOKENS_MEAL = 3000         # Diyet tavsiyesi için
MAX_TOKENS_RECIPE = 2200       # Tarif önerisi için (1000 düşüktü — uzun tarifte JSON kesilip parse hatası 500 veriyordu)
MAX_TOKENS_CHAT = 600          # v1.1: Sohbet yanıtı — kısa tutulur (token tavanı = uzun plan dökülemez)


"""
DOSYA AKIŞI:
client.py tüm AI modüllerinin ortak giriş noktasıdır.
get_claude_client() her çağrıda yeni bir Anthropic instance döndürür.
CLAUDE_MODEL sabiti tüm generator/analyzer'larda kullanılır — model değişince tek yerden güncellenir.

Spring Boot karşılığı: @Bean ile tanımlanan servis bağımlılığı.
"""