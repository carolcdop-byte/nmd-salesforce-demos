import { LightningElement, api } from 'lwc';

const TITULOS = {"aviso": "Aviso legal", "privacidad": "Política de privacidad", "cookies": "Política de cookies"};
const SECCIONES = {
    "aviso": [
        {
            "titulo": "Quién está detrás",
            "texto": "Este sitio pertenece a No More Drama, una marca ficticia creada para un portfolio de Salesforce. No vende productos reales ni tiene sede, registro mercantil ni datos fiscales reales."
        },
        {
            "titulo": "Uso del sitio",
            "texto": "El contenido es de demostración. Puedes navegar, probar los formularios y hablar con Zen, pero ningún pedido, caso ni punto tiene validez fuera de la demo."
        },
        {
            "titulo": "Propiedad intelectual",
            "texto": "Las ilustraciones, el logo y los textos de No More Drama se han creado para este proyecto."
        },
        {
            "titulo": "Responsabilidad",
            "texto": "Al tratarse de una demostración, no se garantiza la disponibilidad del sitio ni la conservación de los datos introducidos."
        }
    ],
    "privacidad": [
        {
            "titulo": "Responsable",
            "texto": "No More Drama (marca ficticia, proyecto de portfolio). Por favor, no introduzcas datos personales reales."
        },
        {
            "titulo": "Qué datos tratamos",
            "texto": "Nombre, email, número de pedido y la descripción de tu caso cuando usas «Tengo un drama»; nombre, apellidos y email cuando te unes al club; y la conversación con Zen."
        },
        {
            "titulo": "Para qué",
            "texto": "Para gestionar tu caso o tu alta en el club Drama Points. Los casos los analiza un sistema de triaje con IA para decidir la prioridad; siempre los revisa una persona del equipo."
        },
        {
            "titulo": "Base legal",
            "texto": "Tu consentimiento, que das al marcar la casilla del formulario y puedes retirar cuando quieras."
        },
        {
            "titulo": "Cuánto tiempo",
            "texto": "Los datos de demostración se borran periódicamente."
        },
        {
            "titulo": "Tus derechos",
            "texto": "Puedes pedir acceso, rectificación, supresión, oposición, limitación y portabilidad escribiendo a nuestro equipo de atención al cliente desde «Tengo un drama»."
        }
    ],
    "cookies": [
        {
            "titulo": "Qué cookies usamos",
            "texto": "Solo las técnicas necesarias para que el sitio y el chat funcionen (sesión, idioma y seguridad). No usamos cookies publicitarias ni de análisis."
        },
        {
            "titulo": "Cómo desactivarlas",
            "texto": "Puedes bloquearlas en tu navegador, pero entonces el inicio de sesión y el chat con Zen pueden no funcionar."
        }
    ]
};

export default class NmdLegal extends LightningElement {
    @api tipo = 'aviso';
    get titulo() { return TITULOS[this.tipo] || TITULOS.aviso; }
    get secciones() { return SECCIONES[this.tipo] || SECCIONES.aviso; }
}
