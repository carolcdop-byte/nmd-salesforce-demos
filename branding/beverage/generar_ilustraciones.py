"""Ilustraciones planas del portal NMD Beverage (Demo 5) y recurso estático nmd_beverage.

Genera SVG propios con la paleta NMD (sin imágenes de terceros) y empaqueta el recurso
estático force-app/main/default/staticresources/nmd_beverage.resource (zip) con:
logo.png, icono.png y las ilustraciones.

Uso: python branding/beverage/generar_ilustraciones.py
"""
import os
import shutil
import zipfile

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(os.path.dirname(AQUI))
SALIDA = os.path.join(AQUI, "svg")
SR = os.path.join(RAIZ, "force-app", "main", "default", "staticresources")

MORADO, NOCHE, CREMA, MAGENTA, AMARILLO = "#62058A", "#370355", "#FBEAE6", "#FA1190", "#FDB712"


def botella(liquido, etiqueta, texto, lata=False):
    """Botella (o lata) plana con la cara NMD en la etiqueta."""
    if lata:
        cuerpo = (f'<rect x="38" y="30" width="44" height="100" rx="8" fill="{liquido}"/>'
                  f'<rect x="40" y="24" width="40" height="8" rx="3" fill="#C9C2CC"/>')
        et_y = 62
    else:
        cuerpo = (f'<rect x="52" y="10" width="16" height="10" rx="2" fill="{NOCHE}"/>'
                  f'<path d="M54 20 h12 v18 q0 8 10 16 q6 6 6 16 v54 a8 8 0 0 1 -8 8 h-28 a8 8 0 0 1 -8 -8 v-54 q0 -10 6 -16 q10 -8 10 -16 z" fill="{liquido}"/>')
        et_y = 76
    cara = (f'<circle cx="51" cy="{et_y + 12}" r="2.2" fill="{NOCHE}"/><circle cx="69" cy="{et_y + 12}" r="2.2" fill="{NOCHE}"/>'
            f'<path d="M52 {et_y + 19} q8 6 16 0" stroke="{NOCHE}" stroke-width="2.4" fill="none" stroke-linecap="round"/>')
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 150" role="img" aria-label="{texto}">'
            f'<ellipse cx="60" cy="140" rx="34" ry="5" fill="{NOCHE}" opacity="0.15"/>{cuerpo}'
            f'<rect x="40" y="{et_y}" width="40" height="30" rx="6" fill="{etiqueta}"/>{cara}'
            f'<rect x="57" y="{et_y - 10}" width="6" height="22" rx="3" fill="#FFFFFF" opacity="0.25"/></svg>')


ZEN = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" role="img" aria-label="Zen meditando">'
       f'<circle cx="100" cy="100" r="92" fill="{CREMA}"/>'
       f'<circle cx="100" cy="64" r="10" fill="{AMARILLO}"/>'
       f'<path d="M50 76 h100 a16 16 0 0 1 16 16 v40 a16 16 0 0 1 -16 16 h-46 l-24 20 v-20 h-30 a16 16 0 0 1 -16 -16 v-40 a16 16 0 0 1 16 -16 z" fill="{MAGENTA}"/>'
       f'<path d="M68 104 q8 8 16 0" stroke="{CREMA}" stroke-width="5" fill="none" stroke-linecap="round"/>'
       f'<path d="M116 104 q8 8 16 0" stroke="{CREMA}" stroke-width="5" fill="none" stroke-linecap="round"/>'
       f'<path d="M84 122 q16 12 32 0" stroke="{CREMA}" stroke-width="5" fill="none" stroke-linecap="round"/>'
       f'<path d="M30 178 q70 -26 140 0" stroke="{MORADO}" stroke-width="8" fill="none" stroke-linecap="round"/></svg>')

