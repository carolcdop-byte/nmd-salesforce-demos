import { LightningElement } from 'lwc';
import isGuest from '@salesforce/user/isGuest';
import basePath from '@salesforce/community/basePath';
import recurso from '@salesforce/resourceUrl/nmd_beverage';

export default class NmdCabecera extends LightningElement {
    esInvitado = isGuest;
    logo = recurso + '/logo.png';
    rutas = {
        inicio: basePath + '/',
        login: basePath + '/login',
        miZona: basePath + '/mi-zona',
        salir: basePath + '/vforcesite/secur/logout.jsp'
    };

    get enlaces() {
        const actual = window.location.pathname.replace(/\/$/, '');
        return [
            ['Inicio', '/'], ['Cervezas', '/cervezas'], ['Club Drama Points', '/club'],
            ['Tengo un drama', '/tengo-un-drama'], ['Sobre nosotros', '/sobre-nmd']
        ].map(([texto, ruta]) => {
            const href = basePath + ruta;
            const activo = actual === href.replace(/\/$/, '');
            return { texto, href, clase: activo ? 'enlace activo' : 'enlace', actual: activo ? 'page' : null };
        });
    }
}
