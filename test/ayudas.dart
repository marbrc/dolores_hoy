// Ayudas compartidas por las pruebas (no es una prueba en sí).
import 'dart:convert';

import 'package:dolores_hoy/datos/cliente_seguro.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response jsonOk(Object cuerpo, [int estado = 200]) => http.Response.bytes(
    utf8.encode(jsonEncode(cuerpo)), estado,
    headers: {'content-type': 'application/json; charset=utf-8'});

ClienteSeguro seguro(Future<http.Response> Function(http.Request) manejador,
        {Duration? espera, int? maxBytes}) =>
    ClienteSeguro(MockClient(manejador),
        espera: espera ?? const Duration(seconds: 2),
        maxBytes: maxBytes ?? 1024 * 1024);

// Respuestas que imitan el formato documentado de cada API.
final jsonClima = {
  'current': {
    'time': '2026-10-29T14:00',
    'temperature_2m': 24.3,
    'relative_humidity_2m': 41,
    'weather_code': 1,
    'wind_speed_10m': 9.4,
  }
};

final jsonCambio = {
  'amount': 1.0,
  'base': 'MXN',
  'date': '2026-10-28',
  'rates': {'EUR': 0.05, 'USD': 0.0555},
};

final jsonFestivos = [
  {'date': '2026-01-01', 'localName': 'Año Nuevo', 'name': "New Year's Day"},
  {'date': '2026-09-16', 'localName': 'Día de la Independencia', 'name': 'Independence Day'},
  {'date': '2026-11-16', 'localName': 'Día de la Revolución', 'name': 'Revolution Day'},
  {'date': '2026-12-25', 'localName': 'Navidad', 'name': 'Christmas Day'},
];

final jsonWiki = {
  'title': 'Dolores Hidalgo',
  'extract': 'Dolores Hidalgo es una ciudad del estado de Guanajuato, México.',
  'thumbnail': {'source': 'https://upload.wikimedia.org/ejemplo.jpg', 'width': 320},
};

final jsonNasa = {
  'date': '2026-10-29',
  'title': 'Nebulosa de ejemplo',
  'explanation': 'Una imagen de prueba.',
  'media_type': 'image',
  'url': 'https://apod.nasa.gov/apod/image/ejemplo.jpg',
};

/// Servidor falso que enruta por dominio: las 5 APIs en una sola función.
Future<http.Response> servidorFalso(http.Request r) async {
  switch (r.url.host) {
    case 'api.open-meteo.com':
      return jsonOk(jsonClima);
    case 'api.frankfurter.dev':
      return jsonOk(jsonCambio);
    case 'date.nager.at':
      return jsonOk(jsonFestivos);
    case 'es.wikipedia.org':
      return jsonOk(jsonWiki);
    case 'api.nasa.gov':
      return jsonOk(jsonNasa);
  }
  return http.Response('', 404);
}
