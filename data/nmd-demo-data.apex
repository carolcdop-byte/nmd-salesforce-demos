// =====================================================================
// No More Drama (NMD) - Datos de demo para el portfolio
// Crea 130 registros: 6 productos, 6 precios (Standard Price Book),
// 8 cuentas, 20 contactos, 25 pedidos, 50 líneas y 15 casos.
//
// Ejecutar:  sf apex run --file data/nmd-demo-data.apex --target-org nmd-dev
// Limpiar:   sf apex run --file data/nmd-cleanup.apex   --target-org nmd-dev
//
// Idempotente: si ya existen productos con código NMD-*, no hace nada.
// Las fechas son relativas a hoy, así que los estados de envío siempre
// son coherentes con las fechas, sea cual sea el día de ejecución.
// Requiere: campos Product2.Linea_de_negocio__c, Order.Estado_envio__c,
// Order.Fecha_prevista_entrega__c y los valores NMD de Case.Type.
// =====================================================================

if (![SELECT Id FROM Product2 WHERE ProductCode LIKE 'NMD-%' LIMIT 1].isEmpty()) {
    System.debug(LoggingLevel.WARN, 'NMD: los datos de demo ya existen. Ejecuta nmd-cleanup.apex antes de volver a cargarlos.');
    return;
}

Date hoy = Date.today();

// ---------- 1. Standard Price Book (debe estar activo) ----------
Pricebook2 stdPb = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
if (!stdPb.IsActive) {
    stdPb.IsActive = true;
    update stdPb;
}

// ---------- 2. Productos + precios ----------
// {nombre, código, línea, precio, descripción}
List<List<Object>> prodDefs = new List<List<Object>>{
    new List<Object>{'Lager Zen', 'NMD-BEV-001', 'Beverage', 1.90, 'Lager suave y equilibrada, 4,5 % vol. Botella 33 cl. Para beber sin dramas.'},
    new List<Object>{'IPA Sin Drama', 'NMD-BEV-002', 'Beverage', 2.40, 'India Pale Ale con lúpulo cítrico y amargor amable, 6 % vol. Botella 33 cl.'},
    new List<Object>{'Stout Plan B', 'NMD-BEV-003', 'Beverage', 2.60, 'Stout tostada con notas de café y cacao, 5,8 % vol. Para cuando el plan A falla.'},
    new List<Object>{'Radler Todo Bien', 'NMD-BEV-004', 'Beverage', 1.70, 'Cerveza con limón natural, 2,5 % vol. Lata 33 cl. Todo bien, de verdad.'},
    new List<Object>{'Kit Detox Digital 7 días', 'NMD-CLI-001', 'Clinic', 29.00, 'Programa guiado de 7 días para reducir el uso del móvil: guía, retos diarios y caja para el teléfono.'},
    new List<Object>{'Kit Detox Digital 30 días', 'NMD-CLI-002', 'Clinic', 79.00, 'Programa completo de 30 días con seguimiento semanal, diario de hábitos y sesiones de acompañamiento.'}
};
List<Product2> productos = new List<Product2>();
for (List<Object> p : prodDefs) {
    productos.add(new Product2(
        Name = (String) p[0], ProductCode = (String) p[1], Linea_de_negocio__c = (String) p[2],
        Description = (String) p[4], IsActive = true, QuantityUnitOfMeasure = 'Each'));
}
insert productos;

List<PricebookEntry> precios = new List<PricebookEntry>();
for (Integer i = 0; i < productos.size(); i++) {
    precios.add(new PricebookEntry(Pricebook2Id = stdPb.Id, Product2Id = productos[i].Id,
        UnitPrice = (Decimal) prodDefs[i][3], IsActive = true));
}
insert precios;

