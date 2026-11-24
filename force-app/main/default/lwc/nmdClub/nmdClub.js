import { LightningElement, wire } from 'lwc';
import isGuest from '@salesforce/user/isGuest';
import basePath from '@salesforce/community/basePath';
import recurso from '@salesforce/resourceUrl/nmd_beverage';
import getReglasClub from '@salesforce/apex/NMD_PortalCatalogo.getReglasClub';
import unirseAlClub from '@salesforce/apex/NMD_PortalFormularios.unirseAlClub';

function mensajeError(error) {
    return (error && error.body && error.body.message) || 'No hemos podido enviarlo. Inténtalo de nuevo en un momento.';
}

export default class NmdClub extends LightningElement {
    esInvitado = isGuest;
    club = recurso + '/club.svg';
    rutas = { miZona: basePath + '/mi-zona', privacidad: basePath + '/privacidad' };
    datos = { nombre: '', apellidos: '', email: '', acepta: false, web: '' };
    enviado = false;
    enviando = false;
    error;

    reglas;

    @wire(getReglasClub)
    cargarReglas({ data }) {
        if (data) { this.reglas = data; }
    }

    cambiar(e) { this.datos[e.target.name] = e.target.value; }
    cambiarCheck(e) { this.datos.acepta = e.target.checked; }
    cambiarTrampa(e) { this.datos.web = e.target.value; }

    async enviar(e) {
        e.preventDefault();
        const campos = [...this.template.querySelectorAll('lightning-input')];
        const valido = campos.reduce((ok, c) => c.reportValidity() && ok, true);
        if (!valido) { return; }
        this.enviando = true;
        this.error = undefined;
        try {
            await unirseAlClub({ ...this.datos, aceptaPrivacidad: this.datos.acepta });
            this.enviado = true;
        } catch (err) {
            this.error = mensajeError(err);
        } finally {
            this.enviando = false;
        }
    }
}
