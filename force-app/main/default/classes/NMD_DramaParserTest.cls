@IsTest
private class NMD_DramaParserTest {

    private static NMD_DramaParser.Salida ejecutar(String texto) {
        NMD_DramaParser.Entrada e = new NMD_DramaParser.Entrada();
        e.textoIA = texto;
        List<NMD_DramaParser.Salida> res = NMD_DramaParser.interpretar(new List<NMD_DramaParser.Entrada>{ e });
        Assert.areEqual(1, res.size(), 'Una salida por entrada');
        return res[0];
    }

    private static String json(Object nivel, Object categoria, Object resumen, Object guia, Object borrador) {
        Map<String, Object> m = new Map<String, Object>();
        if (nivel != null) { m.put('nivel', nivel); }
        if (categoria != null) { m.put('categoria', categoria); }
        if (resumen != null) { m.put('resumen', resumen); }
        if (guia != null) { m.put('guia', guia); }
        if (borrador != null) { m.put('borrador', borrador); }
        return JSON.serialize(m);
    }

    private static final List<String> GUIA = new List<String>{ 'Reconoce el retraso.', 'Ofrece consultar el envío.', 'No prometas fechas.', 'Tono sereno.' };

    @IsTest
    static void nivelAltoSinBorrador() {
        NMD_DramaParser.Salida s = ejecutar(json(5, 'Queja', 'Cliente furioso.', GUIA, 'esto se ignora'));
        Assert.isTrue(s.exito, 'Debe aceptar un JSON válido');
        Assert.areEqual(5, s.nivel);
        Assert.areEqual('Queja', s.categoria);
        Assert.areEqual('Cliente furioso.', s.resumen);
        Assert.isTrue(s.guia.startsWith('• Reconoce el retraso.\n• Ofrece'), 'La guía se convierte en viñetas');
        Assert.isNull(s.borrador, 'En niveles 3-5 no hay borrador');
        Assert.isNull(s.mensajeError);
    }

    @IsTest
    static void nivelBajoConBorrador() {
        NMD_DramaParser.Salida s = ejecutar(json(1, 'consulta de pedido', 'Duda.', GUIA, 'Hola, Manuel: ...'));
        Assert.isTrue(s.exito);
        Assert.areEqual('Consulta de pedido', s.categoria, 'Normaliza mayúsculas y minúsculas');
        Assert.areEqual('Hola, Manuel: ...', s.borrador);
    }

    @IsTest
    static void toleraTextoYBloqueDeCodigoYGuiaComoTexto() {
        NMD_DramaParser.Salida s = ejecutar('Aquí tienes:\n```json\n{"nivel": "3", "categoria": "Producto defectuoso", "resumen": "a", "guia": "Un solo texto", "borrador": ""}\n```');
        Assert.isTrue(s.exito, 'Debe extraer el JSON aunque venga envuelto');
        Assert.areEqual(3, s.nivel, 'Acepta el nivel como texto');
        Assert.areEqual('Un solo texto', s.guia);
    }

    @IsTest
    static void nivelFueraDeRangoSeAjusta() {
        Assert.areEqual(5, ejecutar(json(9, 'Queja', 'a', GUIA, null)).nivel);
        Assert.areEqual(1, ejecutar(json(0, 'Queja', 'a', GUIA, 'b')).nivel);
        Assert.areEqual(3, ejecutar(json(2.6, 'Queja', 'a', GUIA, null)).nivel);
    }

    @IsTest
    static void textosLargosSeRecortan() {
        String largo = 'x'.repeat(NMD_DramaParser.MAX_BORRADOR + 50);
        NMD_DramaParser.Salida s = ejecutar(json(2, 'Devolución', largo, largo, largo));
        Assert.isTrue(s.exito);
        Assert.areEqual(NMD_DramaParser.MAX_RESUMEN, s.resumen.length());
        Assert.areEqual(NMD_DramaParser.MAX_GUIA, s.guia.length());
        Assert.areEqual(NMD_DramaParser.MAX_BORRADOR, s.borrador.length());
    }

    @IsTest
    static void respuestasInvalidasDevuelvenError() {
        List<String> invalidas = new List<String>{
            null,
            '   ',
            'Lo siento, no puedo ayudar con eso.',
            '{"nivel": 3, "categoria": "Queja", "resumen": }',
            json(null, 'Queja', 'a', GUIA, null),
            json('alto', 'Queja', 'a', GUIA, null),
            json(3, 'Reclamación', 'a', GUIA, null),
            json(3, null, 'a', GUIA, null),
            json(3, 'Queja', '', GUIA, null),
            json(3, 'Queja', 'a', new List<String>(), null),
            json(3, 'Queja', 'a', null, null),
            json(2, 'Queja', 'a', GUIA, ''),
            json(1, 'Queja', 'a', GUIA, null)
        };
        for (String t : invalidas) {
            NMD_DramaParser.Salida s = ejecutar(t);
            Assert.isFalse(s.exito, 'Debe rechazar: ' + t);
            Assert.isNotNull(s.mensajeError, 'Debe explicar el error: ' + t);
            Assert.isNull(s.nivel, 'No debe devolver valores parciales: ' + t);
            Assert.isNull(s.categoria, 'No debe devolver valores parciales: ' + t);
        }
    }
}
