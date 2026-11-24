// =====================================================================
// No More Drama (NMD) - Foto del usuario del agente Zen
// Pone el icono de marca (Content Asset NMD_Icono) como foto de perfil
// del usuario "Zen Agente NMD". Se ve donde Zen aparece como autor
// (casos, historial, noticias).
//
// Ejecutar:  sf apex run --file data/nmd-zen-avatar.apex --target-org nmd-dev
//
// Requiere desplegado: contentassets/NMD_Icono y el usuario de Zen
// (data/nmd-zen-agent-user.apex). Lo ejecuta un administrador.
// El avatar del chat (cuando Zen tenga canal) se configura aparte, en la
// implementación de Messaging for In-App and Web: ver docs/branding.md.
// =====================================================================

final String USERNAME = 'zen.agente@tuorg.nmd-demo.example';

User zen = [SELECT Id FROM User WHERE Username = :USERNAME LIMIT 1];
ContentAsset icono = [SELECT ContentDocumentId FROM ContentAsset WHERE DeveloperName = 'NMD_Icono' LIMIT 1];
ContentVersion v = [SELECT VersionNumber FROM ContentVersion
                    WHERE ContentDocumentId = :icono.ContentDocumentId AND IsLatest = true LIMIT 1];

ConnectApi.Photo foto = ConnectApi.UserProfiles.setPhoto(null, zen.Id, icono.ContentDocumentId, Integer.valueOf(v.VersionNumber));
System.debug(LoggingLevel.INFO, 'NMD: foto de Zen actualizada: ' + foto.largePhotoUrl);
