/**
 * No More Drama (NMD) - Triaje NMD.
 * Convierte la respuesta JSON de la plantilla de Prompt Builder NMD_Detector_Drama en los
 * valores del triaje: nivel de drama (1-5), categoría, resumen, guía para el agente y, para
 * niveles 1-2, borrador de email. Lo usan el Flow NMD_Triaje_IA (al crear el caso) y el
 * Flow de pantalla NMD_Detectar_Drama (botón Detectar drama).
 *
 * No llama al modelo ni escribe en la base de datos: solo interpreta y valida el texto.
 * Si la respuesta no es válida, devuelve exito = false y un mensaje; los Flows deciden qué hacer
 * (el triaje automático marca el caso como "Triaje IA fallido").
 */
public with sharing class NMD_DramaParser {

    @TestVisible static final Integer MAX_RESUMEN = 1000;
    @TestVisible static final Integer MAX_GUIA = 2000;
    @TestVisible static final Integer MAX_BORRADOR = 4000;
    @TestVisible static final List<String> CATEGORIAS = new List<String>{
        'Consulta de pedido', 'Devolución', 'Producto defectuoso', 'Queja' };

    public class Entrada {
        @InvocableVariable(label='Respuesta de la IA' description='Texto devuelto por la plantilla NMD_Detector_Drama' required=true)
        public String textoIA;
    }

    public class Salida {
        @InvocableVariable(label='Éxito' description='true si la respuesta de la IA es válida')
        public Boolean exito = false;
        @InvocableVariable(label='Nivel de drama' description='Número entero entre 1 y 5')
        public Integer nivel;
        @InvocableVariable(label='Categoría' description='Consulta de pedido, Devolución, Producto defectuoso o Queja')
        public String categoria;
        @InvocableVariable(label='Resumen')
        public String resumen;
        @InvocableVariable(label='Guía para el agente' description='3-4 puntos, uno por línea')
        public String guia;
        @InvocableVariable(label='Borrador de email' description='Solo para niveles 1-2; vacío en el resto')
        public String borrador;
        @InvocableVariable(label='Mensaje de error')
        public String mensajeError;
    }

    @InvocableMethod(label='NMD: Interpretar triaje IA'
        description='Valida el JSON de la plantilla NMD_Detector_Drama y devuelve nivel, categoría, resumen, guía y borrador.'
        category='No More Drama')
    public static List<Salida> interpretar(List<Entrada> entradas) {
        List<Salida> salidas = new List<Salida>();
        for (Entrada e : entradas) {
            salidas.add(interpretarTexto(e == null ? null : e.textoIA));
        }
        return salidas;
    }

    @TestVisible
    static Salida interpretarTexto(String texto) {
        Salida s = new Salida();
        if (String.isBlank(texto)) {
            return error(s, 'La IA no ha devuelto ninguna respuesta.');
        }
        // El modelo debería devolver solo JSON, pero toleramos texto o bloques de código alrededor.
        Integer inicio = texto.indexOf('{');
        Integer fin = texto.lastIndexOf('}');
        if (inicio < 0 || fin <= inicio) {
            return error(s, 'La respuesta de la IA no tiene el formato esperado.');
        }
        Map<String, Object> datos;
        try {
            datos = (Map<String, Object>) JSON.deserializeUntyped(texto.substring(inicio, fin + 1));
        } catch (Exception ex) {
            return error(s, 'La respuesta de la IA no es un JSON válido.');
        }

        Integer nivel = aEntero(datos.get('nivel'));
        if (nivel == null) {
            return error(s, 'La IA no ha indicado un nivel de drama válido.');
        }
        s.nivel = Math.max(1, Math.min(5, nivel));

        s.categoria = categoriaValida(datos.get('categoria'));
        if (s.categoria == null) {
            return error(s, 'La IA no ha indicado una categoría válida.');
        }

        s.resumen = recortar(datos.get('resumen'), MAX_RESUMEN);
        if (String.isBlank(s.resumen)) {
            return error(s, 'La IA no ha devuelto el resumen.');
        }

        s.guia = recortar(guiaComoTexto(datos.get('guia')), MAX_GUIA);
        if (String.isBlank(s.guia)) {
            return error(s, 'La IA no ha devuelto la guía para el agente.');
        }

        // El borrador solo tiene sentido en niveles 1-2: en el resto se descarta aunque venga.
        if (s.nivel <= 2) {
            s.borrador = recortar(datos.get('borrador'), MAX_BORRADOR);
            if (String.isBlank(s.borrador)) {
                return error(s, 'La IA no ha devuelto el borrador de email para un caso de nivel ' + s.nivel + '.');
            }
        }
        s.exito = true;
        return s;
    }

    private static Integer aEntero(Object valor) {
        if (valor == null) {
            return null;
        }
        try {
            return Decimal.valueOf(String.valueOf(valor).trim()).round(System.RoundingMode.HALF_UP).intValue();
        } catch (Exception ex) {
            return null;
        }
    }

    private static String categoriaValida(Object valor) {
        if (valor == null) {
            return null;
        }
        String texto = String.valueOf(valor).trim();
        for (String c : CATEGORIAS) {
            if (c.equalsIgnoreCase(texto)) {
                return c;
            }
        }
        return null;
    }

    private static String guiaComoTexto(Object valor) {
        if (valor == null) {
            return null;
        }
        List<String> puntos = new List<String>();
        if (valor instanceof List<Object>) {
            for (Object o : (List<Object>) valor) {
                if (o != null && String.isNotBlank(String.valueOf(o))) {
                    puntos.add('• ' + String.valueOf(o).trim());
                }
            }
            return puntos.isEmpty() ? null : String.join(puntos, '\n');
        }
        return String.valueOf(valor).trim();
    }

    private static String recortar(Object valor, Integer maximo) {
        if (valor == null) {
            return null;
        }
        String texto = String.valueOf(valor).trim();
        return texto.length() > maximo ? texto.left(maximo - 1) + '…' : texto;
    }

    private static Salida error(Salida s, String mensaje) {
        Salida vacia = new Salida();
        vacia.exito = false;
        vacia.mensajeError = mensaje;
        return vacia;
    }
}