// ---------- 3. Cuentas ----------
// {nombre, tipo, sector, ciudad, provincia, calle, CP, teléfono, web, descripción}
List<List<String>> accDefs = new List<List<String>>{
    new List<String>{'Bar La Desconexión', 'Customer - Direct', 'Hospitality', 'Madrid', 'Madrid', 'Calle de la Cava Baja, 14', '28005', '+00 910 000 101', 'https://ladesconexion.example.com', 'Bar de cañas en La Latina. Cliente habitual de Lager Zen e IPA Sin Drama.'},
    new List<String>{'Taberna El Respiro', 'Customer - Direct', 'Hospitality', 'Sevilla', 'Sevilla', 'Calle Feria, 32', '41003', '+00 954 000 102', 'https://elrespiro.example.com', 'Taberna tradicional en la Alameda. Pide mucha Radler en verano.'},
    new List<String>{'Restaurante Calma Chicha', 'Customer - Direct', 'Food & Beverage', 'Valencia', 'Valencia', 'Carrer de Sueca, 21', '46006', '+00 960 000 103', 'https://calmachicha.example.com', 'Restaurante de cocina mediterránea en Ruzafa. Marida Stout Plan B con postres.'},
    new List<String>{'Gastrobar Sin Prisas', 'Customer - Direct', 'Food & Beverage', 'Barcelona', 'Barcelona', 'Carrer de Blai, 9', '08004', '+00 930 000 104', 'https://sinprisas.example.com', 'Gastrobar de pinchos en Poble-sec. Rotación alta de toda la gama Beverage.'},
    new List<String>{'Festival Sonido Sereno', 'Customer - Direct', 'Entertainment', 'Benicàssim', 'Castellón', 'Recinto de Festivales, s/n', '12560', '+00 964 000 105', 'https://sonidosereno.example.com', 'Festival de música indie en julio. Pedidos grandes y concentrados en temporada.'},
    new List<String>{'Festival Norte Tranquilo', 'Customer - Direct', 'Entertainment', 'Bilbao', 'Bizkaia', 'Parque de Kobetamendi, s/n', '48002', '+00 944 000 106', 'https://nortetranquilo.example.com', 'Festival de música y bienestar. Vende cerveza y kits Detox Digital en su zona chill.'},
    new List<String>{'Distribuciones Serenas S.L.', 'Channel Partner / Reseller', 'Retail', 'Zaragoza', 'Zaragoza', 'Polígono Plaza, Calle Bari, 55', '50197', '+00 976 000 107', 'https://distribucionesserenas.example.com', 'Distribuidor mayorista para Aragón, Navarra y La Rioja. Revende toda la gama NMD.'},
    new List<String>{'Clientes NMD', 'Customer - Direct', 'Retail', 'Madrid', 'Madrid', 'Paseo de la Castellana, 100', '28046', '+00 900 000 108', 'https://nomoredrama.example.com', 'Cuenta agrupadora para clientes particulares de la tienda online NMD.'}
};
List<Account> cuentas = new List<Account>();
for (List<String> a : accDefs) {
    // La org usa picklists de país/provincia: país por código ISO; España no tiene provincias configuradas,
    // así que la provincia (a[4]) se guarda solo como referencia en la descripción.
    cuentas.add(new Account(Name = a[0], Type = a[1], Industry = a[2], BillingCity = a[3],
        BillingStreet = a[5], BillingPostalCode = a[6], BillingCountryCode = 'ES', Phone = a[7], Website = a[8],
        Description = a[9] + ' Provincia: ' + a[4] + '.'));
}
insert cuentas;

// ---------- 4. Contactos (20) ----------
// {índice cuenta, nombre, apellidos, cargo, email, móvil}
List<List<String>> conDefs = new List<List<String>>{
    new List<String>{'0', 'Lucía', 'Martín Herrera', 'Propietaria', 'lucia.martin@example.com', '+00 600 000 001'},
    new List<String>{'0', 'Javier', 'Ortega Ruiz', 'Encargado de barra', 'javier.ortega@example.com', '+00 600 000 002'},
    new List<String>{'0', 'Paula', 'Gil Moreno', 'Responsable de compras', 'paula.gil@example.com', '+00 600 000 003'},
    new List<String>{'1', 'Manuel', 'Romero Castillo', 'Propietario', 'manuel.romero@example.com', '+00 600 000 004'},
    new List<String>{'1', 'Rocío', 'Navarro Delgado', 'Encargada de sala', 'rocio.navarro@example.com', '+00 600 000 005'},
    new List<String>{'1', 'Antonio', 'Vega Márquez', 'Administración', 'antonio.vega@example.com', '+00 600 000 006'},
    new List<String>{'2', 'Carmen', 'Soler Ferrer', 'Jefa de sala', 'carmen.soler@example.com', '+00 600 000 007'},
    new List<String>{'2', 'Vicent', 'Llorens Puig', 'Chef y socio', 'vicent.llorens@example.com', '+00 600 000 008'},
    new List<String>{'3', 'Marc', 'Vidal Roca', 'Gerente', 'marc.vidal@example.com', '+00 600 000 009'},
    new List<String>{'3', 'Laia', 'Puig Serra', 'Responsable de compras', 'laia.puig@example.com', '+00 600 000 010'},
    new List<String>{'4', 'Sergio', 'Blasco Ibáñez', 'Director de producción', 'sergio.blasco@example.com', '+00 600 000 011'},
    new List<String>{'4', 'Elena', 'Ramos Pastor', 'Responsable de barras', 'elena.ramos@example.com', '+00 600 000 012'},
    new List<String>{'4', 'Hugo', 'Cano Beltrán', 'Logística', 'hugo.cano@example.com', '+00 600 000 013'},
    new List<String>{'5', 'Ane', 'Etxeberria Uriarte', 'Directora del festival', 'ane.etxeberria@example.com', '+00 600 000 014'},
    new List<String>{'5', 'Iker', 'Zubizarreta Goikoetxea', 'Coordinador de proveedores', 'iker.zubizarreta@example.com', '+00 600 000 015'},
    new List<String>{'6', 'Raúl', 'Lacasa Bernal', 'Director comercial', 'raul.lacasa@example.com', '+00 600 000 016'},
    new List<String>{'6', 'Pilar', 'Aznar Gimeno', 'Jefa de almacén', 'pilar.aznar@example.com', '+00 600 000 017'},
    new List<String>{'6', 'Diego', 'Sanz Lafuente', 'Atención al cliente', 'diego.sanz@example.com', '+00 600 000 018'},
    new List<String>{'7', 'Marta', 'López Fuentes', 'Clienta particular', 'marta.lopez@example.com', '+00 600 000 019'},
    new List<String>{'7', 'Andrés', 'Prieto Calvo', 'Cliente particular', 'andres.prieto@example.com', '+00 600 000 020'}
};
List<Contact> contactos = new List<Contact>();
for (List<String> c : conDefs) {
    Account acc = cuentas[Integer.valueOf(c[0])];
    contactos.add(new Contact(AccountId = acc.Id, FirstName = c[1], LastName = c[2], Title = c[3],
        Email = c[4], MobilePhone = c[5], MailingCity = acc.BillingCity, MailingCountryCode = 'ES'));
}
insert contactos;

