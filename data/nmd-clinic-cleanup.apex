// =====================================================================
// No More Drama (NMD) - Borra los datos de demo de NMD Clinic (Demo 4)
// Borra muestras, visitas, HCP (Nº de colegiado NMD-DEMO-*) y HCO
// (descripción "NMD Clinic demo"). Mantiene el catálogo de kits y la
// delegada.
//
// Ejecutar:  sf apex run --file data/nmd-clinic-cleanup.apex --target-org nmd-dev
// =====================================================================
List<Contact> hcps = [SELECT Id FROM Contact WHERE Numero_colegiado__c LIKE 'NMD-DEMO-%'];
List<Visita__c> visitas = [SELECT Id FROM Visita__c WHERE HCP__c IN :hcps];
List<Muestra_entregada__c> muestras = [SELECT Id FROM Muestra_entregada__c WHERE Visita__c IN :visitas];
// Description es texto largo y no se puede filtrar en SOQL: se filtra aquí
List<Account> hcos = new List<Account>();
for (Account a : [SELECT Id, Description FROM Account WHERE RecordType.DeveloperName = 'HCO']) {
    if (a.Description == 'NMD Clinic demo') {
        hcos.add(a);
    }
}
delete muestras;
delete visitas;
delete hcps;
delete hcos;
System.debug(LoggingLevel.INFO, 'NMD Clinic: borrados ' + muestras.size() + ' muestras, ' + visitas.size() + ' visitas, '
    + hcps.size() + ' HCP y ' + hcos.size() + ' HCO.');
