@IsTest
private class NMD_ContextoVisitaTest {

    @TestSetup
    static void datos() {
        Id rtHco = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HCO').getRecordTypeId();
        Id rtHcp = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('HCP').getRecordTypeId();
        Account hco = new Account(Name = 'Clínica Test', RecordTypeId = rtHco);
        insert hco;
        Contact hcp = new Contact(LastName = 'Test', FirstName = 'Dra.', AccountId = hco.Id, RecordTypeId = rtHcp,
            Especialidad__c = 'Psicología clínica', Segmento__c = 'A', Numero_colegiado__c = 'TEST-001',
            Consentimiento_RGPD__c = true, Fecha_consentimiento__c = Date.today().addMonths(-6));
        insert hcp;
        Kit_de_muestra__c kit = new Kit_de_muestra__c(Name = 'Kit Test', Codigo__c = 'TEST-KIT', Activo__c = true);
        insert kit;
        Visita__c pasada = new Visita__c(HCP__c = hcp.Id, HCO__c = hco.Id, Fecha__c = Date.today().addDays(-7), Estado__c = 'Realizada',
            Objetivo__c = 'Presentar el kit', Resultado__c = 'Interesada', Siguiente_paso__c = 'Dejar muestras');
        insert pasada;
        insert new Muestra_entregada__c(Visita__c = pasada.Id, Kit__c = kit.Id, Cantidad__c = 2);
        insert new Visita__c(HCP__c = hcp.Id, HCO__c = hco.Id, Fecha__c = Date.today(), Estado__c = 'Planificada', Objetivo__c = 'Seguimiento');
    }

    @IsTest
    static void construyeContexto() {
        Visita__c v = [SELECT Id FROM Visita__c WHERE Estado__c = 'Planificada' LIMIT 1];
        NMD_ContextoVisita.Request r = new NMD_ContextoVisita.Request();
        r.visitaId = v.Id;
        Test.startTest();
        List<NMD_ContextoVisita.Response> res = NMD_ContextoVisita.contexto(new List<NMD_ContextoVisita.Request>{ r });
        Test.stopTest();
        String p = res[0].contexto;
        Assert.isTrue(p.contains('Dra. Test'), p);
        Assert.isTrue(p.contains('Segmento: A'), p);
        Assert.isTrue(p.contains('Consentimiento RGPD: sí'), p);
        Assert.isTrue(p.contains('Muestras este año: 2 de 10'), p);
        Assert.isTrue(p.contains('Presentar el kit'), 'Incluye la visita anterior: ' + p);
        Assert.isTrue(p.contains('2 x Kit Test'), 'Incluye las muestras: ' + p);
    }

    @IsTest
    static void sinVisita() {
        NMD_ContextoVisita.Request r = new NMD_ContextoVisita.Request();
        List<NMD_ContextoVisita.Response> res = NMD_ContextoVisita.contexto(new List<NMD_ContextoVisita.Request>{ r });
        Assert.areEqual('No hay visita.', res[0].contexto);
    }

    @IsTest
    static void hcpSinHistorial() {
        Contact hcp = [SELECT Id, AccountId FROM Contact WHERE Numero_colegiado__c = 'TEST-001'];
        Visita__c v = new Visita__c(HCP__c = hcp.Id, Fecha__c = Date.today().addDays(3), Estado__c = 'Planificada');
        insert v;
        delete [SELECT Id FROM Visita__c WHERE Estado__c = 'Realizada'];
        String p = NMD_ContextoVisita.construir(v.Id);
        Assert.isTrue(p.contains('- Ninguna registrada.'), p);
        Assert.isTrue(p.contains('- Ninguna.'), p);
        Assert.isTrue(p.contains('Objetivo indicado: sin datos'), p);
    }
}
