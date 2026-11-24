import { LightningElement } from 'lwc';
import basePath from '@salesforce/community/basePath';
import recurso from '@salesforce/resourceUrl/nmd_beverage';
import crearDrama from '@salesforce/apex/NMD_PortalFormularios.crearDrama';

function mensajeError(error) {
    return (error && error.body && error.body.message) || 'No hemos podido enviarlo. Inténtalo de nuevo en un momento.';
}

export default class NmdTengoUnDrama extends LightningElement {
    drama = recurso + '/drama.svg';
    rutas = { privacidad: basePath + '/privacidad' };
    tipos = [
        { label: 'Consulta de pedido', value: 'Consulta de pedido' },
        { label: 'Devolución', value: 'Devolución' },
        { label: 'Producto defectuoso', value: 'Producto defectuoso' },
        { label: 'Queja', value: 'Queja' }
    ];
    datos = { nombre: '', email: '', numeroPedido: '', tipo: '', descripcion: '', acepta: false, web: '' };
    numeroCaso;
    enviado = false;
    enviando = false;
    error;

    cambiar(e) { this.datos = { ...this.datos, [e.target.name]: e.target.value }; }
    cambiarCheck(e) { this.datos.acepta = e.target.checked; }
    cambiarTrampa(e) { this.datos.web = e.target.value; }

    async enviar(e) {
        e.preventDefault();
        const campos = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea')];
        const valido = campos.reduce((ok, c) => c.reportValidity() && ok, true);
        if (!valido) { return; }
        this.enviando = true;
        this.error = undefined;
        try {
            const d = this.datos;
            const numero = await crearDrama({
                nombre: d.nombre, email: d.email, numeroPedido: d.numeroPedido, tipo: d.tipo,
                descripcion: d.descripcion, aceptaPrivacidad: d.acepta, web: d.web
            });
            this.numeroCaso = numero;
            this.enviado = true;
        } catch (err) {
            this.error = mensajeError(err);
        } finally {
            this.enviando = false;
        }
    }
}
