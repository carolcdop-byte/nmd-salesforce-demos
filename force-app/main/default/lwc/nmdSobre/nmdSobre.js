import { LightningElement } from 'lwc';
import recurso from '@salesforce/resourceUrl/nmd_beverage';

export default class NmdSobre extends LightningElement {
    zen = recurso + '/zen.svg';
}
