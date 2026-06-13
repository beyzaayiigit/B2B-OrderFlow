"""TextileFlow demo API — Gemini 2.5 Flash destekli metin asistanı.

Endpoints:
  GET  /health              → servis + LLM durumu
  POST /assist/order-note   → dağınık notu üretici-dostu nota çevirir
  POST /assist/update-request → ham talebi net güncelleme talebine çevirir
"""
from __future__ import annotations

import os

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

load_dotenv()

from .llm import assistant  # noqa: E402  (load_dotenv'den sonra import)
from .schemas import (  # noqa: E402
    AssistResponse,
    OrderNoteRequest,
    UpdateRequestRequest,
)

app = FastAPI(title="TextileFlow Assist API", version="0.1.0")

_origins = [
    o.strip() for o in os.getenv("ALLOWED_ORIGINS", "*").split(",") if o.strip()
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins or ["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health() -> dict[str, object]:
    return {"status": "ok", "llm_enabled": assistant.enabled, "model": assistant.model}


def _require_llm() -> None:
    if not assistant.enabled:
        raise HTTPException(
            status_code=503,
            detail="LLM yapılandırılmamış (GEMINI_API_KEY eksik).",
        )


@app.post("/assist/order-note", response_model=AssistResponse)
def assist_order_note(req: OrderNoteRequest) -> AssistResponse:
    _require_llm()
    try:
        result = assistant.order_note(req.text)
    except Exception as exc:  # noqa: BLE001 — demo: hatayı tek tip döndür
        raise HTTPException(status_code=502, detail=f"LLM hatası: {exc}") from exc
    if not result:
        raise HTTPException(status_code=502, detail="Boş yanıt alındı.")
    return AssistResponse(result=result, model=assistant.model)


@app.post("/assist/update-request", response_model=AssistResponse)
def assist_update_request(req: UpdateRequestRequest) -> AssistResponse:
    _require_llm()
    try:
        result = assistant.update_request(req.text, req.order_code)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=502, detail=f"LLM hatası: {exc}") from exc
    if not result:
        raise HTTPException(status_code=502, detail="Boş yanıt alındı.")
    return AssistResponse(result=result, model=assistant.model)
