// =====================================================================
// No More Drama (NMD) - Datos de demo de NMD Clinic (Demo 4)
// Crea 2 kits de muestra (catálogo enlazado a los productos Clinic),
// 5 HCO, 12 HCP, ~21 visitas y 11 muestras entregadas. Todo (salvo el
// catálogo) es propiedad de la Delegada NMD Clinic.
//   - 2 HCP sin consentimiento RGPD (Sara Gil y Tomás Vidal).
//   - 1 HCP a 9 de 10 muestras este año (Lucía Herrera).
//   - 3 visitas planificadas para hoy; el resto, pasadas o próximas.
// Las fechas son relativas a hoy, así que la demo funciona cualquier día
// (las visitas "del año" se ajustan para no salir del año en curso).
//
// Ejecutar:  sf apex run --file data/nmd-clinic-demo.apex --target-org nmd-dev
// Requiere:  data/nmd-delegada.apex ejecutado antes.
// Limpiar:   data/nmd-clinic-cleanup.apex
// =====================================================================

final String USUARIO_DELEGADA = 'delegada.clinic@tuorg.nmd-demo.example';
final String MARCA = 'NMD Clinic demo';

if (![SELECT Id FROM Contact WHERE Numero_colegiado__c LIKE 'NMD-DEMO-%' LIMIT 1].isEmpty()) {
    System.debug(LoggingLevel.INFO, 'NMD: los datos de demo de NMD Clinic ya existen. Ejecuta antes data/nmd-clinic-cleanup.apex.');
    return;
}
Id delegada = [SELECT Id FROM User WHERE Username = :USUARIO_DELEGADA LIMIT 1].Id;
Id rtHco = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HCO').getRecordTypeId();
Id rtHcp = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('HCP').getRecordTypeId();
Date hoy = Date.today();
Date inicioAno = Date.newInstance(hoy.year(), 1, 1);

// ---------- Catálogo de kits (enlazado a los productos Clinic) ----------
Map<String, Kit_de_muestra__c> kits = new Map<String, Kit_de_muestra__c>();
for (Kit_de_muestra__c k : [SELECT Id, Codigo__c FROM Kit_de_muestra__c WHERE Codigo__c IN ('NMD-CLI-001', 'NMD-CLI-002')]) {
    kits.put(k.Codigo__c, k);
}
List<Kit_de_muestra__c> nuevosKits = new List<Kit_de_muestra__c>();
for (Product2 p : [SELECT Id, Name, ProductCode FROM Product2 WHERE ProductCode IN ('NMD-CLI-001', 'NMD-CLI-002')]) {
    if (!kits.containsKey(p.ProductCode)) {
        Kit_de_muestra__c k = new Kit_de_muestra__c(Name = p.Name, Codigo__c = p.ProductCode, Producto__c = p.Id, Activo__c = true);
        kits.put(p.ProductCode, k);
        nuevosKits.add(k);
    }
}
insert nuevosKits;
Id kit7 = kits.get('NMD-CLI-001').Id;
Id kit30 = kits.get('NMD-CLI-002').Id;

// ---------- HCO ----------
List<Account> hcos = new List<Account>{
    new Account(Name = 'Clínica Serena', Tipo_de_centro__c = 'Clínica', BillingCity = 'Madrid'),
    new Account(Name = 'Hospital Mente Sana', Tipo_de_centro__c = 'Hospital', BillingCity = 'Madrid'),
    new Account(Name = 'Consulta Ruiz Psicología', Tipo_de_centro__c = 'Consulta privada', BillingCity = 'Valencia'),
    new Account(Name = 'Centro de Salud Las Letras', Tipo_de_centro__c = 'Centro de salud', BillingCity = 'Madrid'),
    new Account(Name = 'Clínica Equilibrio', Tipo_de_centro__c = 'Clínica', BillingCity = 'Barcelona')
};
for (Account a : hcos) {
    a.RecordTypeId = rtHco;
    a.OwnerId = delegada;
    a.Description = MARCA;
    a.BillingCountryCode = 'ES';
}
insert hcos;

