import 'dart:io';

import 'package:dolores_hoy/datos/cliente_seguro.dart';
import 'package:dolores_hoy/dominio/excepciones.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'ayudas.dart';

void main() {
  final https = Uri.parse('https://ejemplo.com/datos');

  test('rechaza direcciones http:// sin siquiera hacer la petición', () {
    var llamado = false;
    final c = seguro((_) async {
      llamado = true;
      return jsonOk({});
    });
    expect(c.obtenerJson(Uri.parse('http://ejemplo.com')),
        throwsA(isA<ConexionInseguraException>()));
    expect(llamado, false);
  });

  test('devuelve el JSON decodificado (con acentos)', () async {
    final c = seguro((_) async => jsonOk({'nombre': 'Año Nuevo'}));
    final r = await c.obtenerJson(https) as Map<String, dynamic>;
    expect(r['nombre'], 'Año Nuevo');
  });

  test('envía cabeceras Accept y User-Agent', () async {
    final c = seguro((req) async {
      expect(req.headers['Accept'], 'application/json');
      expect(req.headers['User-Agent'], contains('DoloresHoy'));
      return jsonOk({});
    });
    await c.obtenerJson(https);
  });

  test('429 produce un mensaje de límite de peticiones', () {
    final c = seguro((_) async => jsonOk({}, 429));
    expect(
        c.obtenerJson(https),
        throwsA(isA<ErrorServidorException>().having((e) => e.toString(), 'mensaje', contains('Demasiadas'))));
  });

  test('500 lanza ErrorServidorException con el código', () {
    final c = seguro((_) async => jsonOk({}, 500));
    expect(c.obtenerJson(https),
        throwsA(isA<ErrorServidorException>().having((e) => e.codigo, 'codigo', 500)));
  });

  test('sin red lanza SinConexionException', () {
    final c = seguro((_) async => throw const SocketException('x'));
    expect(c.obtenerJson(https), throwsA(isA<SinConexionException>()));
  });

  test('timeout se trata como sin conexión', () {
    final c = seguro((_) async {
      await Future.delayed(const Duration(milliseconds: 200));
      return jsonOk({});
    }, espera: const Duration(milliseconds: 20));
    expect(c.obtenerJson(https), throwsA(isA<SinConexionException>()));
  });

  test('descarta respuestas más grandes que el límite', () {
    final c = seguro((_) async => jsonOk({'relleno': 'x' * 500}), maxBytes: 100);
    expect(c.obtenerJson(https), throwsA(isA<RespuestaDemasiadoGrandeException>()));
  });

  test('HTML en lugar de JSON lanza RespuestaInvalidaException', () {
    final c = seguro((_) async => http.Response('<html>login wifi</html>', 200));
    expect(c.obtenerJson(https), throwsA(isA<RespuestaInvalidaException>()));
  });

  group('redactar (para logs)', () {
    test('oculta la clave pero conserva el resto', () {
      final u = Uri.parse('https://api.nasa.gov/planetary/apod?api_key=SECRETO123&dia=hoy');
      final texto = ClienteSeguro.redactar(u);
      expect(texto, isNot(contains('SECRETO123')));
      expect(texto, contains('api_key=***'));
      expect(texto, contains('dia=hoy'));
    });

    test('una URL sin parámetros queda igual', () {
      expect(ClienteSeguro.redactar(https), 'https://ejemplo.com/datos');
    });
  });
}