HERO = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 480 300" role="img" aria-label="Cervezas NMD sin drama">'
        f'<circle cx="390" cy="70" r="40" fill="{AMARILLO}"/>'
        f'<path d="M0 230 q120 -50 240 0 t240 0 v70 h-480 z" fill="{MORADO}"/>'
        f'<path d="M0 260 q120 -40 240 0 t240 0 v40 h-480 z" fill="{NOCHE}"/>'
        f'<g transform="translate(70 70)">{botella("#F6B93B", CREMA, "Lager").split(">", 1)[1].rsplit("</svg>", 1)[0]}</g>'
        f'<g transform="translate(180 50) scale(1.15)">{botella("#E8742A", CREMA, "IPA").split(">", 1)[1].rsplit("</svg>", 1)[0]}</g>'
        f'<g transform="translate(300 70)">{botella("#3B2418", CREMA, "Stout").split(">", 1)[1].rsplit("</svg>", 1)[0]}</g></svg>')

CLUB = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 120" role="img" aria-label="Niveles Tranqui, Zen y Drama Free">'
        f'<rect x="10" y="70" width="80" height="40" rx="8" fill="{CREMA}"/><rect x="110" y="45" width="80" height="65" rx="8" fill="{AMARILLO}"/>'
        f'<rect x="210" y="15" width="80" height="95" rx="8" fill="{MAGENTA}"/>'
        f'<text x="50" y="96" font-family="Poppins, Arial" font-size="14" font-weight="700" fill="{NOCHE}" text-anchor="middle">Tranqui</text>'
        f'<text x="150" y="84" font-family="Poppins, Arial" font-size="14" font-weight="700" fill="{NOCHE}" text-anchor="middle">Zen</text>'
        f'<text x="250" y="66" font-family="Poppins, Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">Drama Free</text></svg>')

DRAMA = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 160" role="img" aria-label="Semáforo de drama">'
         f'<rect x="50" y="10" width="60" height="140" rx="16" fill="{NOCHE}"/>'
         f'<circle cx="80" cy="40" r="16" fill="{MAGENTA}"/><circle cx="80" cy="80" r="16" fill="{AMARILLO}"/><circle cx="80" cy="120" r="16" fill="#4CC38A"/>'
         f'<path d="M73 118 q7 6 14 0" stroke="{NOCHE}" stroke-width="3" fill="none" stroke-linecap="round"/></svg>')

ILUSTRACIONES = {
    "nmd-bev-001.svg": botella("#F6B93B", CREMA, "Lager Zen"),
    "nmd-bev-002.svg": botella("#E8742A", AMARILLO, "IPA Sin Drama"),
    "nmd-bev-003.svg": botella("#3B2418", MAGENTA, "Stout Plan B"),
    "nmd-bev-004.svg": botella("#F4E04D", CREMA, "Radler Todo Bien", lata=True),
    "zen.svg": ZEN, "hero.svg": HERO, "club.svg": CLUB, "drama.svg": DRAMA,
}

if __name__ == "__main__":
    os.makedirs(SALIDA, exist_ok=True)
    for nombre, svg in ILUSTRACIONES.items():
        open(os.path.join(SALIDA, nombre), "w", encoding="utf-8").write(svg)
    zip_path = os.path.join(SR, "nmd_beverage.resource")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        for nombre in ILUSTRACIONES:
            z.write(os.path.join(SALIDA, nombre), nombre)
        z.write(os.path.join(RAIZ, "branding", "nmd-logo-horizontal.png"), "logo.png")
        z.write(os.path.join(RAIZ, "branding", "nmd-icono.png"), "icono.png")
    open(os.path.join(SR, "nmd_beverage.resource-meta.xml"), "w", encoding="utf-8", newline="\n").write(
        '<?xml version="1.0" encoding="UTF-8"?>\n<StaticResource xmlns="http://soap.sforce.com/2006/04/metadata">\n'
        '    <cacheControl>Public</cacheControl>\n    <contentType>application/zip</contentType>\n'
        '    <description>Portal NMD Beverage: logo, icono e ilustraciones planas propias (botellas, Zen, club, semáforo de drama).</description>\n'
        '</StaticResource>\n')
    print("ok", len(ILUSTRACIONES), "ilustraciones ->", zip_path)