// ---------- HCP ----------
// nombre, apellido, especialidad, segmento, consentimiento, HCO (índice)
List<List<Object>> defs = new List<List<Object>>{
    new List<Object>{ 'Lucía', 'Herrera', 'Psicología clínica', 'A', true, 0 },
    new List<Object>{ 'Javier', 'Molina', 'Psiquiatría', 'A', true, 1 },
    new List<Object>{ 'Marta', 'Ruiz', 'Psicología sanitaria', 'B', true, 2 },
    new List<Object>{ 'Andrés', 'Navarro', 'Medicina de familia', 'B', true, 3 },
    new List<Object>{ 'Elena', 'Castro', 'Neuropsicología', 'C', true, 1 },
    new List<Object>{ 'Pablo', 'Ortega', 'Psicología clínica', 'C', true, 4 },
    new List<Object>{ 'Sara', 'Gil', 'Pediatría', 'B', false, 3 },
    new List<Object>{ 'Tomás', 'Vidal', 'Psicología sanitaria', 'C', false, 4 },
    new List<Object>{ 'Nuria', 'Prieto', 'Psicología clínica', 'A', true, 0 },
    new List<Object>{ 'Hugo', 'Serrano', 'Psiquiatría', 'B', true, 1 },
    new List<Object>{ 'Irene', 'Lozano', 'Medicina de familia', 'C', true, 3 },
    new List<Object>{ 'Raúl', 'Méndez', 'Psicología sanitaria', 'A', true, 4 }
};
List<Contact> hcps = new List<Contact>();
Integer n = 1;
for (List<Object> d : defs) {
    Boolean consiente = (Boolean) d[4];
    String nombre = (String) d[0];
    hcps.add(new Contact(
        RecordTypeId = rtHcp, OwnerId = delegada,
        Salutation = nombre.endsWith('a') ? 'Dra.' : 'Dr.', FirstName = nombre, LastName = (String) d[1],
        Email = nombre.toLowerCase().replace('í', 'i').replace('á', 'a').replace('ú', 'u').replace('é', 'e') + '.' + ((String) d[1]).toLowerCase().replace('é', 'e') + '@example.com',
        Title = (String) d[2], Especialidad__c = (String) d[2], Segmento__c = (String) d[3],
        Numero_colegiado__c = 'NMD-DEMO-' + String.valueOf(n).leftPad(3, '0'),
        Consentimiento_RGPD__c = consiente, Fecha_consentimiento__c = consiente ? hoy.addMonths(-8) : null,
        AccountId = hcos[(Integer) d[5]].Id));
    n++;
}
insert hcps;
Map<String, Contact> hcp = new Map<String, Contact>();
for (Contact c : hcps) {
    hcp.put(c.FirstName, c);
}

