// =====================================================================
// No More Drama (NMD) - Triaje inicial de los casos abiertos
// El Flow NMD_Triaje_IA solo analiza los casos NUEVOS. Este script analiza
// una vez los casos abiertos que aún no tienen triaje (por ejemplo, tras
// desplegar la Demo 2 sobre datos existentes), en lotes de 5 para no
// superar el tiempo máximo de llamadas externas por transacción.
//
// Ejecutar (repetir hasta que el log diga quedan=0):
//   sf apex run --file data/nmd-triaje-inicial.apex --target-org nmd-dev
//
// Hace lo mismo que NMD_Triaje_IA: plantilla NMD_Detector_Drama ->
// NMD_DramaParser -> guardar la propuesta o marcar Triaje IA fallido.
// Las reglas (NMD_Calcular_Camino / NMD_Aplicar_Camino) se aplican solas
// al guardar. Cada caso es una llamada a la IA (consume créditos Einstein).
// =====================================================================
List<Case> casos = [SELECT Id, CaseNumber, Type FROM Case
                    WHERE IsClosed = false AND Triaje_IA_fecha__c = null
                    ORDER BY CaseNumber LIMIT 5];
List<Case> upd = new List<Case>();
for (Case c : casos) {
    Case u = new Case(Id = c.Id, Triaje_IA_fecha__c = System.now());
    try {
        ConnectApi.EinsteinPromptTemplateGenerationsInput inp = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        inp.isPreview = false;
        ConnectApi.WrappedValue v = new ConnectApi.WrappedValue();
        v.value = new Map<String, String>{ 'id' => c.Id };
        inp.inputParams = new Map<String, ConnectApi.WrappedValue>{ 'Input:Caso' => v };
        inp.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        inp.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';
        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation out =
            ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('NMD_Detector_Drama', inp);
        NMD_DramaParser.Entrada e = new NMD_DramaParser.Entrada();
        e.textoIA = out.generations[0].text;
        NMD_DramaParser.Salida s = NMD_DramaParser.interpretar(new List<NMD_DramaParser.Entrada>{ e })[0];
        if (s.exito) {
            u.Nivel_drama__c = s.nivel;
            u.Categoria_IA__c = s.categoria;
            u.Resumen_IA__c = s.resumen;
            u.Guia_agente__c = s.guia;
            u.Respuesta_sugerida__c = s.borrador;
            u.Triaje_IA_fallido__c = false;
            if (String.isBlank(c.Type)) { u.Type = s.categoria; }
        } else {
            u.Triaje_IA_fallido__c = true;
        }
        System.debug(LoggingLevel.INFO, 'NMD: ' + c.CaseNumber + ' exito=' + s.exito + ' nivel=' + s.nivel + ' ' + s.mensajeError);
    } catch (Exception ex) {
        u.Triaje_IA_fallido__c = true;
        System.debug(LoggingLevel.INFO, 'NMD: ' + c.CaseNumber + ' ERROR ' + ex.getMessage());
    }
    upd.add(u);
}
update upd;
Integer quedan = [SELECT COUNT() FROM Case WHERE IsClosed = false AND Triaje_IA_fecha__c = null];
System.debug(LoggingLevel.INFO, 'NMD: procesados=' + upd.size() + ' quedan=' + quedan);
