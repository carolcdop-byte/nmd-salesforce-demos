// =====================================================================
// No More Drama (NMD) - Usuario "Comercial NMD" (Demo 3, NMD Distribución)
// Crea el comercial (licencia Salesforce, perfil Usuario estándar, en
// español), pone como su Manager al usuario que ejecuta el script (la jefa
// de ventas, que aprueba los descuentos de más del 15 %) y asigna el
// permission set NMD Ventas al comercial y a la jefa de ventas.
//
// Ejecutar:  sf apex run --file data/nmd-comercial.apex --target-org nmd-dev
//
// Idempotente: no duplica el usuario ni las asignaciones; si el usuario ya
// existe, restablece su idioma (es / es_ES) y su Manager.
// Requiere desplegado: permission set NMD_Ventas.
// El email es el del usuario que ejecuta el script (recibe el enlace para
// establecer la contraseña). En otra org, cambia USERNAME (único en todo
// Salesforce).
// =====================================================================

final String USERNAME = 'comercial.nmd@tuorg.nmd-demo.example';
final Id JEFA = UserInfo.getUserId();

List<User> existentes = [SELECT Id, LanguageLocaleKey, LocaleSidKey, ManagerId FROM User WHERE Username = :USERNAME LIMIT 1];
User comercial;
if (!existentes.isEmpty()) {
    comercial = existentes[0];
    System.debug(LoggingLevel.INFO, 'NMD: el comercial ya existe (' + comercial.Id + ').');
    if (comercial.LanguageLocaleKey != 'es' || comercial.LocaleSidKey != 'es_ES' || comercial.ManagerId != JEFA) {
        update new User(Id = comercial.Id, LanguageLocaleKey = 'es', LocaleSidKey = 'es_ES', ManagerId = JEFA);
        System.debug(LoggingLevel.INFO, 'NMD: idioma y Manager del comercial restablecidos.');
    }
} else {
    Profile perfil = [SELECT Id FROM Profile WHERE Name IN ('Usuario estándar', 'Standard User') LIMIT 1];
    comercial = new User(
        FirstName = 'Comercial', LastName = 'NMD', Alias = 'comnmd',
        Username = USERNAME, Email = UserInfo.getUserEmail(), CommunityNickname = 'comercial.nmd',
        Title = 'Comercial B2B', CompanyName = 'No More Drama', Department = 'NMD Distribución',
        ProfileId = perfil.Id, ManagerId = JEFA,
        LanguageLocaleKey = 'es', LocaleSidKey = 'es_ES', TimeZoneSidKey = 'Europe/Madrid', EmailEncodingKey = 'UTF-8');
    Database.DMLOptions opts = new Database.DMLOptions();
    opts.EmailHeader.triggerUserEmail = true; // email de bienvenida para fijar la contraseña
    Database.SaveResult sr = Database.insert(comercial, opts);
    if (!sr.isSuccess()) {
        throw new DmlException('NMD: no se pudo crear el comercial: ' + sr.getErrors()[0].getMessage());
    }
    System.debug(LoggingLevel.INFO, 'NMD: comercial creado (' + comercial.Id + ').');
}

// Permission set NMD Ventas para el comercial y la jefa de ventas
PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'NMD_Ventas' LIMIT 1];
Set<Id> yaAsignados = new Set<Id>();
for (PermissionSetAssignment psa : [SELECT AssigneeId FROM PermissionSetAssignment
                                    WHERE PermissionSetId = :ps.Id AND AssigneeId IN (:comercial.Id, :JEFA)]) {
    yaAsignados.add(psa.AssigneeId);
}
List<PermissionSetAssignment> nuevas = new List<PermissionSetAssignment>();
for (Id u : new List<Id>{ comercial.Id, JEFA }) {
    if (!yaAsignados.contains(u)) {
        nuevas.add(new PermissionSetAssignment(AssigneeId = u, PermissionSetId = ps.Id));
    }
}
insert nuevas;
System.debug(LoggingLevel.INFO, 'NMD: asignaciones de NMD Ventas nuevas: ' + nuevas.size());
