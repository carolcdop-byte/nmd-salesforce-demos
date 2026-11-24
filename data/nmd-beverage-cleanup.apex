// =====================================================================
// No More Drama (NMD) - Borra los datos de demo de NMD Beverage (Demo 5)
// Borra los pedidos de botellas del club (Nombre "Club Drama Points demo"),
// quita los puntos y la marca de socio a Marta y Andrés y devuelve el
// pedido 00000107 de la Demo 1 a su estado anterior (sin puntos).
// También borra los casos y leads de prueba del portal (origen
// "Web NMD Beverage" y "Club Drama Points") con email @example.com.
// Los usuarios de portal no se pueden borrar: desactívalos en Setup si hace falta.
//
// Ejecutar:  sf apex run --file data/nmd-beverage-cleanup.apex --target-org nmd-dev
// =====================================================================
List<Order> pedidos = [SELECT Id FROM Order WHERE Name = 'Club Drama Points demo'];
for (Order o : pedidos) {
    o.Status = 'Draft'; // los pedidos activados no se pueden borrar
}
update pedidos;
delete pedidos;

List<Order> demo1 = [SELECT Id FROM Order WHERE Puntos_otorgados__c = true];
for (Order o : demo1) {
    o.Puntos_otorgados__c = false;
    o.Drama_Points__c = null;
}
update demo1;

List<Contact> socios = [SELECT Id FROM Contact WHERE Miembro_club__c = true];
for (Contact c : socios) {
    c.Miembro_club__c = false;
    c.Drama_Points__c = null;
}
update socios;

List<Case> casos = [SELECT Id FROM Case WHERE Origin = 'Web NMD Beverage' AND SuppliedEmail LIKE '%@example.com'];
delete casos;
List<Lead> leads = [SELECT Id FROM Lead WHERE LeadSource = 'Club Drama Points' AND Email LIKE '%@example.com'];
delete leads;

System.debug(LoggingLevel.INFO, 'NMD Beverage: borrados ' + pedidos.size() + ' pedidos, ' + casos.size() + ' casos y ' + leads.size()
    + ' leads; ' + demo1.size() + ' pedidos sin puntos y ' + socios.size() + ' socios dados de baja.');
