# Guion de vídeo — Demo 1: NMD Care con el agente Zen

**Duración:** 2 min 30 s aprox. (máximo 3 min)
**Formato:** grabación de pantalla con voz en off, en español.
**Mensaje clave:** Zen resuelve lo repetitivo con cero drama, y cuando hace falta una persona, el caso llega a la consola con todo el contexto.

---

## Preparación (antes de grabar)

- [ ] Inicia sesión en nmd-dev con tu usuario. Tienes NMD Base, así que ves la app NMD Care.
- [ ] **Pestaña 1:** Agentforce Builder con **Zen** abierto y el panel de vista previa en modo **acciones reales**, para que se creen casos de verdad.
- [ ] **Pestaña 2:** consola **NMD Care** → Casos, con una vista de lista **"Cola Agentes NMD"**. Créala desde la propia lista: Propietario del caso = Agentes NMD, ordenada por Fecha de creación descendente. Columnas: Número, Asunto, Tipo, Prioridad, Origen.
- [ ] Ten a mano los mensajes del guion para copiarlos y pegarlos. Así evitas erratas que cambien la respuesta del agente.
- [ ] Haz un ensayo completo y **borra después los casos que cree** (Casos → filtrar Origen = Agente Zen). Así el vídeo arranca con la cola limpia.
- [ ] Oculta marcadores y notificaciones del navegador. Pon el zoom al 110-125 % para que se lea bien.

---

## Escenas

| Tiempo | Pantalla | Voz en off |
|---|---|---|
| **0:00-0:15** | Consola NMD Care con la cabecera negra y las pestañas Casos, Pedidos, Cuentas y Contactos | "No More Drama vende cerveza y kits de detox digital. Su equipo de soporte recibe a diario las mismas preguntas: ¿dónde está mi pedido?, ¿cómo lo devuelvo?… y algún que otro drama. Para eso hemos creado Zen." |
| **0:15-0:25** | Agentforce Builder con Zen: los 4 topics a la vista | "Zen es un agente de Agentforce con cuatro temas: estado de pedido, devoluciones, incidencias y pasar con una persona. Cada uno usa un Flow que verifica al cliente antes de hacer nada." |

### Escena 1 — Consulta de pedido (0:25-0:55)

| Escribir en la vista previa | Qué se ve | Voz en off |
|---|---|---|
| `Hola, ¿cómo va mi pedido?` | Zen pide el número de pedido y el email | "Antes de dar ningún dato, Zen pide el número de pedido y el email de la compra." |
| `Es el 00000110 y mi email es carmen.soler@example.com` | Responde que lleva retraso, con la fecha prevista y un tono empático | "Con los datos verificados, responde con lo que dice Salesforce, sin inventar nada. Y como el pedido va con retraso, deja el humor para otro momento." |

*Opcional (+10 s):* escribe `Pues prueba con el 00000105` con el mismo email. Zen responde "no he podido verificar el pedido" sin dar ningún dato. Voz: "Si el email no coincide, no hay datos. Ni siquiera confirma si el pedido existe."

### Escena 2 — Devolución (0:55-1:20)

| Escribir | Qué se ve | Voz en off |
|---|---|---|
| `Quiero devolver el pedido 00000107, soy marta.lopez@example.com. El kit llegó con la caja abierta.` | Zen confirma la devolución y da el **número de caso** | "Para devolver, Zen comprueba que el pedido es de quien lo pide y que ya está entregado. Si todo encaja, crea el caso y da el número al momento." |

### Escena 3 — Enfado y escalado (1:20-1:50)

| Escribir | Qué se ve | Voz en off |
|---|---|---|
| `ESTOY HARTO. Tercer retraso este año con el pedido 00000113. Quiero hablar con una persona YA. Mi email es marc.vidal@example.com` | Zen responde con seriedad y empatía, sin bromas, y da el número de caso | "Cuando el cliente está enfadado o pide una persona, Zen no discute ni bromea: resume la conversación y la pasa al equipo con prioridad alta." |

👉 **Apunta el número de caso** que da Zen para la siguiente escena.

### Escena 4 — El caso llega a la consola (1:50-2:25)

| Acción | Qué se ve | Voz en off |
|---|---|---|
| Cambia a la pestaña de NMD Care → vista "Cola Agentes NMD" y actualiza | Arriba aparecen el caso de escalado (High) y la devolución, con Origen = Agente Zen | "En la consola NMD Care, el equipo humano ve los casos que crea Zen en su cola, con la prioridad ya asignada." |
| Abre el caso de escalado | Asunto "Escalado desde el Agente Zen", Prioridad High, contacto Marc Vidal y la descripción con el resumen | "Y no hace falta preguntar nada otra vez: el resumen de Zen explica qué pasa, qué se ha intentado y cómo está el cliente." |
| Abre el caso de devolución y haz clic en el campo **Pedido** | Se abre el pedido 00000107 en una subpestaña, con la lista relacionada "Casos NMD" | "Cada caso queda vinculado a su pedido, así que el agente humano tiene todo el contexto a un clic." |

### Cierre (2:25-2:35)

| Pantalla | Voz en off |
|---|---|
| Vuelta a Zen en Agentforce Builder, o una diapositiva con: Agentforce · Agent Script · Flows · Consola Lightning | "Zen resuelve lo repetitivo, protege los datos del cliente y, cuando hace falta una persona, se la pasa con todo el contexto. Cero drama." |

---

## Después de grabar

- Borra los casos creados en la grabación (Casos → Origen = Agente Zen → los de hoy).
- Si se ha creado algún caso no previsto, revisa su asunto antes de borrarlo, por si muestra un comportamiento que haya que corregir.