// Contacto principal de cada cuenta (el primero de su lista)
Map<Id, Contact> contactoPrincipal = new Map<Id, Contact>();
for (Contact c : contactos) {
    if (!contactoPrincipal.containsKey(c.AccountId)) contactoPrincipal.put(c.AccountId, c);
}

// ---------- 5. Pedidos (25) + líneas (50) ----------
// {cuenta, días desde hoy de inicio, días desde hoy de entrega prevista, estado, estado envío,
//  producto línea 1, cantidad 1, producto línea 2, cantidad 2, nota}
// Productos: 0 Lager, 1 IPA, 2 Stout, 3 Radler, 4 Kit 7 días, 5 Kit 30 días
List<List<Object>> ordDefs = new List<List<Object>>{
    // Entregados (fecha prevista pasada)
    new List<Object>{0, -150, -146, 'Activated', 'Entregado', 0, 240, 1, 120, 'Pedido de apertura de temporada.'},
    new List<Object>{1, -140, -135, 'Activated', 'Entregado', 3, 288, 0, 144, 'Reposición para terrazas de verano.'},
    new List<Object>{4, -130, -122, 'Activated', 'Entregado', 0, 1200, 3, 960, 'Pedido principal del festival.'},
    new List<Object>{2, -110, -106, 'Activated', 'Entregado', 2, 96, 1, 72, 'Carta de maridajes de otoño.'},
    new List<Object>{6, -100, -93, 'Activated', 'Entregado', 1, 600, 2, 480, 'Stock trimestral para distribución en Aragón.'},
    new List<Object>{3, -90, -86, 'Activated', 'Entregado', 1, 144, 3, 96, 'Reposición mensual.'},
    new List<Object>{5, -85, -78, 'Activated', 'Entregado', 0, 720, 4, 40, 'Barra principal y zona chill del festival.'},
    new List<Object>{7, -60, -56, 'Activated', 'Entregado', 4, 3, 5, 2, 'Pedidos web de particulares agrupados.'},
    new List<Object>{0, -45, -41, 'Activated', 'Entregado', 1, 144, 2, 48, 'Reposición mensual.'},
    new List<Object>{6, -35, -28, 'Activated', 'Entregado', 0, 960, 5, 30, 'Primer pedido de kits Clinic para tiendas.'},
    // Retrasados (fecha prevista pasada, sin entregar)
    new List<Object>{2, -20, -15, 'Activated', 'Retrasado', 2, 120, 0, 96, 'Retraso en ruta Valencia por incidencia del transportista.'},
    new List<Object>{4, -18, -12, 'Activated', 'Retrasado', 3, 480, 1, 240, 'Bloqueado en almacén por rotura de stock de Radler.'},
    new List<Object>{7, -14, -10, 'Activated', 'Retrasado', 5, 4, 4, 2, 'Paquetería no localiza la dirección de entrega.'},
    new List<Object>{3, -12, -7, 'Activated', 'Retrasado', 1, 96, 2, 72, 'Retraso por huelga de transporte en Barcelona.'},
    new List<Object>{5, -10, -4, 'Activated', 'Retrasado', 0, 360, 5, 20, 'Pendiente de cita de descarga en el recinto.'},
    // Enviados (en tránsito, fecha prevista hoy o futura)
    new List<Object>{1, -4, 1, 'Activated', 'Enviado', 0, 144, 3, 144, 'En tránsito hacia Sevilla.'},
    new List<Object>{6, -5, 2, 'Activated', 'Enviado', 1, 480, 3, 480, 'En tránsito hacia Zaragoza.'},
    new List<Object>{0, -3, 1, 'Activated', 'Enviado', 0, 192, 3, 96, 'En tránsito hacia Madrid.'},
    new List<Object>{7, -2, 2, 'Activated', 'Enviado', 4, 5, 1, 24, 'Pedidos web en reparto.'},
    // Activados pendientes de salir del almacén
    new List<Object>{2, -1, 5, 'Activated', 'Pendiente', 2, 72, 3, 48, 'Preparando en almacén.'},
    new List<Object>{4, 0, 10, 'Activated', 'Pendiente', 0, 600, 1, 360, 'Reserva para la edición de invierno.'},
    // Borradores (aún sin confirmar)
    new List<Object>{3, 2, 9, 'Draft', 'Pendiente', 1, 120, 2, 60, 'Borrador: pendiente de confirmar cantidades.'},
    new List<Object>{5, 5, 20, 'Draft', 'Pendiente', 5, 50, 0, 480, 'Borrador: propuesta para el festival de primavera.'},
    new List<Object>{6, 3, 12, 'Draft', 'Pendiente', 2, 240, 4, 60, 'Borrador: ampliación de catálogo Clinic.'},
    new List<Object>{1, 7, 14, 'Draft', 'Pendiente', 3, 192, 1, 96, 'Borrador: pedido de Navidad.'}
};
List<Order> pedidos = new List<Order>();
for (List<Object> o : ordDefs) {
    Account acc = cuentas[(Integer) o[0]];
    pedidos.add(new Order(
        AccountId = acc.Id, Pricebook2Id = stdPb.Id, Status = 'Draft',
        EffectiveDate = hoy.addDays((Integer) o[1]),
        Fecha_prevista_entrega__c = hoy.addDays((Integer) o[2]),
        Estado_envio__c = (String) o[4],
        BillToContactId = contactoPrincipal.get(acc.Id).Id,
        ShipToContactId = contactoPrincipal.get(acc.Id).Id,
        ShippingStreet = acc.BillingStreet, ShippingCity = acc.BillingCity,
        ShippingPostalCode = acc.BillingPostalCode, ShippingCountryCode = 'ES',
        Description = (String) o[9]));
}
insert pedidos;

