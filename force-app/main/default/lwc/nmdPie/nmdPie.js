import { LightningElement } from 'lwc';
import basePath from '@salesforce/community/basePath';

export default class NmdPie extends LightningElement {
    rutas = {
        aviso: basePath + '/aviso-legal',
        privacidad: basePath + '/privacidad',
        cookies: basePath + '/cookies'
    };
}
