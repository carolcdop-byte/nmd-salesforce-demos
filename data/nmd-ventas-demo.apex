// =====================================================================
// No More Drama (NMD) - Datos de demo de NMD Distribución (Demo 3)
// 4 productos por caja (24 botellas) con precio en el Standard Price Book,
// 10 leads (3 convertidos), 6 oportunidades del tipo de registro
// Distribución (una por etapa + una perdida), 3 presupuestos:
//   - Propuesta:   60 cajas  -> tramo 5 % (sincronizado: da el importe de la oportunidad)
//   - Negociación: 160 cajas -> tramo 10 % + 8 % adicional = 18 % -> sincronizado y enviado a aprobación (pendiente)
//   - Ganada:      320 cajas -> tramo 15 %, sincronizado -> el Flow crea el pedido (Estado de envío Pendiente)
//
// Ejecutar (después de nmd-demo-data.apex y nmd-comercial.apex):
//   sf apex run --file data/nmd-ventas-demo.apex --target-org nmd-dev
//
// Idempotente: si ya hay oportunidades Distribución, no hace nada.
// Lo ejecuta la jefa de ventas (aprobadora). Propietario de leads,
// oportunidades y presupuestos: el Comercial NMD. Datos ficticios (@example.com).
// =====================================================================

final String MARCA = '[NMD demo ventas]';
Id rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Distribucion').getRecordTypeId();
if ([SELECT COUNT() FROM Opportunity WHERE RecordTypeId = :rt] > 0) {
    System.debug(LoggingLevel.INFO, 'NMD: ya hay oportunidades Distribución; no se crean datos.');
    return;
}
Id comercial = [SELECT Id FROM User WHERE Username = 'comercial.nmd@tuorg.nmd-demo.example' LIMIT 1].Id;
Id pb = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

// ---------- 0. Productos por caja (venta B2B). Los de botella (NMD-BEV-00x) se quedan para la Demo 1 ----------
Map<String, Product2> productosCaja = new Map<String, Product2>{
    'NMD-BEV-101' => new Product2(Name='Caja Lager Zen (24 x 33 cl)', ProductCode='NMD-BEV-101', Linea_de_negocio__c='Beverage', Family='Caja 24', IsActive=true,
        Description='Caja de 24 botellas de Lager Zen. Precio mayorista para hostelería.'),
    'NMD-BEV-102' => new Product2(Name='Caja IPA Sin Drama (24 x 33 cl)', ProductCode='NMD-BEV-102', Linea_de_negocio__c='Beverage', Family='Caja 24', IsActive=true,
        Description='Caja de 24 botellas de IPA Sin Drama. Precio mayorista para hostelería.'),
    'NMD-BEV-103' => new Product2(Name='Caja Stout Plan B (24 x 33 cl)', ProductCode='NMD-BEV-103', Linea_de_negocio__c='Beverage', Family='Caja 24', IsActive=true,
        Description='Caja de 24 botellas de Stout Plan B. Precio mayorista para hostelería.'),
    'NMD-BEV-104' => new Product2(Name='Caja Radler Todo Bien (24 x 33 cl)', ProductCode='NMD-BEV-104', Linea_de_negocio__c='Beverage', Family='Caja 24', IsActive=true,
        Description='Caja de 24 botellas de Radler Todo Bien. Precio mayorista para hostelería.')};
Map<String, Decimal> precioCaja = new Map<String, Decimal>{ 'NMD-BEV-101' => 36, 'NMD-BEV-102' => 42, 'NMD-BEV-103' => 45, 'NMD-BEV-104' => 33 };
for (Product2 p : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN :productosCaja.keySet()]) { productosCaja.get(p.ProductCode).Id = p.Id; }
upsert productosCaja.values();
Set<Id> conPrecio = new Set<Id>();
for (PricebookEntry e : [SELECT Product2Id FROM PricebookEntry WHERE Pricebook2Id = :pb AND Product2Id IN :productosCaja.values()]) { conPrecio.add(e.Product2Id); }
List<PricebookEntry> nuevosPrecios = new List<PricebookEntry>();
for (Product2 p : productosCaja.values()) {
    if (!conPrecio.contains(p.Id)) {
        nuevosPrecios.add(new PricebookEntry(Pricebook2Id=pb, Product2Id=p.Id, UnitPrice=precioCaja.get(p.ProductCode), IsActive=true));
    }
}
insert nuevosPrecios;
Map<String, PricebookEntry> pbe = new Map<String, PricebookEntry>();
for (PricebookEntry e : [SELECT Id, UnitPrice, Product2.ProductCode FROM PricebookEntry
                         WHERE Pricebook2Id = :pb AND IsActive = true AND Product2.Linea_de_negocio__c = 'Beverage']) {
    pbe.put(e.Product2.ProductCode, e);
}

final String LAGER = 'NMD-BEV-101', IPA = 'NMD-BEV-102', STOUT = 'NMD-BEV-103', RADLER = 'NMD-BEV-104'; // productos por caja

