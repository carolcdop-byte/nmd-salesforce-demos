import { LightningElement, wire } from 'lwc';
import getCervezas from '@salesforce/apex/NMD_PortalCatalogo.getCervezas';
import recurso from '@salesforce/resourceUrl/nmd_beverage';

export default class NmdCatalogo extends LightningElement {
    cervezas = [];
    error;

    @wire(getCervezas)
    cargar({ data, error }) {
        if (data) {
            this.cervezas = data.map((c) => ({
                ...c,
                imagen: recurso + '/' + c.codigo.toLowerCase() + '.svg',
                alt: 'Ilustración de ' + c.nombre
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
    }
}
