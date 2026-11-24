// =====================================================================
// No More Drama (NMD) - Datos de demo de NMD Beverage / club Drama Points (Demo 5)
// Hace socios del club a los 2 particulares de la cuenta "Clientes NMD"
// (Marta López Fuentes y Andrés Prieto Calvo) y les crea pedidos de botellas:
//   - Andrés: 3 pedidos entregados (~275 puntos, cerca de pasar a Zen) y 1 enviado.
//   - Marta: 2 pedidos entregados; con su pedido entregado de la Demo 1
//     (00000107, 245 €) pasa a Zen.
// Los pedidos se crean Pendientes y después se marcan como Entregados, para
// que el Flow NMD_Club_Puntos_Pedido sume los puntos igual que en la vida real.
// El pedido 00000107 se "toca" para que sume sus puntos (no cambia nada más).
//
// Ejecutar:  sf apex run --file data/nmd-beverage-demo.apex --target-org nmd-dev
// Limpiar:   data/nmd-beverage-cleanup.apex
// Requiere:  datos de demo de la Demo 1 (data/nmd-demo-data.apex).
// =====================================================================

final String MARCA = 'Club Drama Points demo';
if (![SELECT Id FROM Order WHERE Name = :MARCA LIMIT 1].isEmpty()) {
    System.debug(LoggingLevel.INFO, 'NMD Beverage: los pedidos de demo ya existen. Ejecuta antes data/nmd-beverage-cleanup.apex.');
    return;
}
Map<String, Contact> socios = new Map<String, Contact>();
for (Contact c : [SELECT Id, AccountId, Email FROM Contact
                  WHERE Email IN ('marta.lopez@example.com', 'andres.prieto@example.com') AND Account.Name = 'Clientes NMD']) {
    c.Miembro_club__c = true;
    socios.put(c.Email, c);
}
update socios.values();

Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
Map<String, PricebookEntry> precios = new Map<String, PricebookEntry>();
for (PricebookEntry pe : [SELECT Id, ProductCode, UnitPrice FROM PricebookEntry
                          WHERE Pricebook2Id = :pb.Id AND ProductCode IN ('NMD-BEV-001', 'NMD-BEV-002', 'NMD-BEV-003', 'NMD-BEV-004')]) {
    precios.put(pe.ProductCode, pe);
}
Date hoy = Date.today();

// email, días desde el pedido, estado final, líneas (código:cantidad)
List<List<Object>> defs = new List<List<Object>>{
    new List<Object>{ 'andres.prieto@example.com', 75, 'Entregado', 'NMD-BEV-001:24' },
    new List<Object>{ 'andres.prieto@example.com', 40, 'Entregado', 'NMD-BEV-002:12,NMD-BEV-004:12' },
    new List<Object>{ 'andres.prieto@example.com', 18, 'Entregado', 'NMD-BEV-003:12' },
    new List<Object>{ 'andres.prieto@example.com', 2, 'Enviado', 'NMD-BEV-001:12' },
    new List<Object>{ 'marta.lopez@example.com', 55, 'Entregado', 'NMD-BEV-002:24' },
    new List<Object>{ 'marta.lopez@example.com', 25, 'Entregado', 'NMD-BEV-001:12,NMD-BEV-003:12' }
};
List<Order> pedidos = new List<Order>();
for (List<Object> d : defs) {
    Contact c = socios.get((String) d[0]);
    Integer dias = (Integer) d[1];
    pedidos.add(new Order(
        Name = MARCA, AccountId = c.AccountId, BillToContactId = c.Id, Pricebook2Id = pb.Id,
        EffectiveDate = hoy.addDays(-dias), Status = 'Draft', Estado_envio__c = 'Pendiente',
        Fecha_prevista_entrega__c = hoy.addDays(-dias + 4)));
}
insert pedidos;

List<OrderItem> lineas = new List<OrderItem>();
for (Integer i = 0; i < defs.size(); i++) {
    for (String l : ((String) defs[i][3]).split(',')) {
        PricebookEntry pe = precios.get(l.substringBefore(':'));
        lineas.add(new OrderItem(OrderId = pedidos[i].Id, PricebookEntryId = pe.Id,
                                 Quantity = Integer.valueOf(l.substringAfter(':')), UnitPrice = pe.UnitPrice));
    }
}
insert lineas;

// Pasan a su estado final: los Entregados suman puntos (Flow NMD_Club_Puntos_Pedido)
for (Integer i = 0; i < defs.size(); i++) {
    pedidos[i].Status = 'Activated';
    pedidos[i].Estado_envio__c = (String) defs[i][2];
}
update pedidos;

// Pedido entregado de Marta de la Demo 1: se guarda sin cambios para que sume sus puntos
update [SELECT Id FROM Order WHERE BillToContactId = :socios.get('marta.lopez@example.com').Id
        AND Estado_envio__c = 'Entregado' AND Puntos_otorgados__c = false];

for (Contact c : [SELECT Name, Drama_Points__c, Nivel_club__c, Puntos_siguiente_nivel__c FROM Contact WHERE Id IN :socios.values()]) {
    System.debug(LoggingLevel.INFO, 'NMD Beverage: ' + c.Name + ' -> ' + c.Drama_Points__c + ' puntos, nivel ' + c.Nivel_club__c
        + ', faltan ' + c.Puntos_siguiente_nivel__c);
}
