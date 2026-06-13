"""TextileFlow uygulama ve bildirim ikonlarını üretir."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
# Asla çıktı dosyasını kaynak olarak kullanma — döngüsel küçülme yapar.
SOURCE = ROOT / "assets" / "logos" / "textileflow_source.png"
APP_ICON_OUT = ROOT / "assets" / "logos" / "app_icon.png"
FOREGROUND_OUT = ROOT / "assets" / "logos" / "app_icon_foreground.png"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
ADAPTIVE_ICON_XML = ANDROID_RES / "mipmap-anydpi-v26" / "ic_launcher.xml"

APP_ICON_SIZE = 1024
# Adaptive icon güvenli alanı ~%72; inset yok, logo biraz büyük dursun.
LOGO_SCALE = 0.84
# Gölge nedeniyle optik olarak aşağı kayıyor; hafif yukarı.
OFFSET_Y_RATIO = -0.035

NOTIFICATION_SIZES = {
    "drawable-mdpi": 24,
    "drawable-hdpi": 36,
    "drawable-xhdpi": 48,
    "drawable-xxhdpi": 72,
    "drawable-xxxhdpi": 96,
}
NOTIFICATION_SCALE = 0.78
NOTIFICATION_OFFSET_Y_RATIO = -0.04


def _is_logo_pixel(r: int, g: int, b: int, a: int) -> bool:
    if a < 20:
        return False
    if r > 235 and g > 235 and b > 235:
        return False
    mx = max(r, g, b)
    mn = min(r, g, b)
    # Gölge / gri tonlar
    if mx - mn < 28:
        return False
    # Koyu metin
    if mx < 110:
        return False
    return True


def _extract_symbol(img: Image.Image) -> Image.Image:
    """Kaynak logodan yalnızca renkli sembolü ayır."""
    rgba = img.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()

    min_x, min_y = width, height
    max_x, max_y = 0, 0
    found = False

    # Metin sağda; sembol genelde sol %45'te.
    symbol_right = int(width * 0.37)

    for y in range(height):
        for x in range(symbol_right):
            r, g, b, a = pixels[x, y]
            if not _is_logo_pixel(r, g, b, a):
                continue
            found = True
            min_x = min(min_x, x)
            min_y = min(min_y, y)
            max_x = max(max_x, x)
            max_y = max(max_y, y)

    if not found:
        raise RuntimeError("Sembol pikselleri bulunamadı.")

    pad = 2
    cropped = rgba.crop(
        (
            max(0, min_x - pad),
            max(0, min_y - pad),
            min(symbol_right, max_x + 1),
            min(height, max_y + 1 + pad),
        )
    )
    return _trim_non_symbol_columns(cropped)


def _trim_non_symbol_columns(img: Image.Image) -> Image.Image:
    """Sağ kenardaki metin artıklarını temizle."""
    rgba = img.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    last_col = 0
    for x in range(width):
        if any(
            _is_logo_pixel(*pixels[x, y][:3], pixels[x, y][3]) for y in range(height)
        ):
            last_col = x
    return rgba.crop((0, 0, last_col + 1, height))


def _fit_logo(logo: Image.Image, target: int) -> Image.Image:
    """thumbnail yalnızca küçültür; launcher için büyütmek gerekir."""
    width, height = logo.size
    scale = min(target / width, target / height)
    new_w = max(1, round(width * scale))
    new_h = max(1, round(height * scale))
    return logo.resize((new_w, new_h), Image.Resampling.LANCZOS)


def _place_on_canvas(
    logo: Image.Image,
    size: int,
    scale: float,
    *,
    background: tuple[int, ...],
    offset_y_ratio: float = 0.0,
) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), background)
    target = int(size * scale)
    fitted = _fit_logo(logo, target)
    offset_x = (size - fitted.width) // 2
    offset_y = (size - fitted.height) // 2 + int(size * offset_y_ratio)
    canvas.paste(fitted, (offset_x, offset_y), fitted)
    return canvas


def _notification_icon_from_rgba(symbol_rgba: Image.Image, size: int) -> Image.Image:
    """Android FCM: şeffaf zemin, beyaz siluet."""
    rgba = symbol_rgba.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    alpha = Image.new("L", (width, height), 0)
    alpha_pixels = alpha.load()
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a < 20:
                continue
            if r > 240 and g > 240 and b > 240:
                continue
            alpha_pixels[x, y] = 255

    min_x, min_y, max_x, max_y = width, height, 0, 0
    found = False
    for y in range(height):
        for x in range(width):
            if alpha_pixels[x, y] > 0:
                found = True
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    if not found:
        raise RuntimeError("Bildirim ikonu için sembol bulunamadı.")

    pad = 4
    cropped_alpha = alpha.crop(
        (
            max(0, min_x - pad),
            max(0, min_y - pad),
            min(width, max_x + 1 + pad),
            min(height, max_y + 1 + pad),
        )
    )

    target = int(size * NOTIFICATION_SCALE)
    cw, ch = cropped_alpha.size
    scale = min(target / cw, target / ch)
    nw, nh = max(1, round(cw * scale)), max(1, round(ch * scale))
    resized = cropped_alpha.resize((nw, nh), Image.Resampling.LANCZOS)

    canvas_alpha = Image.new("L", (size, size), 0)
    ox = (size - nw) // 2
    oy = (size - nh) // 2 + int(size * NOTIFICATION_OFFSET_Y_RATIO)
    canvas_alpha.paste(resized, (ox, oy))

    white = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    transparent = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    return Image.composite(white, transparent, canvas_alpha)


def _notification_icon(logo: Image.Image, size: int) -> Image.Image:
    """Kaynak sembol kırpımından bildirim silueti (eski yol)."""
    placed = _place_on_canvas(
        logo,
        size,
        NOTIFICATION_SCALE,
        background=(0, 0, 0, 0),
        offset_y_ratio=NOTIFICATION_OFFSET_Y_RATIO,
    )
    return _notification_icon_from_rgba(placed, size)


def _fix_adaptive_icon_xml() -> None:
    ADAPTIVE_ICON_XML.write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@color/ic_launcher_background"/>
  <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
""",
        encoding="utf-8",
    )
    print(f"Adaptive icon xml: {ADAPTIVE_ICON_XML}")


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    logo = _extract_symbol(source)
    print(f"Symbol crop: {logo.size[0]}x{logo.size[1]} from {SOURCE.name}")

    app_icon = _place_on_canvas(
        logo,
        APP_ICON_SIZE,
        LOGO_SCALE,
        background=(255, 255, 255, 255),
        offset_y_ratio=OFFSET_Y_RATIO,
    ).convert("RGB")
    app_icon.save(APP_ICON_OUT, format="PNG", optimize=True)
    print(f"App icon: {APP_ICON_OUT}")

    foreground = _place_on_canvas(
        logo,
        APP_ICON_SIZE,
        LOGO_SCALE,
        background=(0, 0, 0, 0),
        offset_y_ratio=OFFSET_Y_RATIO,
    )
    foreground.save(FOREGROUND_OUT, format="PNG", optimize=True)
    print(f"Adaptive foreground: {FOREGROUND_OUT}")

    for folder, size in NOTIFICATION_SIZES.items():
        out_dir = ANDROID_RES / folder
        out_dir.mkdir(parents=True, exist_ok=True)
        notification = _notification_icon_from_rgba(foreground, size)
        out_path = out_dir / "ic_notification.png"
        notification.save(out_path, format="PNG", optimize=True)
        print(f"Notification icon ({size}px): {out_path}")

    _fix_adaptive_icon_xml()


if __name__ == "__main__":
    main()