// ---------- 1. Leads ----------
List<Lead> leads = new List<Lead>{
    new Lead(FirstName='Nerea', LastName='Ortiz', Company='Chiringuito Ola Lenta', Email='nerea.ortiz@example.com', Tipo_de_negocio__c='Bar', Volumen_estimado__c=120, City='Valencia'),
    new Lead(FirstName='Bruno', LastName='Salas', Company='Festival Brisa de Verano', Email='bruno.salas@example.com', Tipo_de_negocio__c='Festival', Volumen_estimado__c=60, City='Gijón'),
    new Lead(FirstName='Elena', LastName='Rubio', Company='Bodegón Sin Prisa', Email='elena.rubio@example.com', Tipo_de_negocio__c='Restaurante', Volumen_estimado__c=35, City='Sevilla'),
    new Lead(FirstName='Óscar', LastName='Navarro', Company='Distribuciones Calma Norte', Email='oscar.navarro@example.com', Tipo_de_negocio__c='Distribuidor', Volumen_estimado__c=400, City='Bilbao'),
    new Lead(FirstName='Inés', LastName='Campos', Company='Bar El Suspiro', Email='ines.campos@example.com', Tipo_de_negocio__c='Bar', Volumen_estimado__c=15, City='Madrid'),
    new Lead(FirstName='Raúl', LastName='Herrero', Company='Terraza Buen Rollo', Email='raul.herrero@example.com', Tipo_de_negocio__c='Bar', Volumen_estimado__c=45, City='Málaga'),
    new Lead(FirstName='Sonia', LastName='Peña', Company='Restaurante Pausa', Email='sonia.pena@example.com', Tipo_de_negocio__c='Restaurante', Volumen_estimado__c=25, City='Zaragoza'),
    new Lead(FirstName='Jorge', LastName='Lozano', Company='Festival Luna Quieta', Email='jorge.lozano@example.com', Tipo_de_negocio__c='Festival', Volumen_estimado__c=150, City='Granada'),
    new Lead(FirstName='Alba', LastName='Moreno', Company='Cervecería Respira', Email='alba.moreno@example.com', Tipo_de_negocio__c='Bar', Volumen_estimado__c=80, City='Barcelona'),
    new Lead(FirstName='Pablo', LastName='Iglesias', Company='Mesón Tranquilo', Email='pablo.iglesias@example.com', Tipo_de_negocio__c='Restaurante', City='Valladolid')
};
for (Lead l : leads) { l.OwnerId = comercial; l.Description = MARCA; l.LeadSource = 'Web'; }
insert leads;

// Convertir 3 leads (Chiringuito, Festival Brisa, Bodegón) -> cuenta, contacto y oportunidad Distribución
String estadoConvertido = [SELECT ApiName FROM LeadStatus WHERE IsConverted = true LIMIT 1].ApiName;
List<Database.LeadConvert> conversiones = new List<Database.LeadConvert>();
for (Integer i = 0; i < 3; i++) {
    Database.LeadConvert lc = new Database.LeadConvert();
    lc.setLeadId(leads[i].Id);
    lc.setConvertedStatus(estadoConvertido);
    lc.setOwnerId(comercial);
    lc.setOpportunityName('NMD Distribución - ' + leads[i].Company);
    conversiones.add(lc);
}
List<Database.LeadConvertResult> res = Database.convertLead(conversiones);
List<Id> oppsConvertidas = new List<Id>();
List<Account> cuentasConvertidas = new List<Account>();
for (Database.LeadConvertResult r : res) {
    oppsConvertidas.add(r.getOpportunityId());
    cuentasConvertidas.add(new Account(Id = r.getAccountId(), Description = MARCA));
}
update cuentasConvertidas;

// ---------- 2. Oportunidades ----------
List<Opportunity> conv = [SELECT Id, Name FROM Opportunity WHERE Id IN :oppsConvertidas ORDER BY Name];
// Orden por nombre: Bodegón, Chiringuito, Festival Brisa
Map<String, String> etapaConv = new Map<String, String>{
    'NMD Distribución - Bodegón Sin Prisa' => 'Cerrada perdida',
    'NMD Distribución - Chiringuito Ola Lenta' => 'Cata',
    'NMD Distribución - Festival Brisa de Verano' => 'Prospección'};
for (Opportunity o : conv) {
    o.RecordTypeId = rt; o.StageName = etapaConv.get(o.Name); o.Pricebook2Id = pb;
    o.CloseDate = Date.today().addDays(o.StageName == 'Cerrada perdida' ? -10 : 30);
    if (o.StageName == 'Cerrada perdida') { o.Description = 'Perdida por precio: ya trabajan con otra marca local. Seguimiento en 3 meses.'; }
}
update conv;

