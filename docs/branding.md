# Marca No More Drama en Salesforce

> Proyecto de portfolio. No More Drama (NMD) es una marca ficticia.

## Paleta

| Color | Hex | Uso en Salesforce |
|---|---|---|
| Morado NMD | `#62058A` | Color principal del tema (botones, enlaces, pestaña activa) |
| Morado noche | `#370355` | Fondo de la cabecera (tema) y color de la app NMD Care |
| Crema | `#FBEAE6` | Texto del logo y trazos del emblema |
| Magenta | `#FA1190` | Emblema |
| Naranja | `#F9913C` | — (reservado) |
| Amarillo zen | `#FDB712` | Punto del emblema |

Tipografía de marca: **Poppins**. Salesforce no permite cambiar la fuente de la interfaz, así que Poppins solo aparece en las imágenes (logo). La fuente está en `branding/fonts/` con su licencia SIL Open Font License (`OFL.txt`).

## Archivos (`branding/`)

| Archivo | Qué es |
|---|---|
| `nmd-emblema.svg` | Emblema original (viewBox 0 0 120 120) |
| `nmd-logo-horizontal.png` | 565×120, emblema + "NO MORE DRAMA" en crema, fondo transparente. Logo del tema |
| `nmd-icono.png` | 512×512, emblema. Logo de la app NMD Care y foto de Zen |
| `generar_png.py` | Regenera los PNG con Chrome o Edge en modo headless (no necesita librerías de imagen): `python branding/generar_png.py` |

En la org, los PNG son **Content Assets**: `NMD_Logo` y `NMD_Icono` (`force-app/main/default/contentassets/`).

## Qué se aplicó

| Elemento | Metadata | Resultado |
|---|---|---|
| Tema de la org "No More Drama" | `brandingSets/No_More_Drama` + `lightningExperienceThemes/No_More_Drama` | Color principal `#62058A`, logo `/file-asset/NMD_Logo`, cabecera `#370355`. **Activo** |
| App NMD Care | `applications/NMD_Care` (`<brand>`) | Color `#370355`, logo `NMD_Icono` (Iniciador de aplicaciones), usa el tema de la org |
| Zen | `data/nmd-zen-avatar.apex` | Foto de perfil del usuario "Zen Agente NMD" = icono NMD |
| Nivel de drama de un vistazo | `objects/Case/fields/Drama__c` | Fórmula semáforo, primera columna de las vistas "Urgencias NMD" y "Cola por drama" |

### Campo "Drama" (semáforo)

| Situación | Muestra |
|---|---|
| Nivel 5 | 🔴 5 |
| Nivel 4 | 🟠 4 |
| Nivel 3 | 🟡 3 |
| Nivel 1-2 | 🟢 1 / 🟢 2 |
| IA fallida y sin nivel | ⚠️ Revisar |
| Sin triaje | ⚪ — |

Es una fórmula de texto, de solo lectura, que funciona en vistas de lista, móvil e informes. Al ordenar la vista por *Drama* en ascendente, los semáforos salen de más a menos urgente (🔴 → 🟢). Los casos ⚠️ y ⚪ quedan al principio.

## Páginas de inicio con la marca NMD

Ambas usan la plantilla de inicio estándar con una cabecera de texto enriquecido (icono `NMD_Icono`, título en morado NMD y un lema) y se asignan como página de inicio de cada app (`actionOverrides` con `standard-home`). Informes en la carpeta **NMD**.

| App | Página | Contenido |
|---|---|---|
| NMD Distribución | `NMD_Inicio_Distribucion` | Pipeline por etapa (`NMD_Pipeline_inicio`) · Ventas del mes por producto (`NMD_Ventas_mes_por_producto`) · Elementos para aprobar (presupuestos pendientes de mi aprobación) · Vista *Leads calientes* |
| NMD Care | `NMD_Inicio_Care` | Vista *Urgencias NMD* (con el semáforo Drama) · Casos abiertos por camino (`NMD_Casos_abiertos_por_camino`) · Tareas de hoy · Vista *Casos de Zen esta semana* |

NMD Care tiene ahora la pestaña **Inicio** (con su mapeo de espacio de trabajo de consola). Comprobado en el navegador con la jefa de ventas, el Comercial NMD y el Agente Humano NMD (que ve sus tareas de hoy del Triaje NMD).

## Cómo desplegarla en otra org

```bash
D=force-app/main/default
sf project deploy start -d $D/contentassets --target-org <alias>
sf project deploy start -d $D/brandingSets -d $D/lightningExperienceThemes -d $D/applications \
  -d $D/objects/Case/fields/Drama__c.field-meta.xml -d $D/objects/Case/listViews \
  -d $D/permissionsets/NMD_Base.permissionset-meta.xml --target-org <alias>
sf apex run --file data/nmd-zen-avatar.apex --target-org <alias>
```

Después, en **Configuración → Temas y marca**, activa "No More Drama" (no se puede activar por metadata).

## Avatar de Zen en el chat (cuando tenga canal)

El agente no tiene campo de avatar en sus metadatos: el avatar del chat se define en el canal. Cuando Zen tenga Messaging for In-App and Web:

1. **Configuración → Implementaciones de servicios integrados** → la implementación de Zen.
2. **Messaging for In-App and Web Settings → Branding** (Configuración de marca).
3. En *Avatar del agente* o *Logotipo*, sube `branding/nmd-icono.png`. Usa los colores de la paleta (principal `#62058A`, secundario `#370355`).
4. **Publica** la implementación.

## Lecciones aprendidas

- **Activar un tema personalizado desactiva SLDS 2.** Los temas personalizados usan SLDS 1; al activar "No More Drama", Salesforce desactiva el estilo "Salesforce Cosmos" (SLDS 2). Para volver atrás, activa de nuevo Cosmos en Temas y marca.
- **`BrandingSet` sin `type`:** los valores probados (`lightningExperience`, `LightningExperience`, `Lightning`) dan error; sin el campo, despliega bien.
- **El logo de la app va dentro de `<brand>`:** `<brand><logo>NMD_Icono</logo><logoVersion>1</logoVersion></brand>`, con el nombre de un Content Asset. Un `<logo>` fuera de `<brand>` (o apuntando a un Document) se ignora en silencio.
- **"Sustituir el tema de la organización" en la app oculta el logo del tema.** Con `shouldOverrideOrgTheme=true`, NMD Care mostraba la nube de Salesforce en la cabecera. Con `false`, usa el tema de la org (logo NMD y cabecera `#370355`).
- **Logo crema sobre cabecera oscura:** el texto crema solo se lee sobre fondo oscuro. Por eso la cabecera del tema es morado noche; el buscador (caja blanca) y los iconos (blancos) se leen bien.
