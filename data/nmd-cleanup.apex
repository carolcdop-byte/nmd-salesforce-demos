// =====================================================================
// No More Drama (NMD) - Borra SOLO los datos de demo creados por
// nmd-demo-data.apex y los casos con Origin = "Agente Zen".
// No toca metadata, usuarios ni el Standard Price Book.
//
// Ejecutar:  sf apex run --file data/nmd-cleanup.apex --target-org nmd-dev
// =====================================================================

Set<String> cuentasNmd = new Set<String>{
    'Bar La Desconexión', 'Taberna El Respiro', 'Restaurante Calma Chicha', 'Gastrobar Sin Prisas',
    'Festival Sonido Sereno', 'Festival Norte Tranquilo', 'Distribuciones Serenas S.L.', 'Clientes NMD'
};
List<Account> cuentas = [SELECT Id FROM Account WHERE Name IN :cuentasNmd];

// Casos de las cuentas NMD y todos los creados por las acciones del Agente Zen
// (estos últimos pueden no tener cuenta, p. ej. escalados con un email desconocido)
delete [SELECT Id FROM Case WHERE AccountId IN :cuentas OR Origin = 'Agente Zen'];

// Los pedidos activados no se pueden borrar: primero se devuelven a borrador
List<Order> pedidos = [SELECT Id, Status FROM Order WHERE AccountId IN :cuentas];
List<Order> aBorrador = new List<Order>();
for (Order o : pedidos) {
    if (o.Status != 'Draft') aBorrador.add(new Order(Id = o.Id, Status = 'Draft'));
}
update aBorrador;
delete pedidos; // borra también sus líneas (OrderItem)

delete [SELECT Id FROM Contact WHERE AccountId IN :cuentas];
delete cuentas;
delete [SELECT Id FROM Product2 WHERE ProductCode LIKE 'NMD-%']; // borra también sus precios

System.debug(LoggingLevel.INFO, 'NMD: datos de demo eliminados.');
