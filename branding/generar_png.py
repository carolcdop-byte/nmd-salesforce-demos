"""Genera los PNG de marca de No More Drama a partir de nmd-emblema.svg.

Usa Chrome (o Edge) en modo headless para renderizar HTML con fondo transparente,
así no hace falta instalar librerías de imagen. Fuente: Poppins Bold (branding/fonts, licencia OFL).

    python branding/generar_png.py

Salida (en branding/):
  nmd-logo-horizontal.png  565x120  emblema + "NO MORE DRAMA" en crema, fondo transparente (tema de la org)
  nmd-icono.png            512x512  emblema (apps y avatar de Zen)
"""
import os
import subprocess
import tempfile
from pathlib import Path

DIR = Path(__file__).resolve().parent
CREMA = "#FBEAE6"
NAVEGADORES = [r"C:\Program Files\Google\Chrome\Application\chrome.exe",
               r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"]

emblema = (DIR / "nmd-emblema.svg").read_text(encoding="utf-8").strip()
fuente = (DIR / "fonts" / "Poppins-Bold.ttf").as_uri()

BASE = f"""<!doctype html><html><head><meta charset="utf-8"><style>
@font-face {{ font-family: Poppins; src: url('{fuente}') format('truetype'); font-weight: 700; }}
html, body {{ margin: 0; padding: 0; background: transparent; overflow: hidden; }}
</style></head><body>%s</body></html>"""

PIEZAS = {
    "nmd-logo-horizontal.png": ((565, 120), f"""
<div style="display:flex;align-items:center;height:120px;width:565px;">
  <div style="width:112px;height:112px;margin:4px 18px 4px 4px;">{emblema.replace('<svg ', '<svg width="112" height="112" ')}</div>
  <div style="font-family:Poppins;font-weight:700;font-size:47px;letter-spacing:1px;color:{CREMA};white-space:nowrap;line-height:1;">NO MORE DRAMA</div>
</div>"""),
    "nmd-icono.png": ((512, 512), emblema.replace('<svg ', '<svg width="512" height="512" style="display:block" ')),
}

navegador = next(p for p in NAVEGADORES if os.path.exists(p))
with tempfile.TemporaryDirectory() as tmp:
    for nombre, ((w, h), cuerpo) in PIEZAS.items():
        html = Path(tmp) / (nombre + ".html")
        html.write_text(BASE % cuerpo, encoding="utf-8")
        salida = DIR / nombre
        subprocess.run([navegador, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                        "--default-background-color=00000000", "--force-device-scale-factor=1",
                        f"--window-size={w},{h}", f"--screenshot={salida}", "--virtual-time-budget=3000",
                        html.as_uri()], check=True, capture_output=True, timeout=120)
        print("ok", salida.name, salida.stat().st_size, "bytes")
