/**
 * No More Drama (NMD) - Portal NMD Beverage: catálogo público de cervezas.
 * Lo usa el LWC nmdCatalogo (también para visitantes sin sesión).
 * Lee Producto_portal__c, la copia pública (sin precios) de las botellas Beverage que mantiene el
 * Flow NMD_Portal_Publicar_Producto: la licencia de usuario invitado no admite Product2.
 * without sharing: con el acceso seguro de invitados activado, el invitado no ve ningún registro
 * por sharing; el catálogo es público por diseño y solo se devuelven nombre, código y descripción.
 * WITH SYSTEM_MODE explícito: desde la API 67 el Apex usa modo usuario por defecto y el invitado no
 * tiene permisos sobre el objeto (no se le dan: solo lee a través de esta clase).
 */
public without sharing class NMD_PortalCatalogo {

    public class Cerveza {
        @AuraEnabled public String codigo;
        @AuraEnabled public String nombre;
        @AuraEnabled public String descripcion;
    }

    public class ReglasClub {
        @AuraEnabled public Integer puntosPorPedido;
        @AuraEnabled public Integer puntosPorEuro;
        @AuraEnabled public Integer umbralZen;
        @AuraEnabled public Integer umbralDramaFree;
    }

    @AuraEnabled(cacheable=true)
    public static List<Cerveza> getCervezas() {
        List<Cerveza> out = new List<Cerveza>();
        for (Producto_portal__c p : [SELECT Codigo__c, Name, Descripcion__c FROM Producto_portal__c
                                     WHERE Activo__c = true WITH SYSTEM_MODE ORDER BY Codigo__c LIMIT 20]) {
            Cerveza c = new Cerveza();
            c.codigo = p.Codigo__c;
            c.nombre = p.Name;
            c.descripcion = p.Descripcion__c;
            out.add(c);
        }
        return out;
    }

    /** Reglas del club Drama Points (NMD_Club_Config__mdt.General), para la página del club. */
    @AuraEnabled(cacheable=true)
    public static ReglasClub getReglasClub() {
        NMD_Club_Config__mdt cfg = NMD_Club_Config__mdt.getInstance('General');
        ReglasClub r = new ReglasClub();
        r.puntosPorPedido = cfg == null ? 50 : cfg.Puntos_por_pedido__c.intValue();
        r.puntosPorEuro = cfg == null ? 1 : cfg.Puntos_por_euro__c.intValue();
        r.umbralZen = cfg == null ? 300 : cfg.Umbral_Zen__c.intValue();
        r.umbralDramaFree = cfg == null ? 800 : cfg.Umbral_Drama_Free__c.intValue();
        return r;
    }
}
