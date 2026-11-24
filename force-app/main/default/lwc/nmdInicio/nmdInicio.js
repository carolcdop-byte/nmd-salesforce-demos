import { LightningElement } from 'lwc';
import basePath from '@salesforce/community/basePath';
import recurso from '@salesforce/resourceUrl/nmd_beverage';

export default class NmdInicio extends LightningElement {
    hero = recurso + '/hero.svg';
    botella = recurso + '/nmd-bev-002.svg';
    club = recurso + '/club.svg';
    drama = recurso + '/drama.svg';
    zen = recurso + '/zen.svg';
    rutas = { cervezas: basePath + '/cervezas', club: basePath + '/club', drama: basePath + '/tengo-un-drama' };
}
