// =====================================================================
// No More Drama (NMD) - Usuario del agente Zen (Einstein Agent User)
// Crea el usuario con el que se ejecuta el Service Agent "Zen" y le
// asigna los permission sets AgentforceServiceAgentUser (de Salesforce)
// y NMD_Zen_Agent (acceso a los 4 Flows de acciones).
//
// Ejecutar:  sf apex run --file data/nmd-zen-agent-user.apex --target-org nmd-dev
//
// Idempotente: no duplica el usuario ni las asignaciones.
// Requiere desplegado: permission set NMD_Zen_Agent.
// El username debe coincidir con access.default_agent_user en
// force-app/main/default/aiAuthoringBundles/NMD_Zen/NMD_Zen.agent.
// En otra org, cambia USERNAME en ambos sitios (único en todo Salesforce).
// =====================================================================

final String USERNAME = 'zen.agente@tuorg.nmd-demo.example';

List<User> existentes = [SELECT Id FROM User WHERE Username = :USERNAME LIMIT 1];
User agente;
if (!existentes.isEmpty()) {
    agente = existentes[0];
    System.debug(LoggingLevel.INFO, 'NMD: el usuario del agente ya existe (' + agente.Id + ').');
} else {
    Profile perfil = [SELECT Id FROM Profile WHERE Name = 'Einstein Agent User' LIMIT 1];
    agente = new User(
        FirstName = 'Zen', LastName = 'Agente NMD', Alias = 'zenagt',
        Username = USERNAME, Email = UserInfo.getUserEmail(), CommunityNickname = 'zen.agente.nmd',
        CompanyName = 'No More Drama', Department = 'NMD Care',
        ProfileId = perfil.Id, LanguageLocaleKey = 'es', LocaleSidKey = 'es_ES',
        TimeZoneSidKey = 'Europe/Madrid', EmailEncodingKey = 'UTF-8');
    insert agente;
    System.debug(LoggingLevel.INFO, 'NMD: usuario del agente creado (' + agente.Id + ').');
}

Set<Id> yaAsignados = new Set<Id>();
for (PermissionSetAssignment psa : [SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :agente.Id]) {
    yaAsignados.add(psa.PermissionSetId);
}
List<PermissionSetAssignment> nuevas = new List<PermissionSetAssignment>();
for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN ('AgentforceServiceAgentUser', 'NMD_Zen_Agent')]) {
    if (!yaAsignados.contains(ps.Id)) {
        nuevas.add(new PermissionSetAssignment(AssigneeId = agente.Id, PermissionSetId = ps.Id));
        System.debug(LoggingLevel.INFO, 'NMD: asignando ' + ps.Name + '.');
    }
}
insert nuevas;
