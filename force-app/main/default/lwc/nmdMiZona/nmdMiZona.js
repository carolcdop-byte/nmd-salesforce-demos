import { LightningElement } from 'lwc';
import basePath from '@salesforce/community/basePath';
import getMiZona from '@salesforce/apex/NMD_PortalMiZona.getMiZona';

const CLASES = { Entregado: 'estado ok', Enviado: 'estado camino', Pendiente: 'estado pendiente', Retrasado: 'estado retraso' };

export default class NmdMiZona extends LightningElement {
    datos;
    error;
    cargando = true;
    rutas = { drama: basePath + '/tengo-un-drama' };

    async connectedCallback() {
        try {
            this.datos = await getMiZona();
        } catch (err) {
            this.error = (err && err.body && err.body.message) || 'No hemos podido cargar tu zona.';
        } finally {
            this.cargando = false;
        }
    }

    get pedidos() {
        return (this.datos.pedidos || []).map((p) => ({
            ...p,
            productos: (p.lineas || []).map((l) => l.cantidad + ' × ' + l.producto).join(', '),
            claseEstado: CLASES[p.estadoEnvio] || 'estado',
            textoPuntos: p.puntos ? '+' + p.puntos : '—'
        }));
    }
    get casos() { return this.datos.casos || []; }
    get hayPedidos() { return this.pedidos.length > 0; }
    get hayCasos() { return this.casos.length > 0; }

    get porcentaje() {
        const d = this.datos;
        if (!d || !d.siguienteNivel) { return 100; }
        const total = d.puntos + d.faltan;
        return total > 0 ? Math.round((d.puntos * 100) / total) : 0;
    }
    get estiloBarra() { return 'width:' + this.porcentaje + '%'; }
}
