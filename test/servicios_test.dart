import 'package:dolores_hoy/datos/config_claves.dart';
import 'package:dolores_hoy/datos/servicios.dart';
import 'package:dolores_hoy/dominio/excepciones.dart';
import 'package:dolores_hoy/dominio/modelos.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayudas.dart';

void main() {
  group('API 1 · Clima (Open-Meteo)', () {
    test('convierte la respuesta en Clima', () async {
      final s = ServicioClima(seguro((req) async {
        expect(req.url.host, 'api.open-meteo.com');
        expect(req.url.queryParameters['latitude'], '21.1561');
        return jsonOk(jsonClima);
      }));
      final c = await s.actual();
      expect(c.temperatura, 24.3);
      expect(c.humedad, 41);
      expect(c.codigo, 1);
    });

    test('rechaza coordenadas fuera de rango', () {
      final s = ServicioClima(seguro((_) async => jsonOk(jsonClima)));
      expect(s.actual(lat: 200), throwsA(isA<EntradaInvalidaException>()));
    });

    test('si falta el bloque current lanza RespuestaInvalida', () {
      final s = ServicioClima(seguro((_) async => jsonOk({'otra': 1})));
      expect(s.actual(), throwsA(isA<RespuestaInvalidaException>()));
    });

    test('describirClima traduce códigos', () {
      expect(describirClima(0).$2, 'Despejado');
      expect(describirClima(63).$2, 'Lluvia');
      expect(describirClima(95).$2, 'Tormenta');
    });
  });

  group('API 2 · Tipo de cambio (Frankfurter)', () {
    test('calcula pesos por dólar invirtiendo la tasa', () async {
      final s = ServicioCambio(seguro((_) async => jsonOk({
            'base': 'MXN', 'date': '2026-10-28', 'rates': {'USD': 0.05, 'EUR': 0.04}
          })));
      final t = await s.deMxn();
      expect(t.pesosPorUnidad('USD'), closeTo(20.0, 0.0001));
      expect(t.pesosPorUnidad('EUR'), closeTo(25.0, 0.0001));
    });
  });

  group('API 3 · Festivos (Nager.Date)', () {
    test('devuelve solo los próximos, en orden', () async {
      final s = ServicioFestivos(seguro((req) async {
        expect(req.url.path, '/api/v3/PublicHolidays/2026/MX');
        return jsonOk(jsonFestivos);
      }));
      final r = await s.proximos(hoy: DateTime(2026, 10, 29), cuantos: 2);
      expect(r.map((f) => f.nombre), ['Día de la Revolución', 'Navidad']);
    });

    test('incluye el festivo de hoy mismo', () async {
      final s = ServicioFestivos(seguro((_) async => jsonOk(jsonFestivos)));
      final r = await s.proximos(hoy: DateTime(2026, 12, 25), cuantos: 5);
      expect(r.single.nombre, 'Navidad');
    });

    test('rechaza años absurdos', () {
      final s = ServicioFestivos(seguro((_) async => jsonOk(jsonFestivos)));
      expect(s.proximos(anio: 3000), throwsA(isA<EntradaInvalidaException>()));
    });
  });

  group('API 4 · Wikipedia', () {
    test('pide el resumen del tema con guiones bajos', () async {
      final s = ServicioWikipedia(seguro((req) async {
        expect(req.url.host, 'es.wikipedia.org');
        expect(req.url.pathSegments.last, 'Dolores_Hidalgo');
        return jsonOk(jsonWiki);
      }));
      final r = await s.resumen('Dolores Hidalgo');
      expect(r.titulo, 'Dolores Hidalgo');
      expect(r.urlImagen, startsWith('https://'));
    });

    test('un tema con "/" NO puede escapar de la ruta (path injection)', () async {
      final s = ServicioWikipedia(seguro((req) async {
        // Siempre exactamente 5 segmentos: api/rest_v1/page/summary/<tema>
        expect(req.url.pathSegments.length, 5);
        expect(req.url.pathSegments.last, '../../admin');
        return jsonOk(jsonWiki);
      }));
      await s.resumen('../../admin');
    });

    test('rechaza vacío, demasiado largo y caracteres de control', () {
      expect(() => ServicioWikipedia.normalizarTema('   '),
          throwsA(isA<EntradaInvalidaException>()));
      expect(() => ServicioWikipedia.normalizarTema('a' * 81),
          throwsA(isA<EntradaInvalidaException>()));
      expect(() => ServicioWikipedia.normalizarTema('hola\nmundo'),
          throwsA(isA<EntradaInvalidaException>()));
    });

    test('ignora miniaturas que no sean https', () async {
      final s = ServicioWikipedia(seguro((_) async => jsonOk({
            'title': 'X', 'extract': 'Y', 'thumbnail': {'source': 'http://inseguro.com/a.jpg'}
          })));
      expect((await s.resumen('X')).urlImagen, isNull);
    });
  });

  group('API 5 · NASA APOD (con clave)', () {
    test('manda la clave como parámetro api_key', () async {
      final s = ServicioNasa(
          seguro((req) async {
            expect(req.url.host, 'api.nasa.gov');
            expect(req.url.queryParameters['api_key'], 'MI_CLAVE');
            return jsonOk(jsonNasa);
          }),
          const ConfigClaves(nasa: 'MI_CLAVE'));
      final f = await s.fotoDelDia();
      expect(f.titulo, 'Nebulosa de ejemplo');
      expect(f.urlImagen, isNotNull);
    });

    test('sin clave ni siquiera hace la petición', () {
      var llamado = false;
      final s = ServicioNasa(
          seguro((_) async {
            llamado = true;
            return jsonOk(jsonNasa);
          }),
          const ConfigClaves(nasa: '  '));
      expect(s.fotoDelDia(), throwsA(isA<ClaveFaltanteException>()));
      expect(llamado, false);
    });

    test('si la NASA publica un video, no hay imagen que mostrar', () async {
      final s = ServicioNasa(
          seguro((_) async => jsonOk({...jsonNasa, 'media_type': 'video', 'url': 'https://youtube.com/x'})),
          const ConfigClaves(nasa: 'K'));
      expect((await s.fotoDelDia()).urlImagen, isNull);
    });

    test('una URL de imagen http:// se descarta', () async {
      final s = ServicioNasa(
          seguro((_) async => jsonOk({...jsonNasa, 'url': 'http://apod.nasa.gov/a.jpg'})),
          const ConfigClaves(nasa: 'K'));
      expect((await s.fotoDelDia()).urlImagen, isNull);
    });

    test('403 explica que la clave no es válida', () {
      final s = ServicioNasa(
          seguro((_) async => jsonOk({}, 403)), const ConfigClaves(nasa: 'MALA'));
      expect(s.fotoDelDia(),
          throwsA(isA<ErrorServidorException>().having((e) => e.toString(), 'm', contains('clave'))));
    });
  });

}
