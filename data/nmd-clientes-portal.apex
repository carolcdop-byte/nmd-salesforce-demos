// =====================================================================
// No More Drama (NMD) - Clientes registrados del portal NMD Beverage (Demo 5)
// Crea los usuarios de portal de los 2 particulares de la cuenta "Clientes NMD":
// Marta López Fuentes y Andrés Prieto Calvo (licencia Customer Community,
// perfil "NMD Cliente Beverage", es / es_ES) y les asigna el permission set
// NMD_Cliente_Portal. Lo que ve cada uno lo limita el sharing set
// "NMD Clientes Beverage" (solo sus pedidos y sus casos).
//
// Ejecutar:  sf apex run --file data/nmd-clientes-portal.apex --target-org nmd-dev
//
// Idempotente. Requiere: datos de la Demo 1, perfil "NMD Cliente Beverage",
// permission set NMD_Cliente_Portal, portal NMD Beverage activo y que el
// propietario de la cuenta "Clientes NMD" tenga rol (lo pone nmd-delegada.apex).
// El email de los usuarios es el de quien ejecuta el script (recibe el enlace
// para fijar la contraseña); los nombres de usuario son ficticios. En otra org,
// cambia DOMINIO (los nombres de usuario son únicos en todo Salesforce).
// =====================================================================

final String DOMINIO = '@tuorg.nmd-beverage.example';
Map<String, String> alias = new Map<String, String>{ 'marta.lopez@example.com' => 'martal', 'andres.prieto@example.com' => 'andresp' };

Profile perfil = [SELECT Id FROM Profile WHERE Name = 'NMD Cliente Beverage' LIMIT 1];
List<Contact> contactos = [SELECT Id, FirstName, LastName, Email FROM Contact
                           WHERE Email IN :alias.keySet() AND Account.Name = 'Clientes NMD'];
Map<Id, User> existentes = new Map<Id, User>();
for (User u : [SELECT Id, ContactId FROM User WHERE ContactId IN :contactos]) {
    existentes.put(u.ContactId, u);
}
List<User> nuevos = new List<User>();
for (Contact c : contactos) {
    if (existentes.containsKey(c.Id)) {
        continue;
    }
    nuevos.add(new User(
        ContactId = c.Id, ProfileId = perfil.Id, FirstName = c.FirstName, LastName = c.LastName,
        Alias = alias.get(c.Email), Username = c.Email.substringBefore('@') + DOMINIO,
        Email = UserInfo.getUserEmail(), CommunityNickname = c.Email.substringBefore('@') + '.nmd',
        LanguageLocaleKey = 'es', LocaleSidKey = 'es_ES', TimeZoneSidKey = 'Europe/Madrid', EmailEncodingKey = 'UTF-8'));
}
insert nuevos;

PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'NMD_Cliente_Portal'];
Set<Id> usuarios = new Set<Id>();
for (User u : [SELECT Id FROM User WHERE ContactId IN :contactos]) {
    usuarios.add(u.Id);
}
for (PermissionSetAssignment a : [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId = :ps.Id AND AssigneeId IN :usuarios]) {
    usuarios.remove(a.AssigneeId);
}
List<PermissionSetAssignment> asignaciones = new List<PermissionSetAssignment>();
for (Id u : usuarios) {
    asignaciones.add(new PermissionSetAssignment(AssigneeId = u, PermissionSetId = ps.Id));
}
insert asignaciones;
System.debug(LoggingLevel.INFO, 'NMD Beverage: ' + nuevos.size() + ' usuarios de portal creados, ' + asignaciones.size() + ' permission sets asignados.');
