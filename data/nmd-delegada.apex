// =====================================================================
// No More Drama (NMD) - Usuario "Delegada NMD Clinic" (Demo 4, NMD Clinic)
// Crea la delegada de visita médica (licencia Salesforce Platform, perfil
// "Usuario de Platform estándar", en español), con rol "Delegada NMD
// Clinic" y como Manager al usuario que ejecuta el script. Al que ejecuta
// (la jefa de compliance y ventas) le pone el rol "Jefa de compliance y
// ventas": así ve todas las visitas (privadas) por jerarquía de roles.
// Asigna el permission set NMD Clinic a las dos y el de plantillas de
// Prompt Builder (Prompt Template User) a la delegada.
//
// Ejecutar:  sf apex run --file data/nmd-delegada.apex --target-org nmd-dev
//
// Idempotente. Requiere desplegados: roles Jefa_Compliance_Ventas y
// Delegada_NMD_Clinic, permission set NMD_Clinic.
// El email es el del usuario que ejecuta el script (recibe el enlace para
// establecer la contraseña). En otra org, cambia USERNAME (único en todo
// Salesforce).
// =====================================================================

final String USERNAME = 'delegada.clinic@tuorg.nmd-demo.example';
final Id JEFA = UserInfo.getUserId();

Map<String, Id> roles = new Map<String, Id>();
for (UserRole r : [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName IN ('Jefa_Compliance_Ventas', 'Delegada_NMD_Clinic')]) {
    roles.put(r.DeveloperName, r.Id);
}

// Rol de la jefa (usuario que ejecuta)
User usuarioJefa = [SELECT Id, UserRoleId FROM User WHERE Id = :JEFA];
if (usuarioJefa.UserRoleId != roles.get('Jefa_Compliance_Ventas')) {
    update new User(Id = JEFA, UserRoleId = roles.get('Jefa_Compliance_Ventas'));
    System.debug(LoggingLevel.INFO, 'NMD: rol Jefa de compliance y ventas asignado.');
}

List<User> existentes = [SELECT Id FROM User WHERE Username = :USERNAME LIMIT 1];
User delegada;
if (!existentes.isEmpty()) {
    delegada = new User(Id = existentes[0].Id, LanguageLocaleKey = 'es', LocaleSidKey = 'es_ES', ManagerId = JEFA,
                        UserRoleId = roles.get('Delegada_NMD_Clinic'), IsActive = true);
    update delegada;
    System.debug(LoggingLevel.INFO, 'NMD: la delegada ya existe (' + delegada.Id + '); idioma, rol y Manager restablecidos.');
} else {
    Profile perfil = [SELECT Id FROM Profile WHERE Name IN ('Usuario de Platform estándar', 'Standard Platform User') LIMIT 1];
    delegada = new User(
        FirstName = 'Delegada', LastName = 'NMD Clinic', Alias = 'delclin',
        Username = USERNAME, Email = UserInfo.getUserEmail(), CommunityNickname = 'delegada.clinic',
        Title = 'Delegada de visita médica', CompanyName = 'No More Drama', Department = 'NMD Clinic',
        ProfileId = perfil.Id, ManagerId = JEFA, UserRoleId = roles.get('Delegada_NMD_Clinic'),
        LanguageLocaleKey = 'es', LocaleSidKey = 'es_ES', TimeZoneSidKey = 'Europe/Madrid', EmailEncodingKey = 'UTF-8');
    Database.DMLOptions opts = new Database.DMLOptions();
    opts.EmailHeader.triggerUserEmail = true; // email de bienvenida para fijar la contraseña
    Database.SaveResult sr = Database.insert(delegada, opts);
    if (!sr.isSuccess()) {
        throw new DmlException('NMD: no se pudo crear la delegada: ' + sr.getErrors()[0].getMessage());
    }
    System.debug(LoggingLevel.INFO, 'NMD: delegada creada (' + delegada.Id + ').');
}

// Permission sets
Map<String, Id> ps = new Map<String, Id>();
for (PermissionSet p : [SELECT Id, Name FROM PermissionSet WHERE Name IN ('NMD_Clinic', 'EinsteinGPTPromptTemplateUser')]) {
    ps.put(p.Name, p.Id);
}
List<PermissionSetAssignment> deseadas = new List<PermissionSetAssignment>{
    new PermissionSetAssignment(AssigneeId = delegada.Id, PermissionSetId = ps.get('NMD_Clinic')),
    new PermissionSetAssignment(AssigneeId = JEFA, PermissionSetId = ps.get('NMD_Clinic'))
};
if (ps.containsKey('EinsteinGPTPromptTemplateUser')) {
    deseadas.add(new PermissionSetAssignment(AssigneeId = delegada.Id, PermissionSetId = ps.get('EinsteinGPTPromptTemplateUser')));
}
Set<String> ya = new Set<String>();
for (PermissionSetAssignment a : [SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment
                                  WHERE AssigneeId IN (:delegada.Id, :JEFA) AND PermissionSetId IN :ps.values()]) {
    ya.add('' + a.AssigneeId + a.PermissionSetId);
}
List<PermissionSetAssignment> nuevas = new List<PermissionSetAssignment>();
for (PermissionSetAssignment a : deseadas) {
    if (!ya.contains('' + a.AssigneeId + a.PermissionSetId)) {
        nuevas.add(a);
    }
}
insert nuevas;
System.debug(LoggingLevel.INFO, 'NMD: ' + nuevas.size() + ' permission sets asignados.');
