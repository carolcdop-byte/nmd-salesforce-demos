/**
 * No More Drama (NMD) - Portal NMD Beverage: formularios públicos.
 *  - crearDrama: "Tengo un drama" crea un caso (origen Web NMD Beverage) que pasa por el
 *    Triaje NMD (Flow NMD_Triaje_IA) como cualquier caso nuevo.
 *  - unirseAlClub: "Únete al club" crea un lead (origen Club Drama Points) con consentimiento.
 *
 * without sharing: los usa el usuario invitado, que no tiene acceso a Case, Contact, Order ni
 * Lead. Por eso la clase NUNCA devuelve datos de registros existentes: solo el número del caso
 * que acaba de crear. El email sirve para vincular el caso a su contacto, pero la respuesta es
 * la misma exista o no, así que no se puede usar para averiguar quién es cliente.
 * Campo trampa (honeypot) "web": si un robot lo rellena, se responde como si todo fuera bien
 * pero no se crea nada.
 * Modo sistema explícito (WITH SYSTEM_MODE / AccessLevel.SYSTEM_MODE): desde la API 67 el Apex usa
 * modo usuario por defecto, y el invitado no tiene (ni debe tener) permisos sobre Case, Contact, Order o Lead.
 */
public without sharing class NMD_PortalFormularios {

    @TestVisible static final Set<String> TIPOS = new Set<String>{ 'Consulta de pedido', 'Devolución', 'Producto defectuoso', 'Queja' };
    static final Pattern PATRON_EMAIL = Pattern.compile('^[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}$');

    @AuraEnabled
    public static String crearDrama(String nombre, String email, String numeroPedido, String tipo, String descripcion,
                                    Boolean aceptaPrivacidad, String web) {
        if (String.isNotBlank(web)) {
            return '';
        }
        validar(nombre, email, aceptaPrivacidad);
        if (String.isBlank(descripcion) || descripcion.trim().length() < 10) {
            throw error('Cuéntanos tu drama con un poco más de detalle (al menos 10 caracteres).');
        }
        if (!TIPOS.contains(tipo)) {
            throw error('Elige el tipo de drama.');
        }
        email = email.trim().toLowerCase();
        Case c = new Case(
            Subject = ('Tengo un drama: ' + tipo).left(255),
            Description = descripcion.trim().left(4000),
            Type = tipo,
            Origin = 'Web NMD Beverage',
            SuppliedName = nombre.trim().left(80),
            SuppliedEmail = email);
        List<Contact> contactos = [SELECT Id, AccountId FROM Contact WHERE Email = :email WITH SYSTEM_MODE ORDER BY CreatedDate LIMIT 1];
        if (!contactos.isEmpty()) {
            c.ContactId = contactos[0].Id;
            c.AccountId = contactos[0].AccountId;
            if (String.isNotBlank(numeroPedido)) {
                // Solo se vincula si el pedido es de ese contacto
                for (Order o : [SELECT Id FROM Order WHERE OrderNumber = :numeroPedido.trim() AND BillToContactId = :contactos[0].Id WITH SYSTEM_MODE LIMIT 1]) {
                    c.Pedido__c = o.Id;
                }
            }
        }
        if (String.isNotBlank(numeroPedido) && c.Pedido__c == null) {
            c.Description = ('Número de pedido indicado: ' + numeroPedido.trim().left(20) + '\n\n' + c.Description).left(4000);
        }
        for (Group q : [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Agentes_NMD' WITH SYSTEM_MODE LIMIT 1]) {
            c.OwnerId = q.Id;
        }
        Database.insert(c, AccessLevel.SYSTEM_MODE);
        return [SELECT CaseNumber FROM Case WHERE Id = :c.Id WITH SYSTEM_MODE].CaseNumber;
    }

    @AuraEnabled
    public static void unirseAlClub(String nombre, String apellidos, String email, Boolean aceptaPrivacidad, String web) {
        if (String.isNotBlank(web)) {
            return;
        }
        validar(nombre, email, aceptaPrivacidad);
        if (String.isBlank(apellidos)) {
            throw error('Indica tus apellidos.');
        }
        email = email.trim().toLowerCase();
        if (![SELECT Id FROM Lead WHERE Email = :email AND LeadSource = 'Club Drama Points' AND IsConverted = false WITH SYSTEM_MODE LIMIT 1].isEmpty()) {
            return; // ya estaba apuntado: misma respuesta, sin duplicar
        }
        Lead l = new Lead(
            FirstName = nombre.trim().left(40), LastName = apellidos.trim().left(80), Email = email,
            Company = 'Particular (club Drama Points)', LeadSource = 'Club Drama Points',
            Consentimiento_club__c = true, Fecha_consentimiento_club__c = System.now());
        // Los particulares los gestiona la propietaria de la cuenta "Clientes NMD"
        for (Account a : [SELECT OwnerId FROM Account WHERE Name = 'Clientes NMD' WITH SYSTEM_MODE LIMIT 1]) {
            l.OwnerId = a.OwnerId;
        }
        Database.insert(l, AccessLevel.SYSTEM_MODE);
    }

    private static void validar(String nombre, String email, Boolean aceptaPrivacidad) {
        if (String.isBlank(nombre)) {
            throw error('Indica tu nombre.');
        }
        if (String.isBlank(email) || !PATRON_EMAIL.matcher(email.trim()).matches()) {
            throw error('Indica un email válido.');
        }
        if (aceptaPrivacidad != true) {
            throw error('Para continuar tienes que aceptar la política de privacidad.');
        }
    }

    private static AuraHandledException error(String mensaje) {
        AuraHandledException e = new AuraHandledException(mensaje);
        e.setMessage(mensaje);
        return e;
    }
}
