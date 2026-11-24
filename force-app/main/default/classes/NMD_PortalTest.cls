@IsTest
private class NMD_PortalTest {

    @TestSetup
    static void datos() {
        Account a = new Account(Name = 'Clientes NMD');
        insert a;
        Contact c = new Contact(FirstName = 'Ana', LastName = 'Prueba', Email = 'ana.prueba@example.com', AccountId = a.Id, Miembro_club__c = true);
        insert c;
        Product2 p = new Product2(Name = 'Lager Test', ProductCode = 'NMD-BEV-099', Linea_de_negocio__c = 'Beverage', IsActive = true,
                                  Description = 'Cerveza de prueba');
        Product2 caja = new Product2(Name = 'Caja Test', ProductCode = 'NMD-BEV-199', Linea_de_negocio__c = 'Beverage', IsActive = true);
        insert new List<Product2>{ p, caja };
        PricebookEntry pe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = p.Id, UnitPrice = 2, IsActive = true);
        insert pe;
        Order o = new Order(AccountId = a.Id, BillToContactId = c.Id, Pricebook2Id = Test.getStandardPricebookId(),
                            EffectiveDate = Date.today().addDays(-10), Status = 'Draft', Estado_envio__c = 'Pendiente');
        insert o;
        insert new OrderItem(OrderId = o.Id, PricebookEntryId = pe.Id, Quantity = 30, UnitPrice = 2);
        o.Estado_envio__c = 'Entregado';
        update o;
    }

    @IsTest
    static void catalogoSoloBotellasSinPrecio() {
        List<NMD_PortalCatalogo.Cerveza> cervezas = NMD_PortalCatalogo.getCervezas();
        Set<String> codigos = new Set<String>();
        for (NMD_PortalCatalogo.Cerveza c : cervezas) {
            codigos.add(c.codigo);
        }
        Assert.isTrue(codigos.contains('NMD-BEV-099'), 'Incluye la botella');
        Assert.isFalse(codigos.contains('NMD-BEV-199'), 'No incluye las cajas B2B');
        NMD_PortalCatalogo.ReglasClub r = NMD_PortalCatalogo.getReglasClub();
        Assert.areEqual(300, r.umbralZen);
    }

    @IsTest
    static void puntosAlEntregar() {
        Contact c = [SELECT Drama_Points__c, Nivel_club__c, Puntos_siguiente_nivel__c FROM Contact WHERE Email = 'ana.prueba@example.com'];
        // 50 por pedido + 60 € x 1 punto
        Assert.areEqual(110, c.Drama_Points__c);
        Assert.areEqual('Tranqui', c.Nivel_club__c);
        Assert.areEqual(190, c.Puntos_siguiente_nivel__c);
        // Guardarlo otra vez no vuelve a sumar
        Order o = [SELECT Id FROM Order LIMIT 1];
        update o;
        Assert.areEqual(110, [SELECT Drama_Points__c FROM Contact WHERE Id = :c.Id].Drama_Points__c);
    }

    @IsTest
    static void dramaCreaCasoVinculado() {
        String pedido = [SELECT OrderNumber FROM Order LIMIT 1].OrderNumber;
        String numero = NMD_PortalFormularios.crearDrama('Ana', 'ANA.prueba@example.com ', pedido, 'Queja', 'La botella llegó rota y sin tapón.', true, null);
        Case k = [SELECT ContactId, Pedido__c, Origin, Type, Owner.Name FROM Case WHERE CaseNumber = :numero];
        Assert.isNotNull(k.ContactId);
        Assert.isNotNull(k.Pedido__c);
        Assert.areEqual('Web NMD Beverage', k.Origin);
        Assert.areEqual('Queja', k.Type);
    }

    @IsTest
    static void dramaPedidoAjenoNoSeVincula() {
        String pedido = [SELECT OrderNumber FROM Order LIMIT 1].OrderNumber;
        String numero = NMD_PortalFormularios.crearDrama('Otro', 'otro@example.com', pedido, 'Consulta de pedido', '¿Dónde está mi pedido?', true, '');
        Case k = [SELECT ContactId, Pedido__c, Description FROM Case WHERE CaseNumber = :numero];
        Assert.isNull(k.ContactId);
        Assert.isNull(k.Pedido__c);
        Assert.isTrue(k.Description.contains(pedido));
    }

    @IsTest
    static void validacionesYTrampa() {
        String[] errores = new String[]{};
        try { NMD_PortalFormularios.crearDrama('Ana', 'no-es-email', null, 'Queja', 'Un drama de prueba', true, null); } catch (AuraHandledException e) { errores.add(e.getMessage()); }
        try { NMD_PortalFormularios.crearDrama('Ana', 'ana@example.com', null, 'Queja', 'Un drama de prueba', false, null); } catch (AuraHandledException e) { errores.add(e.getMessage()); }
        try { NMD_PortalFormularios.crearDrama('Ana', 'ana@example.com', null, 'Otro', 'Un drama de prueba', true, null); } catch (AuraHandledException e) { errores.add(e.getMessage()); }
        try { NMD_PortalFormularios.crearDrama('Ana', 'ana@example.com', null, 'Queja', 'corto', true, null); } catch (AuraHandledException e) { errores.add(e.getMessage()); }
        try { NMD_PortalFormularios.unirseAlClub('Ana', '', 'ana@example.com', true, null); } catch (AuraHandledException e) { errores.add(e.getMessage()); }
        try { NMD_PortalFormularios.unirseAlClub('', 'Prueba', 'ana@example.com', true, null); } catch (AuraHandledException e) { errores.add(e.getMessage()); }
        Assert.areEqual(6, errores.size(), String.join(errores, ' | '));
        Integer antes = [SELECT COUNT() FROM Case];
        Assert.areEqual('', NMD_PortalFormularios.crearDrama('Bot', 'bot@example.com', null, 'Queja', 'Spam spam spam', true, 'http://spam'));
        NMD_PortalFormularios.unirseAlClub('Bot', 'Bot', 'bot@example.com', true, 'http://spam');
        Assert.areEqual(antes, [SELECT COUNT() FROM Case]);
        Assert.areEqual(0, [SELECT COUNT() FROM Lead WHERE Email = 'bot@example.com']);
    }

    @IsTest
    static void clubCreaLeadSinDuplicar() {
        NMD_PortalFormularios.unirseAlClub('Leo', 'Nuevo', 'Leo.Nuevo@example.com', true, null);
        NMD_PortalFormularios.unirseAlClub('Leo', 'Nuevo', 'leo.nuevo@example.com', true, null);
        List<Lead> leads = [SELECT LeadSource, Consentimiento_club__c, Fecha_consentimiento_club__c FROM Lead WHERE Email = 'leo.nuevo@example.com'];
        Assert.areEqual(1, leads.size());
        Assert.areEqual('Club Drama Points', leads[0].LeadSource);
        Assert.isTrue(leads[0].Consentimiento_club__c);
        Assert.isNotNull(leads[0].Fecha_consentimiento_club__c);
    }

    @IsTest
    static void miZonaSoloParaClientes() {
        try {
            NMD_PortalMiZona.getMiZona();
            Assert.fail('Un usuario interno no tiene Mi zona');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('clientes registrados'));
        }
    }

    /** Dos particulares de la misma cuenta: ninguno ve los pedidos ni los casos del otro, ni consultando directamente. */
    @IsTest
    static void aislamientoEntreClientesDeLaMismaCuenta() {
        Contact ana = [SELECT Id, AccountId FROM Contact WHERE Email = 'ana.prueba@example.com'];
        Contact beto = new Contact(FirstName = 'Beto', LastName = 'Prueba', Email = 'beto.prueba@example.com', AccountId = ana.AccountId);
        insert beto;
        insert new Case(Subject = 'Caso de Ana', ContactId = ana.Id, AccountId = ana.AccountId);
        Profile pr = [SELECT Id FROM Profile WHERE Name = 'NMD Cliente Beverage' LIMIT 1];
        User u = new User(FirstName = 'Beto', LastName = 'Prueba', Alias = 'betopr', Email = 'beto.prueba@example.com',
            Username = 'beto.prueba.' + System.currentTimeMillis() + '@nmd-test.example.com', ProfileId = pr.Id, ContactId = beto.Id,
            LanguageLocaleKey = 'es', LocaleSidKey = 'es_ES', TimeZoneSidKey = 'Europe/Madrid', EmailEncodingKey = 'UTF-8');
        System.runAs(new User(Id = UserInfo.getUserId())) { // evita MIXED_DML con los contactos y casos de arriba
            insert u;
            insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'NMD_Cliente_Portal'].Id);
        }
        System.runAs(u) {
            Assert.areEqual(0, [SELECT COUNT() FROM Order WITH USER_MODE], 'Beto no debe ver el pedido de Ana');
            Assert.areEqual(0, [SELECT COUNT() FROM Case WITH USER_MODE], 'Beto no debe ver el caso de Ana');
            Assert.areEqual(0, [SELECT COUNT() FROM Contact WHERE Id = :ana.Id WITH USER_MODE], 'Beto no debe ver la ficha de Ana');
            Assert.areEqual(1, [SELECT COUNT() FROM Contact WHERE Id = :beto.Id WITH USER_MODE], 'Beto ve su propia ficha');
            NMD_PortalMiZona.Resumen r = NMD_PortalMiZona.getMiZona();
            Assert.areEqual(0, r.pedidos.size());
            Assert.areEqual(0, r.casos.size());
        }
    }

    @IsTest
    static void miZonaDelCliente() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'ana.prueba@example.com'];
        Profile pr = [SELECT Id FROM Profile WHERE Name = 'NMD Cliente Beverage' LIMIT 1];
        User u = new User(FirstName = 'Ana', LastName = 'Prueba', Alias = 'anapr', Email = 'ana.prueba@example.com',
            Username = 'ana.prueba.' + System.currentTimeMillis() + '@nmd-test.example.com', ProfileId = pr.Id, ContactId = c.Id,
            LanguageLocaleKey = 'es', LocaleSidKey = 'es_ES', TimeZoneSidKey = 'Europe/Madrid', EmailEncodingKey = 'UTF-8');
        insert u;
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'NMD_Cliente_Portal'].Id);
        NMD_PortalMiZona.Resumen r;
        System.runAs(u) {
            r = NMD_PortalMiZona.getMiZona();
        }
        Assert.areEqual('Ana', r.nombre);
        Assert.areEqual(110, r.puntos);
        Assert.areEqual('Zen', r.siguienteNivel);
        Assert.areEqual(1, r.pedidos.size());
        Assert.areEqual(1, r.pedidos[0].lineas.size());
    }
}
