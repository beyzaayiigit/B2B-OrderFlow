from pydantic import BaseModel, Field


class OrderNoteRequest(BaseModel):
    """Alıcının yazdığı dağınık/ham sipariş notu."""

    text: str = Field(min_length=1, max_length=4000)


class UpdateRequestRequest(BaseModel):
    """Alıcının üreticiye iletmek istediği güncelleme talebi (ham)."""

    text: str = Field(min_length=1, max_length=4000)
    order_code: str | None = Field(default=None, max_length=40)


class AssistResponse(BaseModel):
    """LLM tarafından düzenlenmiş metin."""

    result: str
    model: str
