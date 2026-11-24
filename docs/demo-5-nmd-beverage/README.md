# Demo 5 — NMD Beverage: portal público con el chat de Zen

> Proyecto de portfolio. No More Drama (NMD) es una marca ficticia y todos los datos de demo son inventados.

## 1. Historia

El consumidor final de NMD Beverage entra en la web de la marca:

1. Descubre las cervezas.
2. Se apunta al club **Drama Points**.
3. Si tiene un problema, habla con **Zen** o rellena **"Tengo un drama"**.

Si el problema se complica, el caso llega a **NMD Care** ya priorizado por el **Triaje NMD** (Demo 2).

**Portal:** `https://tu-dominio.develop.my.site.com/nmdbeverage` (Experience Cloud LWR, plantilla Build Your Own).

> En una Developer Edition el dominio `*.my.site.com` es fijo y la ruta solo admite caracteres alfanuméricos, por eso es `/nmdbeverage` y no `nmd-beverage`.

## 2. Usuarios

| Usuario | Licencia y perfil | Qué ve |
|---|---|---|
| **Visitante** (usuario invitado) | Guest, perfil `NMD Beverage Perfil` | Páginas públicas, catálogo, formularios y chat. Ningún acceso directo a objetos. |
| **Marta López Fuentes** y **Andrés Prieto Calvo** (particulares de la cuenta "Clientes NMD") | Customer Community, perfil propio `NMD Cliente Beverage` + permission set `NMD_Cliente_Portal` | Lo mismo que el visitante, más **Mi zona**: solo sus pedidos, sus casos y sus Drama Points |
| **Agente Humano NMD** | Demo 1 | Recibe en NMD Care los casos del portal y del chat, ya triados. Ve los Drama Points en la ficha del contacto. |

`data/nmd-clientes-portal.apex` crea los dos usuarios de portal. El email de esos usuarios es el de quien ejecuta el script, para recibir el enlace de contraseña. Los nombres de usuario son ficticios.

Carmen Soler, propuesta al principio, era contacto de un restaurante (B2B). Por eso se usaron los dos particulares de "Clientes NMD".

## 3. Páginas

| Página | Ruta | Componente | Acceso |
|---|---|---|---|
| Inicio | `/` | `nmdInicio` | Público |
| Cervezas | `/cervezas` | `nmdCatalogo` | Público |
| Club Drama Points | `/club` | `nmdClub` (niveles, reglas y "Únete al club") | Público |
| Tengo un drama | `/tengo-un-drama` | `nmdTengoUnDrama` | Público |
| Sobre nosotros ("Sobre NMD Beverage") | `/sobre-nmd` | `nmdSobre` | Público |
| Mi zona | `/mi-zona` | `nmdMiZona` | **Requiere login** |
| Aviso legal, Privacidad, Cookies | `/aviso-legal`, `/privacidad`, `/cookies` | `nmdLegal` | Público |