// ---------- Visitas ----------
// Fechas: "dias" atrás (negativo = futuro). Las del año no bajan del 1 de enero.
List<Visita__c> visitas = new List<Visita__c>();
Map<String, Visita__c> porClave = new Map<String, Visita__c>();
List<List<Object>> vdefs = new List<List<Object>>{
    // clave, HCP, días atrás, estado, objetivo, resultado, siguiente paso
    new List<Object>{ 'L1', 'Lucía', 160, 'Realizada', 'Presentar los kits de detox digital', 'Muy interesada: lo ve útil para pacientes con uso compulsivo del móvil.', 'Dejar kits de 7 días' },
    new List<Object>{ 'L2', 'Lucía', 63, 'Realizada', 'Seguimiento tras el verano', 'Ha usado los kits con buena acogida; pide material para la sala de espera.', 'Llevar folletos' },
    new List<Object>{ 'L3', 'Lucía', 14, 'Realizada', 'Entregar folletos', 'Folletos entregados. Pregunta por el kit de 30 días.', 'Presentar el kit de 30 días' },
    new List<Object>{ 'L4', 'Lucía', 5, 'Realizada', 'Presentar el kit de 30 días', 'Interés en el kit de 30 días para grupos.', 'Concretar sesión para el equipo' },
    new List<Object>{ 'L5', 'Lucía', 0, 'Planificada', 'Sesión informativa para el equipo de la clínica', null, null },
    new List<Object>{ 'J1', 'Javier', 12, 'Realizada', 'Primera visita', 'Escéptico, pide evidencia y datos de uso.', 'Enviar resumen de resultados' },
    new List<Object>{ 'J2', 'Javier', 0, 'Planificada', 'Llevar resumen de resultados', null, null },
    new List<Object>{ 'M1', 'Marta', 70, 'Realizada', 'Presentación', 'Interesada en el kit de 7 días.', 'Volver en noviembre' },
    new List<Object>{ 'M2', 'Marta', 7, 'Realizada', 'Seguimiento', 'Ha recomendado el kit a dos compañeras.', 'Invitar al webinar de diciembre' },
    new List<Object>{ 'A1', 'Andrés', 28, 'Realizada', 'Presentación en el centro de salud', 'Poco tiempo; acepta información por email.', 'Visitar en diciembre' },
    new List<Object>{ 'E1', 'Elena', 40, 'Realizada', 'Presentación', 'Interesada para adolescentes; consulta a su equipo.', 'Llamar en enero' },
    new List<Object>{ 'P1', 'Pablo', 84, 'Realizada', 'Presentación', 'Interesado, pero sin tiempo este trimestre.', 'Visitar en el próximo trimestre' },
    new List<Object>{ 'S1', 'Sara', 0, 'Planificada', 'Primera visita: pedir el consentimiento RGPD', null, null },
    new List<Object>{ 'T1', 'Tomás', 46, 'Cancelada', 'Primera visita', null, 'Reprogramar y pedir el consentimiento RGPD' },
    new List<Object>{ 'N1', 'Nuria', 13, 'Realizada', 'Presentación', 'Muy interesada.', 'Dejar más kits en la próxima visita' },
    new List<Object>{ 'N2', 'Nuria', 3, 'Realizada', 'Seguimiento', 'Le quedan pocos kits; pide de 30 días.', 'Revisar stock en diciembre' },
    new List<Object>{ 'H1', 'Hugo', 11, 'Realizada', 'Presentación en el hospital', 'Lo derivará a la unidad de adicciones.', 'Contactar con la unidad' },
    new List<Object>{ 'I1', 'Irene', -7, 'Planificada', 'Primera visita', null, null },
    new List<Object>{ 'R1', 'Raúl', 33, 'Realizada', 'Presentación', 'Interesado en el kit de 7 días.', 'Volver en dos semanas' },
    new List<Object>{ 'R2', 'Raúl', 20, 'Realizada', 'Seguimiento', 'Pide datos de resultados.', 'Llevar datos en noviembre' },
    new List<Object>{ 'R3', 'Raúl', -3, 'Planificada', 'Llevar datos de resultados', null, null }
};
Integer h = 9;
for (List<Object> d : vdefs) {
    Contact c = hcp.get((String) d[1]);
    Integer dias = (Integer) d[2];
    Date f = hoy.addDays(-dias);
    if (dias > 0 && f < inicioAno) {
        f = inicioAno.addDays(Math.mod(dias, 20)); // a principios de año, la demo no sale del año en curso
    }
    if (dias > 0 && f >= hoy) {
        f = hoy.addDays(-1);
    }
    Visita__c v = new Visita__c(
        OwnerId = delegada, HCP__c = c.Id, HCO__c = c.AccountId, Fecha__c = f,
        Hora__c = Time.newInstance(h, 30, 0, 0), Estado__c = (String) d[3], Objetivo__c = (String) d[4],
        Resultado__c = (String) d[5], Siguiente_paso__c = (String) d[6]);
    h = h == 17 ? 9 : h + 1;
    visitas.add(v);
    porClave.put((String) d[0], v);
}
insert visitas;

// ---------- Muestras (solo en visitas realizadas a HCP con consentimiento) ----------
List<Muestra_entregada__c> muestras = new List<Muestra_entregada__c>();
List<List<Object>> mdefs = new List<List<Object>>{
    new List<Object>{ 'L1', kit7, 3 }, new List<Object>{ 'L2', kit7, 3 }, new List<Object>{ 'L3', kit30, 3 }, // Lucía: 9 de 10
    new List<Object>{ 'J1', kit7, 1 }, new List<Object>{ 'M2', kit7, 2 }, new List<Object>{ 'E1', kit7, 1 },
    new List<Object>{ 'P1', kit30, 2 }, new List<Object>{ 'N1', kit7, 2 }, new List<Object>{ 'N2', kit30, 1 },
    new List<Object>{ 'H1', kit7, 2 }, new List<Object>{ 'R1', kit7, 2 }
};
for (List<Object> d : mdefs) {
    muestras.add(new Muestra_entregada__c(Visita__c = porClave.get((String) d[0]).Id, Kit__c = (Id) d[1], Cantidad__c = (Integer) d[2]));
}
insert muestras;

System.debug(LoggingLevel.INFO, 'NMD Clinic demo: ' + nuevosKits.size() + ' kits nuevos, ' + hcos.size() + ' HCO, ' + hcps.size() + ' HCP, '
    + visitas.size() + ' visitas, ' + muestras.size() + ' muestras.');
