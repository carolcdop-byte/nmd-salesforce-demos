// =====================================================================
// No More Drama (NMD) - Usuario "Agente Humano NMD"
// Crea el usuario (licencia Salesforce, perfil Usuario estándar,
// Service Cloud User si hay licencia disponible), le asigna el permission
// set NMD Base y el de Salesforce "Usuario de plantilla de solicitud"
// (EinsteinGPTPromptTemplateUser, para la acción Detectar drama) y lo
// añade a las colas "Agentes NMD" y "Urgencias NMD".
//
// Ejecutar:  sf apex run --file data/nmd-agente-humano.apex --target-org nmd-dev
//
// Idempotente: si el usuario, la asignación o la pertenencia a la cola
// ya existen, no los duplica. Si el usuario existe, restablece su idioma
// a español (es / es_ES).
// Requiere desplegado: permission set NMD_Base y colas Agentes_NMD y Urgencias_NMD.
// El email es el del usuario que ejecuta el script (recibe el enlace
// para establecer la contraseña). En otra org, cambia USERNAME, que
// debe ser único en todo Salesforce.
// =====================================================================

final String USERNAME = 'agente.humano.nmd@tuorg.nmd-demo.example';

List<User> existentes = [SELECT Id, UserPermissionsSupportUser FROM User WHERE Username = :USERNAME LIMIT 1];
User agente;
if (!existentes.isEmpty()) {
    agente = existentes[0];
    System.debug(LoggingLevel.INFO, 'NMD: el usuario ya existe (' + agente.Id + ').');
    // La interfaz de la demo debe estar en español aunque alguien haya cambiado el idioma
    User idioma = [SELECT Id, LanguageLocaleKey, LocaleSidKey FROM User WHERE Id = :agente.Id];
    if (idioma.LanguageLocaleKey != 'es' || idioma.LocaleSidKey != 'es_ES') {
        update new User(Id = agente.Id, LanguageLocaleKey = 'es', LocaleSidKey = 'es_ES');
        System.debug(LoggingLevel.INFO, 'NMD: idioma del usuario restablecido a español.');
    }
} else {
    Profile perfil = [SELECT Id FROM Profile WHERE Name IN ('Usuario estándar', 'Standard User') LIMIT 1];
    agente = new User(
        FirstName = 'Agente Humano', LastName = 'NMD', Alias = 'ahnmd',
        Username = USERNAME, Email = UserInfo.getUserEmail(), CommunityNickname = 'agente.humano.nmd',
        Title = 'Agente de atención al cliente', CompanyName = 'No More Drama', Department = 'NMD Care',
        ProfileId = perfil.Id, LanguageLocaleKey = 'es', LocaleSidKey = 'es_ES',
        TimeZoneSidKey = 'Europe/Madrid', EmailEncodingKey = 'UTF-8',
        UserPermissionsSupportUser = true);

    Database.DMLOptions opts = new Database.DMLOptions();
    opts.EmailHeader.triggerUserEmail = true; // envía el email de bienvenida para fijar la contraseña
    Database.SaveResult sr = Database.insert(agente, opts);
    if (!sr.isSuccess()) {
        // Sin licencia Service Cloud User disponible: se crea sin ella
        System.debug(LoggingLevel.WARN, 'NMD: no se pudo crear con Service Cloud User: ' + sr.getErrors()[0].getMessage());
        agente.Id = null;
        agente.UserPermissionsSupportUser = false;
        sr = Database.insert(agente, opts);
        if (!sr.isSuccess()) {
            throw new DmlException('NMD: no se pudo crear el usuario: ' + sr.getErrors()[0].getMessage());
        }
    }
    System.debug(LoggingLevel.INFO, 'NMD: usuario creado (' + agente.Id + '), Service Cloud User = ' + agente.UserPermissionsSupportUser + '.');
}

// Permission sets: NMD Base y Usuario de plantilla de solicitud (Prompt Builder).
// El permiso para ejecutar plantillas va en un permission set con licencia
// Einstein Prompt Templates, por eso no puede estar dentro de NMD Base.
for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN ('NMD_Base', 'EinsteinGPTPromptTemplateUser')]) {
    if ([SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :agente.Id AND PermissionSetId = :ps.Id].isEmpty()) {
        insert new PermissionSetAssignment(AssigneeId = agente.Id, PermissionSetId = ps.Id);
        System.debug(LoggingLevel.INFO, 'NMD: permission set ' + ps.Name + ' asignado.');
    }
}

// Colas Agentes NMD y Urgencias NMD (Triaje NMD)
for (Group cola : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN ('Agentes_NMD', 'Urgencias_NMD')]) {
    if ([SELECT Id FROM GroupMember WHERE GroupId = :cola.Id AND UserOrGroupId = :agente.Id].isEmpty()) {
        insert new GroupMember(GroupId = cola.Id, UserOrGroupId = agente.Id);
        System.debug(LoggingLevel.INFO, 'NMD: añadido a la cola ' + cola.DeveloperName + '.');
    }
}
