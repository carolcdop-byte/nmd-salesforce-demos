# Datos de demo — No More Drama (NMD)

Datos ficticios en español para el portfolio. Son 130 registros en total, pensados para el límite de 5 MB de una Developer Edition.

| Objeto | Nº | Contenido |
|---|---|---|
| Product2 | 6 | 4 cervezas (Beverage) y 2 kits de detox digital (Clinic), con código `NMD-*` |
| PricebookEntry | 6 | Precios en el Standard Price Book |
| Account | 8 | 6 bares, restaurantes y festivales, 1 distribuidor y la cuenta "Clientes NMD" |
| Contact | 20 | Repartidos entre las cuentas, con emails `@example.com` |
| Order | 25 | 21 activados y 4 en borrador. Estado de envío: 10 Entregado, 5 Retrasado, 4 Enviado, 6 Pendiente |
| OrderItem | 50 | 2 líneas por pedido |
| Case | 15 | Consulta de pedido, Devolución, Producto defectuoso y Queja |

## Requisitos previos

Antes de cargar los datos, la metadata de `force-app` tiene que estar desplegada:

- `Product2.Linea_de_negocio__c`
- `Order.Estado_envio__c` y `Order.Fecha_prevista_entrega__c`
- Los valores NMD de `Case.Type` (StandardValueSet `CaseType`)
- El permission set `NMD_Base`, asignado al usuario

## Uso

```bash
# Cargar los datos (si ya existen productos NMD-*, no hace nada)
sf apex run --file data/nmd-demo-data.apex --target-org nmd-dev

# Borrar solo los datos NMD
sf apex run --file data/nmd-cleanup.apex --target-org nmd-dev
```

## Usuario "Agente Humano NMD"

`nmd-agente-humano.apex` crea el usuario humano de soporte:

- Licencia Salesforce y perfil Usuario estándar.
- Service Cloud User, si hay licencia disponible.
- Permission set NMD Base y miembro de la cola "Agentes NMD".

Antes de ejecutarlo tienen que estar desplegados `NMD_Base` y `Agentes_NMD`. El email del usuario es el de quien ejecuta el script, que recibe el enlace para fijar la contraseña. El script se puede ejecutar varias veces sin duplicar nada.

```bash
sf apex run --file data/nmd-agente-humano.apex --target-org nmd-dev
```

Para usarlo en otra org, cambia `USERNAME`, porque tiene que ser único en todo Salesforce.

## Triaje inicial (Demo 2)

El triaje automático (Flow `NMD_Triaje_IA`) solo analiza los casos nuevos. Para analizar los casos abiertos que ya existían:

```bash
sf apex run --file data/nmd-triaje-inicial.apex --target-org nmd-dev   # repetir hasta que el log diga quedan=0
```

Cada caso es una llamada a la IA. Si cargas los datos de demo **después** de desplegar la Demo 2, no hace falta: cada caso nuevo lanza el triaje solo.

## Demo 3: NMD Distribución (ventas B2B)

```bash
sf apex run --file data/nmd-comercial.apex --target-org nmd-dev      # usuario Comercial NMD (Manager = quien lo ejecuta) y permission set NMD Ventas
sf apex run --file data/nmd-ventas-demo.apex --target-org nmd-dev    # 10 leads, 6 oportunidades, 3 presupuestos (1 pendiente de aprobación) y 1 pedido
sf apex run --file data/nmd-ventas-cleanup.apex --target-org nmd-dev # borra esos datos (ejecútalo antes de nmd-cleanup.apex)
```

Ejecuta `nmd-ventas-demo.apex` con la usuaria jefa de ventas: es la Manager del comercial y recibe la aprobación pendiente.

## Demo 4: NMD Clinic (visita médica y compliance)

```bash
sf apex run --file data/nmd-delegada.apex --target-org nmd-dev       # Delegada NMD Clinic (licencia Platform), roles y permission sets
sf apex run --file data/nmd-clinic-demo.apex --target-org nmd-dev    # 2 kits, 5 HCO, 12 HCP, 21 visitas y 11 muestras (51 registros)
sf apex run --file data/nmd-clinic-cleanup.apex --target-org nmd-dev # borra HCO, HCP, visitas y muestras (mantiene kits y delegada)
```

Ejecuta los scripts con la usuaria jefa de compliance y ventas: el script de la delegada le asigna su rol, y así ve todas las visitas (que son privadas). Detalle en `docs/demo-4-nmd-clinic/README.md`.

## Demo 5: NMD Beverage (portal y club Drama Points)

```bash
sf apex run --file data/nmd-beverage-demo.apex --target-org nmd-dev      # socios del club (Marta y Andrés), 6 pedidos de botellas y puntos
sf apex run --file data/nmd-clientes-portal.apex --target-org nmd-dev    # usuarios de portal de Marta y Andrés (licencia Customer Community)
sf apex run --file data/nmd-beverage-cleanup.apex --target-org nmd-dev   # borra pedidos del club, puntos y casos/leads de prueba del portal
```

Los usuarios de portal no se pueden borrar: desactívalos en Setup si hace falta. Detalle en `docs/demo-5-nmd-beverage/README.md`.

## Notas

- Las fechas de los pedidos son relativas al día de ejecución. Así, el estado de envío siempre es coherente con las fechas:
  - **Entregado** y **Retrasado**: la fecha prevista de entrega ya ha pasado.
  - **Enviado** y **Pendiente**: la fecha prevista es hoy o futura.
- El script activa el Standard Price Book si está inactivo.
- La org usa picklists de país y provincia. Por eso el país se guarda como `ES`. España no tiene provincias configuradas, así que la provincia de cada cuenta aparece en su descripción.
- Todo el script se ejecuta en una sola transacción: si algo falla, no se guarda nada.
