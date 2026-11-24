// =====================================================================
// No More Drama (NMD) - Borra los datos de demo de NMD Distribución
// Pedidos creados desde oportunidades, oportunidades Distribución (con sus
// presupuestos), leads de demo (con Tipo de negocio y email @example.com)
// y las cuentas/contactos creados al convertirlos.
//
// Ejecutar:  sf apex run --file data/nmd-ventas-cleanup.apex --target-org nmd-dev
// Ejecútalo ANTES de nmd-cleanup.apex si vas a borrar todo.
// =====================================================================

Id rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Distribucion').getRecordTypeId();

List<Order> pedidos = [SELECT Id FROM Order WHERE Oportunidad__c != null];
delete pedidos; // borra también sus líneas
List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordTypeId = :rt];
for (ProcessInstanceWorkitem wi : [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObject.Type = 'Quote']) {
    Approval.ProcessWorkitemRequest r = new Approval.ProcessWorkitemRequest();
    r.setWorkitemId(wi.Id); r.setAction('Removed');
    Approval.process(r); // retira aprobaciones pendientes para poder borrar
}
delete opps; // borra también presupuestos y líneas
// Leads de demo: tienen Tipo de negocio y email @example.com. Sus cuentas convertidas también se borran.
List<Lead> leads = [SELECT Id, ConvertedAccountId FROM Lead WHERE Tipo_de_negocio__c != null AND Email LIKE '%@example.com'];
Set<Id> idsCuentas = new Set<Id>();
for (Lead l : leads) { if (l.ConvertedAccountId != null) idsCuentas.add(l.ConvertedAccountId); }
List<Account> cuentas = [SELECT Id FROM Account WHERE Id IN :idsCuentas];
delete [SELECT Id FROM Contact WHERE AccountId IN :cuentas];
delete cuentas;
delete leads;
System.debug(LoggingLevel.INFO, 'NMD: borrados pedidos=' + pedidos.size() + ', oportunidades=' + opps.size()
    + ', cuentas=' + cuentas.size() + ', leads=' + leads.size());
