# ── chat_assistant.py (v1.1) — Kişisel Koç Sohbeti ──
#
# TASARIM İLKESİ — üç kilitli kapı (hak kaçağını önler):
#   1. ÜRETMEZ, OKUR: Asistan yeni plan/diyet ÜRETMEZ. Kullanıcının
#      zaten kayıtlı verilerini (context_builder) okuyup yorumlar.
#      Tam üretim isteyen, ilgili ekrana yönlendirilir.
#   2. TOKEN TAVANI: MAX_TOKENS_CHAT=600 → 7 günlük plan fiziksel
#      olarak sığmaz. Kullanıcı ne kadar uğraşsa da uzun içerik dökülemez.
#   3. UCUZ MODEL: Haiku kullanır (Sonnet değil) + kendi ayrı kotası
#      var. Saçma soru soran kendi sohbet hakkını yer, plan bütçesine
#      dokunamaz.
import asyncio

from backend.app.ai.client import get_claude_client, CLAUDE_CHAT_MODEL, MAX_TOKENS_CHAT

SYSTEM_PROMPT = """Sen TrackForge uygulamasının kişisel sağlık ve fitness koçusun.
Kullanıcıyla samimi, kısa ve motive edici konuşursun (Türkçe).

KURALLARIN:
- Kullanıcının aşağıda verilen GERÇEK verilerine dayanarak konuş. Veri yoksa uydurma.
- Cevapların KISA olsun (en fazla birkaç cümle). Uzun listeler, 7 günlük planlar YAZMA.
- Kullanıcı tam bir antrenman planı isterse: "Bunu senin için Antrenman Planı ekranında üretelim, oradaki hakkınla en iyisini hazırlarım" de ve cevabının EN SONUNA yeni bir satırda tam olarak [NAV:workout] etiketini ekle.
- Kullanıcı tam haftalık diyet listesi isterse: "Diyet Planı ekranından üretelim" diye yönlendir ve cevabının EN SONUNA yeni bir satırda tam olarak [NAV:meal] etiketini ekle.
- [NAV:...] etiketini SADECE bu iki yönlendirme durumunda kullan, başka hiçbir cevapta kullanma. Etiketi cümle içine gömme, ayrı satırda ve tam olarak köşeli parantezle yaz.
- Tıbbi teşhis KOYMA. Sağlık endişesinde "bir doktora danışmanı öneririm" de.
- Fitness/sağlık/beslenme dışı konularda (genel sohbet, ödev, kod vb.) kibarca reddet: "Ben senin fitness koçunum, o konuda yardımcı olamam ama antrenman/beslenme konusunda buradayım 💪"
- Emoji kullanabilirsin ama abartma."""


async def chat_with_assistant(
    user_message: str,
    user_context: str,
    history: list = None,
) -> str:
    """Tek bir asistan yanıtı üretir.

    user_message : kullanıcının son mesajı
    user_context : build_user_context() çıktısı (gerçek veriler)
    history      : [{"role": "user"/"assistant", "content": "..."}] — son birkaç tur
    """
    client = get_claude_client()

    context_block = (
        f"KULLANICININ GÜNCEL VERİLERİ:\n{user_context}"
        if user_context else
        "KULLANICININ HENÜZ YETERLİ VERİSİ YOK — onu veri girmeye nazikçe teşvik et."
    )

    messages = []
    # Geçmişi ekle (en fazla son 6 tur — bağlam şişmesin, maliyet artmasın)
    if history:
        for turn in history[-6:]:
            role = turn.get("role")
            content = turn.get("content", "")
            if role in ("user", "assistant") and content:
                messages.append({"role": role, "content": content})
    # Son kullanıcı mesajı
    messages.append({"role": "user", "content": user_message})

    def _call():
        return client.messages.create(
            model=CLAUDE_CHAT_MODEL,
            max_tokens=MAX_TOKENS_CHAT,
            system=f"{SYSTEM_PROMPT}\n\n{context_block}",
            messages=messages,
        )

    message = await asyncio.to_thread(_call)
    # Yanıt metnini topla (Haiku düz metin döner)
    parts = [block.text for block in message.content if hasattr(block, "text")]
    return "".join(parts).strip()
