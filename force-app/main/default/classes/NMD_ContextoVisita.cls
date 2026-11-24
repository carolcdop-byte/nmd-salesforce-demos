/**
 * No More Drama (NMD) - NMD Clinic: contexto para "Prepara mi visita".
 * Acción invocable del Flow NMD_Clinic_Prepara_Visita. Reúne en texto los datos del HCP, su
 * cobertura, las últimas visitas realizadas y las muestras del año. El Flow lo guarda en
 * Visita__c.Contexto_IA__c y la plantilla NMD_Prepara_Visita lo lee. (Esta org no admite
 * campos de combinación Apex en plantillas Flex, por eso se pasa por un campo.)
 *
 * with sharing: la delegada solo ve sus propias visitas (Visita__c es privado).
 */
public with sharing class NMD_ContextoVisita {

    public class Request {
        @InvocableVariable(label='Id de la visita' required=true)
        public Id visitaId;
    }

    public class Response {
        @InvocableVariable(label='Contexto')
        public String contexto;
    }

    @InvocableMethod(label='NMD Clinic: contexto de la visita' description='Datos del HCP, últimas visitas y muestras para preparar la visita con IA.'
        category='No More Drama')
    public static List<Response> contexto(List<Request> requests) {
        List<Response> out = new List<Response>();
        for (Request r : requests) {
            Response res = new Response();
            res.contexto = construir(r == null ? null : r.visitaId);
            out.add(res);
        }
        return out;
    }

    @TestVisible
    static String construir(Id visitaId) {
        if (visitaId == null) {
            return 'No hay visita.';
        }
        Visita__c v = [SELECT Id, Name, Fecha__c, Objetivo__c, Estado__c, HCP__c, HCO__r.Name,
                              HCP__r.Name, HCP__r.Especialidad__c, HCP__r.Segmento__c, HCP__r.Objetivo_visitas__c,
                              HCP__r.Cobertura__c, HCP__r.Visitas_mes__c, HCP__r.Visitas_trimestre__c,
                              HCP__r.Consentimiento_RGPD__c, HCP__r.Fecha_consentimiento__c,
                              HCP__r.Muestras_ano__c, HCP__r.Muestras_restantes__c, HCP__r.Account.Name
                       FROM Visita__c WHERE Id = :visitaId];
        NMD_Clinic_Config__mdt cfg = NMD_Clinic_Config__mdt.getInstance('General');
        Decimal limite = cfg == null ? 10 : cfg.Limite_anual_muestras__c;

        List<String> l = new List<String>();
        l.add('HCP: ' + v.HCP__r.Name + ' · Especialidad: ' + valor(v.HCP__r.Especialidad__c)
            + ' · Centro (HCO): ' + valor(v.HCO__r.Name != null ? v.HCO__r.Name : v.HCP__r.Account.Name));
        l.add('Segmento: ' + valor(v.HCP__r.Segmento__c) + ' · Objetivo de visitas: ' + valor(v.HCP__r.Objetivo_visitas__c)
            + ' · Cobertura actual: ' + valor(v.HCP__r.Cobertura__c)
            + ' (visitas realizadas este mes: ' + entero(v.HCP__r.Visitas_mes__c) + ', este trimestre: ' + entero(v.HCP__r.Visitas_trimestre__c) + ')');
        l.add('Consentimiento RGPD: ' + (v.HCP__r.Consentimiento_RGPD__c ? 'sí (desde ' + fecha(v.HCP__r.Fecha_consentimiento__c) + ')' : 'NO'));
        l.add('Muestras este año: ' + entero(v.HCP__r.Muestras_ano__c) + ' de ' + entero(limite)
            + ' · Disponibles: ' + entero(v.HCP__r.Muestras_restantes__c));
        l.add('Visita a preparar: ' + v.Name + ' del ' + fecha(v.Fecha__c) + ' · Objetivo indicado: ' + valor(v.Objetivo__c));

        List<Visita__c> anteriores = [SELECT Fecha__c, Objetivo__c, Resultado__c, Siguiente_paso__c FROM Visita__c
                                      WHERE HCP__c = :v.HCP__c AND Estado__c = 'Realizada' AND Id != :v.Id
                                      ORDER BY Fecha__c DESC LIMIT 3];
        l.add('Últimas visitas realizadas:');
        if (anteriores.isEmpty()) {
            l.add('- Ninguna registrada.');
        }
        for (Visita__c a : anteriores) {
            l.add('- ' + fecha(a.Fecha__c) + ': objetivo «' + valor(a.Objetivo__c) + '»; resultado «' + valor(a.Resultado__c)
                + '»; siguiente paso «' + valor(a.Siguiente_paso__c) + '»');
        }
        List<Muestra_entregada__c> muestras = [SELECT Fecha_entrega__c, Kit__r.Name, Cantidad__c FROM Muestra_entregada__c
                                               WHERE HCP__c = :v.HCP__c ORDER BY Fecha_entrega__c DESC LIMIT 5];
        l.add('Muestras entregadas recientemente:');
        if (muestras.isEmpty()) {
            l.add('- Ninguna.');
        }
        for (Muestra_entregada__c m : muestras) {
            l.add('- ' + fecha(m.Fecha_entrega__c) + ': ' + entero(m.Cantidad__c) + ' x ' + m.Kit__r.Name);
        }
        return String.join(l, '\n');
    }

    private static String valor(String s) {
        return String.isBlank(s) ? 'sin datos' : s;
    }

    private static String entero(Decimal d) {
        return d == null ? '0' : String.valueOf(d.intValue());
    }

    private static String fecha(Date d) {
        return d == null ? 'sin fecha' : d.format();
    }
}