- **Cabecera y pie:** `nmdCabecera` y `nmdPie`, en el layout común. El chat también está en el layout común.
- **Contenido:** el portal habla solo de NMD Beverage; no menciona NMD Clinic ni NMD Care.
- **Marca:** paleta NMD (morado #62058A, morado noche #370355, crema #FBEAE6, magenta #FA1190, amarillo zen #FDB712), logo NMD y estilos compartidos en el módulo CSS `nmdEstilos`.
- **Ilustraciones:** SVG planos propios (botellas con cara, Zen, niveles del club, semáforo de drama). Los genera `branding/beverage/generar_ilustraciones.py` y van en el recurso estático `nmd_beverage`. No se usan imágenes de terceros.
- **Todo se despliega como metadatos:** `digitalExperiences/site/NMD_Beverage1`, con rutas personalizadas que terminan en `__c`.

## 4. Catálogo (sin precios)

La licencia de usuario invitado **no admite `Product2`**, ni siquiera desde Apex. Por eso:

- El Flow `NMD_Portal_Publicar_Producto` publica cada botella Beverage (`NMD-BEV-0xx`) en el objeto **`Producto_portal__c`** con nombre, código, descripción y activo. **Nunca se publican precios.**
- `Product2` sigue siendo la fuente de la verdad: cualquier cambio en el producto se copia solo.
- `NMD_PortalCatalogo` lee ese objeto en modo sistema y devuelve un DTO.

## 5. "Tengo un drama" y "Únete al club"

**Tengo un drama** (`NMD_PortalFormularios.crearDrama`)
- Crea el caso con origen **Web NMD Beverage**, asignado a la cola Agentes NMD.
- Si el email coincide con un contacto, vincula el caso a ese contacto. Si además el número de pedido es suyo, también vincula el pedido.
- El **Triaje NMD** (Demo 2) se lanza solo, como con cualquier caso nuevo.

**Únete al club** (`unirseAlClub`)
- Crea un **lead** con origen **Club Drama Points**, consentimiento y fecha de consentimiento.
- El propietario es el de la cuenta "Clientes NMD".
- No duplica: si ya hay un lead con ese email y ese origen, no crea otro.
- **No pasa por la puntuación B2B** (Caliente/Templado/Frío) de la Demo 3: el Flow `NMD_Puntuar_Lead` excluye los leads con origen Club Drama Points, que quedan sin puntuación.

**Seguridad de los dos formularios**
- La clase usa `without sharing` y modo sistema explícito, porque el invitado no tiene (ni debe tener) permisos sobre Case, Contact, Order ni Lead.
- **Nunca devuelve datos existentes**, solo el número del caso nuevo. La respuesta es la misma exista o no el email, así que no sirve para averiguar quién es cliente.
- Valida email, privacidad y tipo de drama.
- Lleva un **campo trampa** (honeypot) contra robots. No hay CAPTCHA.

## 6. Mi zona y privacidad

`NMD_PortalMiZona` filtra por el contacto del usuario **y** consulta en modo usuario (`WITH USER_MODE`).

Marta y Andrés comparten la cuenta "Clientes NMD", y los pedidos y contactos dependían de la cuenta ("controlado por principal"). **Un cliente podía ver los pedidos del otro.** El test `aislamientoEntreClientesDeLaMismaCuenta` lo detectó. Solución:

| Objeto | Interno | Externo (portal) |
|---|---|---|
| Pedido (Order) | Lectura/escritura pública (antes: controlado por principal) | **Privado** |
| Contacto | Lectura/escritura pública (antes: controlado por principal) | **Privado** |
| Caso | Sin cambios | Privado |

- El sharing set **`NMD Clientes Beverage`** da a cada cliente sus pedidos (por contacto de facturación) y sus casos (por contacto).
- **Internamente no cambia nada:** las cuentas ya eran de lectura/escritura pública.
- Además está activado el **acceso seguro de usuarios invitados**.

## 7. Club Drama Points

| Regla | Valor (`NMD_Club_Config__mdt.General`) |
|---|---|
| Puntos por pedido entregado | 50 |
| Puntos por euro del pedido | 1 (redondeo hacia abajo) |
| Nivel Zen | desde 300 |
| Nivel Drama Free | desde 800 |

- **Flow `NMD_Club_Puntos_Pedido`:** cuando un pedido de un **socio** (`Contact.Miembro_club__c`) pasa a Entregado, guarda sus puntos en el pedido y lo marca como otorgado, para no sumarlo dos veces. Después **recalcula el total del socio sumando sus pedidos**, así no se pierden puntos si se entregan varios a la vez.
- **Nivel y puntos que faltan:** son fórmulas del contacto que leen los umbrales de la configuración.
- **Devoluciones:** en la demo no restan puntos.

**Datos de demo** (`data/nmd-beverage-demo.apex`):

| Cliente | Pedidos | Puntos | Nivel |
|---|---|---|---|
| Marta | 2 de botellas entregados + su pedido 00000107 de la Demo 1 | 506 | **Zen** |
| Andrés | 3 de botellas entregados + 1 enviado | 275 | **Tranqui**, le faltan 25 para Zen |

## 8. Chat con Zen (Messaging for In-App and Web)

| Pieza | Qué es |
|---|---|
| Canal `NMD_Beverage_Web` | Chat mejorado (Web). Enruta **directamente al agente Zen**, con **Agentes NMD** como cola de reserva |
| Implementación `NMD_Beverage_Web` | Servicio integrado Web (v1), publicado |
| Marca del chat (BrandingSet) | Colores NMD y avatar, botón y logo de NMD servidos desde el recurso estático público del portal |
| Componente del portal | `experience_messaging:embeddedMessaging` en el layout común, con `deploymentName`, `siteEndpoint`, `scrt2URL` y `scrtUrl` |
| CSP | Sitio de confianza `NMD_Chat_SCRT` (`*.salesforce-scrt.com`), necesario porque el portal usa CSP estricta |
| Zen | El mismo agente de la Demo 1, con sus topics, reglas y bienvenida en español. Conexión "Chat mejorado v2" añadida |
| Omni-Channel | Flows `NMD_Omni_Chat_Zen` y `NMD_Omni_Escalado_Agentes`, configuración de enrutamiento `NMD_Mensajeria`; la cola Agentes NMD acepta sesiones de mensajería |

**Escalado a una persona:** el topic "Hablar con una persona" de Zen crea un caso High en la cola (Demo 1), y ese caso pasa por el Triaje. No se configuró la distribución en vivo de la conexión, porque para editarla hay que desactivar a Zen y el flujo de la demo no la necesita.

> **Lección:** si se coloca el componente por metadatos, no basta con `deploymentName`. El generador guarda también la URL del sitio del servicio integrado y la de SCRT. Sin `scrtUrl` el bootstrap se carga pero nunca pide su configuración, así que el botón no aparece y no hay ningún error en la consola.

## 9. Pruebas realizadas

| Prueba | Con quién / cómo | Resultado |
|---|---|---|
| Tests Apex `NMD_PortalTest` | 10 tests | 10/10 OK. Cobertura: Catálogo 100 %, Formularios 100 %, Mi zona 84 % |
| Aislamiento entre clientes de la misma cuenta | Test con dos usuarios de portal | Ninguno ve pedidos, casos ni la ficha del otro |
| Páginas y catálogo | Navegador, visitante | Las 4 botellas, sin precios ni cajas B2B. "Mi zona" redirige al login (en español) |
| Tengo un drama | Navegador, visitante | Caso con origen Web NMD Beverage, en la cola, **triado por la IA** (nivel 3, Contactar hoy) |
| Únete al club | Navegador, visitante | Lead con origen Club Drama Points, consentimiento con fecha y **sin puntuación B2B**. Un lead B2B de control (120 cajas) sigue saliendo Caliente. |
| Mi zona | Navegador, como Marta y como Andrés ("Iniciar sesión en Experiencia como usuario") | Cada uno ve **solo** sus pedidos (con estado de envío, entrega prevista e importe), sus casos y su nivel con la barra de progreso |
| Chat con Zen | Navegador, visitante, **1 conversación** | Bienvenida en español con avatar NMD. Consulta de pedido verificada con número y email. Escalado: caso High vinculado al cliente y al pedido, triado (nivel 3) |
| NMD Care | Navegador, Agente Humano NMD | El caso escalado aparece con prioridad, nivel de drama y la tarea "Contactar hoy" del triaje |

- **Conversaciones de Messaging usadas:** 1 de 10.
- **Llamadas a la IA del triaje:** 2.
- Todos los registros de prueba (casos, tareas, lead y sesión de chat) se borraron.

## 10. Cómo desplegarla en otra org

1. **Activar Digital Experiences** (`settings/Communities`, irreversible) y crear el sitio:
   `sf community create --name "NMD Beverage" --template-name "Build Your Own (LWR)" --url-path-prefix nmdbeverage`
2. **Desplegar `force-app`.**
   - En `networks/NMD Beverage.network-meta.xml` el remitente es un marcador (`remitente@ejemplo.invalid`). Sustitúyelo por un email verificado antes de desplegar.
   - Revisa las URL de dominio de tu org en el componente de chat (`siteEndpoint`, `scrt2URL`, `scrtUrl`), en la marca del chat y en `NMD_Chat_SCRT`.
3. **Crear el canal de Chat mejorado en Setup.** Hay que aceptar los términos de Salesforce. Enrútalo al agente de servicio Zen con la cola Agentes NMD.
4. **Cargar los datos:**
   - `sf apex run --file data/nmd-beverage-demo.apex`
   - `sf apex run --file data/nmd-clientes-portal.apex`
5. **Publicar el sitio:** `sf community publish --name "NMD Beverage"`.
6. **Para limpiar:** `data/nmd-beverage-cleanup.apex`. Los usuarios de portal no se pueden borrar, solo desactivar.

## 11. Lecciones

- **Desde la API 67, Apex usa modo usuario por defecto.** El código que tiene que funcionar para el invitado necesita `WITH SYSTEM_MODE` / `AccessLevel.SYSTEM_MODE` explícitos, y justificados en un comentario.
- **La licencia de invitado no admite `Product2`.** Hay que publicar una copia propia del catálogo.
- **Perfiles estándar de comunidad:** no se pueden usar para crear usuarios salvo que se active una opción. Mejor un perfil propio.
- **Cuenta compartida entre particulares:** con "controlado por principal" un cliente ve los datos de otro. Hay que poner el acceso externo privado y usar sharing sets. Un test lo detectó antes de llegar al navegador.
- **Rutas personalizadas de LWR:** su identificador termina en `__c`.
- **CSS en LWR:** la plantilla tiene una regla global `a:link:not(...)` más específica que las clases normales. Hay que añadir `:link` y `:visited` a los selectores de botones y enlaces.
- **Apex no distingue mayúsculas:** otra vez, una constante `EMAIL` chocó con un parámetro `email`.
