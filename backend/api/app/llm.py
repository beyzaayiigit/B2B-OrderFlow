"""Gemini 2.5 Flash istemci sarmalayıcısı.

Anahtar yoksa istemci `None` kalır; çağrılar 503 ile yanıtlanır (uygulama çalışmaya
devam eder, frontend butonu gizler)."""
from __future__ import annotations

import os

from google import genai
from google.genai import types

_ORDER_NOTE_SYSTEM = (
    "Sen bir tekstil B2B sipariş platformunda asistansın. "
    "Alıcının yazdığı dağınık sipariş notunu, ÜRETİCİNİN net anlayacağı kısa, "
    "profesyonel ve Türkçe bir üretim notuna dönüştür. "
    "Gerekirse maddeler hâlinde yaz. Uydurma bilgi EKLEME; yalnızca verilen içeriği "
    "düzenle ve netleştir. En fazla 500 karakter. "
    "Yanıt olarak SADECE düzenlenmiş notu döndür; başlık, açıklama veya tırnak ekleme."
)

_UPDATE_REQUEST_SYSTEM = (
    "Sen bir tekstil B2B sipariş platformunda asistansın. "
    "Alıcının üreticiye iletmek istediği güncelleme talebini; kibar, net ve uygulanabilir "
    "tek bir Türkçe talep metnine dönüştür. Hangi siparişin neyinin değişeceğini açıkça belirt "
    "(beden/adet/renk/tarih vb.). Uydurma bilgi EKLEME. En fazla 600 karakter. "
    "Yanıt olarak SADECE talep metnini döndür; başlık veya açıklama ekleme."
)


def _clip(text: str, max_chars: int) -> str:
    """Metni en fazla [max_chars]'a indirir; cümle/sözcük ortasından kesmemek
    için son uygun sınıra (nokta/yeni satır/boşluk) geri çekilir."""
    if len(text) <= max_chars:
        return text
    cut = text[:max_chars]
    for sep in (". ", ".\n", "\n", "! ", "? ", "; ", ", ", " "):
        idx = cut.rfind(sep)
        if idx >= max_chars * 0.5:
            keep = idx + (1 if sep[0] in ".!?" else 0)
            return cut[:keep].rstrip()
    return cut.rstrip()


class GeminiAssistant:
    def __init__(self) -> None:
        self.model = os.getenv("GEMINI_MODEL", "gemini-2.5-flash").strip()
        api_key = os.getenv("GEMINI_API_KEY", "").strip()
        self._client: genai.Client | None = (
            genai.Client(api_key=api_key) if api_key else None
        )

    @property
    def enabled(self) -> bool:
        return self._client is not None

    def _generate(self, system: str, user_text: str, max_chars: int) -> str:
        assert self._client is not None
        resp = self._client.models.generate_content(
            model=self.model,
            contents=user_text,
            config=types.GenerateContentConfig(
                system_instruction=system,
                temperature=0.3,
                # 2.5 Flash bir "thinking" modeli; düşünme token'ları çıktı
                # bütçesini yiyip yanıtı yarıda kesebiliyor → düşünmeyi kapat.
                thinking_config=types.ThinkingConfig(thinking_budget=0),
                max_output_tokens=2048,
            ),
        )
        return _clip((resp.text or "").strip(), max_chars)

    def order_note(self, raw_text: str) -> str:
        return self._generate(_ORDER_NOTE_SYSTEM, raw_text, max_chars=500)

    def update_request(self, raw_text: str, order_code: str | None) -> str:
        prefix = f"Sipariş kodu: {order_code}\n" if order_code else ""
        return self._generate(
            _UPDATE_REQUEST_SYSTEM, f"{prefix}Talep: {raw_text}", max_chars=600
        )


assistant = GeminiAssistant()
