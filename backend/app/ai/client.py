# Claude API ile bağlantı kuran merkezi client — tüm AI modülleri bunu kullanır
import anthropic
from backend.app.core.config import get_settings

settings = get_settings()

def get_claude_client() -> anthropic.Anthropic:
    # Anthropic client'ı oluştur — API key .env'den okunur
    return anthropic.Anthropic(api_key=settings.CLAUDE_API_KEY)


# Kullanılacak model — en güncel Claude Sonnet
CLAUDE_MODEL = "claude-sonnet-4-5"

# Token limitleri
MAX_TOKENS_SUMMARY = 1500      # Haftalık özet için
MAX_TOKENS_WORKOUT = 4000      # Antrenman planı için
MAX_TOKENS_MEAL = 1200         # Diyet tavsiyesi için
MAX_TOKENS_RECIPE = 1000       # Tarif önerisi için


"""
DOSYA AKIŞI:
client.py tüm AI modüllerinin ortak giriş noktasıdır.
get_claude_client() her çağrıda yeni bir Anthropic instance döndürür.
CLAUDE_MODEL sabiti tüm generator/analyzer'larda kullanılır — model değişince tek yerden güncellenir.

Spring Boot karşılığı: @Bean ile tanımlanan servis bağımlılığı.
"""