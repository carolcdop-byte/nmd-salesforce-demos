# NMD Salesforce Demos

Portfolio de **Carol de Oliveira** (Salesforce Business Analyst y Product Owner): cinco demos construidas en una
Developer Edition con Salesforce DX, Git y Claude Code, con la marca **No More Drama (NMD)**.

> **No More Drama (NMD) es mi marca de consultoría Salesforce. NMD Beverage, NMD Clinic y NMD Care son empresas ficticias creadas para estas demos; todos los datos son inventados.**

Web: https://carolcdop-byte.github.io

| Demo | Qué es | README |
|---|---|---|
| 1 · NMD Care | Atención al cliente con un agente de Agentforce (Zen) que consulta pedidos, gestiona devoluciones y escala a una persona | [docs/demo-1-nmd-care](docs/demo-1-nmd-care/README.md) |
| 2 · Triaje NMD | La IA detecta el nivel de drama de cada caso, unas reglas en Flow deciden el camino y los agentes actúan | [docs/demo-2-drama-detector](docs/demo-2-drama-detector/README.md) |
| 3 · NMD Distribución | Ventas B2B de lead a pedido: puntuación, proceso propio, presupuestos con descuento por volumen y aprobación | [docs/demo-3-nmd-distribucion](docs/demo-3-nmd-distribucion/README.md) |
| 4 · NMD Clinic | Visita médica y compliance con plataforma estándar: HCP/HCO, call report, muestras con límite, consentimiento y call plan | [docs/demo-4-nmd-clinic](docs/demo-4-nmd-clinic/README.md) |
| 5 · NMD Beverage | Portal público Experience Cloud con el chat de Zen, formulario con triaje, club de puntos y zona de cliente | [docs/demo-5-nmd-beverage](docs/demo-5-nmd-beverage/README.md) |

## Estructura

- `force-app/` — metadatos Salesforce (objetos, Flows, Apex, LWC, páginas, el sitio Experience Cloud…).
- `data/` — scripts de datos de demo y de limpieza (Apex anónimo).
- `docs/` — un README por demo: problema, solución, decisiones, pruebas y lecciones.
- `branding/` — marca NMD (logo, icono, ilustraciones generadas).

## Datos de la org

Los usuarios, dominios y URLs de la org original se han sustituido por marcadores (`admin@tu-org.example`,
`tuorg`, `tu-dominio`) y los IDs de registros por IDs neutros (`0N9000000000001AAA`…). Cámbialos por los de tu
org antes de desplegar; cada README explica los pasos.