List<OrderItem> lineas = new List<OrderItem>();
for (Integer i = 0; i < pedidos.size(); i++) {
    List<Object> o = ordDefs[i];
    for (Integer k = 0; k < 2; k++) {
        Integer p = (Integer) o[5 + k * 2];
        lineas.add(new OrderItem(OrderId = pedidos[i].Id, PricebookEntryId = precios[p].Id,
            Product2Id = productos[p].Id, Quantity = (Integer) o[6 + k * 2], UnitPrice = precios[p].UnitPrice));
    }
}
insert lineas;

// Activar los pedidos que corresponda (no se pueden añadir líneas a un pedido ya activado)
List<Order> aActivar = new List<Order>();
for (Integer i = 0; i < pedidos.size(); i++) {
    if ((String) ordDefs[i][3] == 'Activated') aActivar.add(new Order(Id = pedidos[i].Id, Status = 'Activated'));
}
update aActivar;

Map<Id, Order> pedidosConNumero = new Map<Id, Order>([SELECT Id, OrderNumber FROM Order WHERE Id IN :pedidos]);

// ---------- 6. Casos (15) ----------
// {índice pedido (-1 = sin pedido), índice contacto, tipo, estado, prioridad, origen, asunto, descripción}
List<List<Object>> caseDefs = new List<List<Object>>{
    new List<Object>{10, 6, 'Consulta de pedido', 'Working', 'Medium', 'Phone', '¿Dónde está nuestro pedido?', 'El pedido debía llegar hace días y en la terraza ya no queda Stout Plan B. Piden fecha de entrega concreta.'},
    new List<Object>{12, 18, 'Consulta de pedido', 'New', 'Medium', 'Web', 'Seguimiento de envío sin actualizar', 'La clienta indica que el número de seguimiento no se actualiza desde hace cuatro días.'},
    new List<Object>{15, 3, 'Consulta de pedido', 'Closed', 'Low', 'Email', 'Confirmar hora de entrega', 'Piden que el reparto llegue antes de las 12:00 para no coincidir con el servicio de comidas. Confirmado con el transportista.'},
    new List<Object>{21, 8, 'Consulta de pedido', 'New', 'Low', 'Email', 'Cambio de cantidades en borrador', 'Quieren cambiar 120 IPA Sin Drama por 96 y añadir Radler antes de confirmar el pedido.'},
    new List<Object>{1, 4, 'Devolución', 'Closed', 'Medium', 'Phone', 'Devolución de cajas sobrantes de Radler', 'Sobraron 48 latas de Radler Todo Bien al acabar la temporada de terrazas. Devolución aceptada como abono.'},
    new List<Object>{7, 19, 'Devolución', 'Working', 'Low', 'Web', 'Devolver Kit Detox Digital 30 días', 'El cliente dice que no ha conseguido separarse del móvil ni un día y quiere devolver el kit. Precinto intacto.'},
    new List<Object>{9, 16, 'Devolución', 'New', 'Medium', 'Email', 'Devolución parcial de kits Clinic', 'Las tiendas no han vendido todos los kits de 30 días. Solicitan devolver 10 unidades.'},
    new List<Object>{3, 7, 'Producto defectuoso', 'Closed', 'High', 'Phone', 'Botellas de Stout sin gas', 'Un lote de Stout Plan B llegó sin carbonatación. Se sustituyen 24 botellas sin coste.'},
    new List<Object>{5, 9, 'Producto defectuoso', 'Working', 'High', 'Email', 'Etiquetas despegadas en IPA', 'Varias botellas de IPA Sin Drama llegan con la etiqueta despegada. Piden fotos al cliente para calidad.'},
    new List<Object>{6, 13, 'Producto defectuoso', 'Escalated', 'High', 'Phone', 'Caja para el móvil del Kit 7 días no cierra', 'La caja del Kit Detox Digital 7 días no cierra bien y los asistentes recuperan el móvil al momento. Escalado a proveedor.'},
    new List<Object>{8, 0, 'Producto defectuoso', 'New', 'Medium', 'Web', 'Latas abolladas en el último pedido', 'Llegaron 12 latas abolladas. Se pueden vender, pero la imagen en barra no es buena.'},
    new List<Object>{11, 10, 'Queja', 'Escalated', 'High', 'Phone', 'URGENTE: el festival se queda sin cerveza', 'El director de producción llama muy alterado: "Tenemos 40.000 personas, una ola de calor y CERO Radler. Esto es exactamente el drama que vuestra marca promete evitar". Exige entrega inmediata y una compensación.'},
    new List<Object>{13, 8, 'Queja', 'Working', 'High', 'Email', 'Inaceptable: tercer retraso este año', 'El gerente escribe en mayúsculas que es el tercer retraso del año y que "No More Drama" le está dando más drama que su exsocio. Amenaza con cambiar de proveedor si no hay solución hoy.'},
    new List<Object>{14, 14, 'Queja', 'New', 'Medium', 'Email', 'Descarga sin cita en el recinto', 'El coordinador se queja de que el transportista se presentó sin cita y no pudo descargar. Pide coordinar mejor.'},
    new List<Object>{-1, 19, 'Queja', 'Closed', 'Low', 'Web', 'El nombre de la marca no es para tanto', 'La clienta asegura que tras el Kit Detox Digital 7 días tuvo "un drama enorme" al no poder ver sus redes. Se le explica el programa y se le ofrece un descuento en el siguiente kit.'}
};
List<Case> casos = new List<Case>();
for (List<Object> c : caseDefs) {
    Integer iPed = (Integer) c[0];
    Contact con = contactos[(Integer) c[1]];
    String ref = iPed >= 0 ? ' (pedido ' + pedidosConNumero.get(pedidos[iPed].Id).OrderNumber + ')' : '';
    casos.add(new Case(AccountId = con.AccountId, ContactId = con.Id, Type = (String) c[2], Status = (String) c[3],
        Priority = (String) c[4], Origin = (String) c[5], Subject = (String) c[6] + ref, Description = (String) c[7]));
}
insert casos;

System.debug(LoggingLevel.INFO, 'NMD OK: ' + productos.size() + ' productos, ' + precios.size() + ' precios, ' +
    cuentas.size() + ' cuentas, ' + contactos.size() + ' contactos, ' + pedidos.size() + ' pedidos, ' +
    lineas.size() + ' líneas, ' + casos.size() + ' casos.');
