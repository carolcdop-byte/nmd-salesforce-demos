/**
 * No More Drama (NMD) - Portal NMD Beverage: "Mi zona" del cliente registrado.
 * Devuelve el club (puntos, nivel, cuánto falta), los pedidos y los casos del contacto del
 * usuario conectado.
 * Doble protección: las consultas filtran por el contacto del usuario Y se ejecutan en modo
 * usuario (WITH USER_MODE), así que además se aplican los sharing sets del portal y los
 * permisos del perfil. Un cliente nunca ve datos de otro, aunque estén en la misma cuenta.
 */
public with sharing class NMD_PortalMiZona {

    public class Linea {
        @AuraEnabled public String producto;
        @AuraEnabled public Decimal cantidad;
    }

    public class Pedido {
        @AuraEnabled public String numero;
        @AuraEnabled public Date fecha;
        @AuraEnabled public String estadoEnvio;
        @AuraEnabled public Date fechaPrevista;
        @AuraEnabled public Decimal importe;
        @AuraEnabled public Decimal puntos;
        @AuraEnabled public List<Linea> lineas = new List<Linea>();
    }

    public class Caso {
        @AuraEnabled public String numero;
        @AuraEnabled public String asunto;
        @AuraEnabled public String estado;
        @AuraEnabled public String tipo;
        @AuraEnabled public Datetime fecha;
    }

    public class Resumen {
        @AuraEnabled public String nombre;
        @AuraEnabled public Boolean socio;
        @AuraEnabled public Decimal puntos;
        @AuraEnabled public String nivel;
        @AuraEnabled public Decimal faltan;
        @AuraEnabled public String siguienteNivel;
        @AuraEnabled public List<Pedido> pedidos = new List<Pedido>();
        @AuraEnabled public List<Caso> casos = new List<Caso>();
    }

    @AuraEnabled
    public static Resumen getMiZona() {
        Id contactId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;
        if (contactId == null) {
            AuraHandledException e = new AuraHandledException('Mi zona es solo para clientes registrados.');
            e.setMessage('Mi zona es solo para clientes registrados.');
            throw e;
        }
        Resumen r = new Resumen();
        Contact c = [SELECT FirstName, Miembro_club__c, Drama_Points__c, Nivel_club__c, Puntos_siguiente_nivel__c
                     FROM Contact WHERE Id = :contactId WITH USER_MODE];
        r.nombre = c.FirstName;
        r.socio = c.Miembro_club__c;
        r.puntos = c.Drama_Points__c == null ? 0 : c.Drama_Points__c;
        r.nivel = c.Nivel_club__c;
        r.faltan = c.Puntos_siguiente_nivel__c;
        r.siguienteNivel = c.Nivel_club__c == 'Tranqui' ? 'Zen' : (c.Nivel_club__c == 'Zen' ? 'Drama Free' : null);

        for (Order o : [SELECT OrderNumber, EffectiveDate, Estado_envio__c, Fecha_prevista_entrega__c, TotalAmount, Drama_Points__c,
                               (SELECT Product2.Name, Quantity FROM OrderItems ORDER BY Product2.Name)
                        FROM Order WHERE BillToContactId = :contactId WITH USER_MODE ORDER BY EffectiveDate DESC LIMIT 50]) {
            Pedido p = new Pedido();
            p.numero = o.OrderNumber;
            p.fecha = o.EffectiveDate;
            p.estadoEnvio = o.Estado_envio__c;
            p.fechaPrevista = o.Fecha_prevista_entrega__c;
            p.importe = o.TotalAmount;
            p.puntos = o.Drama_Points__c;
            for (OrderItem i : o.OrderItems) {
                Linea l = new Linea();
                l.producto = i.Product2.Name;
                l.cantidad = i.Quantity;
                p.lineas.add(l);
            }
            r.pedidos.add(p);
        }
        for (Case k : [SELECT CaseNumber, Subject, toLabel(Status), toLabel(Type), CreatedDate FROM Case
                       WHERE ContactId = :contactId WITH USER_MODE ORDER BY CreatedDate DESC LIMIT 50]) {
            Caso cs = new Caso();
            cs.numero = k.CaseNumber;
            cs.asunto = k.Subject;
            cs.estado = k.Status;
            cs.tipo = k.Type;
            cs.fecha = k.CreatedDate;
            r.casos.add(cs);
        }
        return r;
    }
}