Map<String, Account> cuentas = new Map<String, Account>();
for (Account a : [SELECT Id, Name, (SELECT Id FROM Contacts ORDER BY CreatedDate LIMIT 1) FROM Account
                  WHERE Name IN ('Gastrobar Sin Prisas', 'Festival Norte Tranquilo', 'Taberna El Respiro')]) {
    cuentas.put(a.Name, a);
}
Opportunity oPropuesta = new Opportunity(Name='NMD Distribución - Gastrobar Sin Prisas', AccountId=cuentas.get('Gastrobar Sin Prisas').Id,
    StageName='Propuesta', CloseDate=Date.today().addDays(20));
Opportunity oNegociacion = new Opportunity(Name='NMD Distribución - Festival Norte Tranquilo', AccountId=cuentas.get('Festival Norte Tranquilo').Id,
    StageName='Negociación', CloseDate=Date.today().addDays(10));
Opportunity oGanada = new Opportunity(Name='NMD Distribución - Taberna El Respiro', AccountId=cuentas.get('Taberna El Respiro').Id,
    StageName='Negociación', CloseDate=Date.today());
List<Opportunity> nuevas = new List<Opportunity>{ oPropuesta, oNegociacion, oGanada };
for (Opportunity o : nuevas) { o.RecordTypeId = rt; o.OwnerId = comercial; o.Pricebook2Id = pb; }
insert nuevas;

// ---------- 3. Presupuestos (los Flows aplican los tramos al crear las líneas) ----------
Quote q1 = new Quote(Name='Presupuesto Gastrobar Sin Prisas', OpportunityId=oPropuesta.Id, Pricebook2Id=pb,
    ContactId=cuentas.get('Gastrobar Sin Prisas').Contacts[0].Id, OwnerId=comercial, ExpirationDate=Date.today().addDays(30));
Quote q2 = new Quote(Name='Presupuesto Festival Norte Tranquilo', OpportunityId=oNegociacion.Id, Pricebook2Id=pb,
    ContactId=cuentas.get('Festival Norte Tranquilo').Contacts[0].Id, OwnerId=comercial, ExpirationDate=Date.today().addDays(15));
Quote q3 = new Quote(Name='Presupuesto Taberna El Respiro', OpportunityId=oGanada.Id, Pricebook2Id=pb,
    ContactId=cuentas.get('Taberna El Respiro').Contacts[0].Id, OwnerId=comercial, ExpirationDate=Date.today().addDays(15));
insert new List<Quote>{ q1, q2, q3 };

QuoteLineItem linea(Quote q, String codigo, Integer cajas, Decimal adicional) {
    return new QuoteLineItem(QuoteId=q.Id, PricebookEntryId=pbe.get(codigo).Id, Quantity=cajas,
                             UnitPrice=pbe.get(codigo).UnitPrice, Descuento_adicional__c=adicional);
}
insert new List<QuoteLineItem>{
    linea(q1, LAGER, 40, 0), linea(q1, IPA, 20, 0),                 // 60 cajas -> 5 %
    linea(q2, RADLER, 100, 8), linea(q2, LAGER, 60, 8),             // 160 cajas -> 10 % + 8 % = 18 %
    linea(q3, LAGER, 200, 0), linea(q3, STOUT, 80, 0), linea(q3, IPA, 40, 0)  // 320 cajas -> 15 %
};

// Importes: las oportunidades con presupuesto lo sincronizan; el resto lleva un importe estimado
update new List<Opportunity>{ new Opportunity(Id=oPropuesta.Id, SyncedQuoteId=q1.Id), new Opportunity(Id=oNegociacion.Id, SyncedQuoteId=q2.Id) };
Map<String, Decimal> estimado = new Map<String, Decimal>{ 'Prospección' => 3600, 'Cata' => 4200, 'Cerrada perdida' => 1500 };
for (Opportunity o : conv) { o.Amount = estimado.get(o.StageName); }
update conv;

// q1 presentado; q2 a aprobación (lo envía el comercial, lo aprueba su Manager)
update new Quote(Id=q1.Id, Status='Presentado');
Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
req.setObjectId(q2.Id);
req.setSubmitterId(comercial);
req.setComments('Festival con 160 cajas: piden un 8 % extra por ser la primera temporada.');
Approval.process(req);

// q3 aceptado y sincronizado; al ganar la oportunidad, el Flow crea el pedido
update new Quote(Id=q3.Id, Status='Aceptado');
update new Opportunity(Id=oGanada.Id, SyncedQuoteId=q3.Id);
update new Opportunity(Id=oGanada.Id, StageName='Cerrada ganada');

Order pedido = [SELECT OrderNumber, Estado_envio__c, (SELECT Id FROM OrderItems) FROM Order WHERE Oportunidad__c = :oGanada.Id LIMIT 1];
System.debug(LoggingLevel.INFO, 'NMD: leads=' + leads.size() + ' (3 convertidos), oportunidades=6, presupuestos=3, pedido '
    + pedido.OrderNumber + ' (' + pedido.Estado_envio__c + ', ' + pedido.OrderItems.size() + ' líneas).');
