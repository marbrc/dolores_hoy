/// Solo aceptamos URLs https (por ejemplo para imágenes que vienen de una API).
String? soloHttps(Object? url) =>
    url is String && url.startsWith('https://') ? url : null;

class Clima {
  final double temperatura;
  final int humedad;
  final double viento;
  final int codigo;
  const Clima(this.temperatura, this.humedad, this.viento, this.codigo);

  factory Clima.desdeJson(Map<String, dynamic> json) {
    final c = json['current'] as Map<String, dynamic>;
    return Clima(
      (c['temperature_2m'] as num).toDouble(),
      (c['relative_humidity_2m'] as num).round(),
      (c['wind_speed_10m'] as num).toDouble(),
      (c['weather_code'] as num).toInt(),
    );
  }
}

/// Convierte el código WMO de Open-Meteo en emoji y texto.
(String, String) describirClima(int codigo) {
  if (codigo == 0) return ('☀️', 'Despejado');
  if (codigo <= 3) return ('⛅', 'Parcialmente nublado');
  if (codigo == 45 || codigo == 48) return ('🌫️', 'Niebla');
  if (codigo >= 51 && codigo <= 57) return ('🌦️', 'Llovizna');
  if (codigo >= 61 && codigo <= 67) return ('🌧️', 'Lluvia');
  if (codigo >= 71 && codigo <= 77) return ('❄️', 'Nieve');
  if (codigo >= 80 && codigo <= 82) return ('🌧️', 'Chubascos');
  if (codigo >= 95) return ('⛈️', 'Tormenta');
  return ('🌡️', 'Clima variable');
}

class TipoCambio {
  final String base;
  final DateTime fecha;
  final Map<String, double> tasas;
  const TipoCambio(this.base, this.fecha, this.tasas);

  factory TipoCambio.desdeJson(Map<String, dynamic> json) => TipoCambio(
        json['base'] as String,
        DateTime.parse(json['date'] as String),
        (json['rates'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
      );

  /// Cuántos pesos cuesta 1 unidad de [moneda]. Si 1 MXN = 0.05 USD,
  /// entonces 1 USD = 1 / 0.05 = 20 MXN.
  double pesosPorUnidad(String moneda) => 1 / tasas[moneda]!;
}

class Festivo {
  final DateTime fecha;
  final String nombre;
  const Festivo(this.fecha, this.nombre);

  factory Festivo.desdeJson(Map<String, dynamic> json) =>
      Festivo(DateTime.parse(json['date'] as String), json['localName'] as String);
}

class ResumenWiki {
  final String titulo;
  final String extracto;
  final String? urlImagen;
  const ResumenWiki(this.titulo, this.extracto, this.urlImagen);

  factory ResumenWiki.desdeJson(Map<String, dynamic> json) {
    final miniatura = json['thumbnail'] as Map<String, dynamic>?;
    return ResumenWiki(
      json['title'] as String,
      json['extract'] as String,
      soloHttps(miniatura?['source']),
    );
  }
}

class FotoAstronomica {
  final String titulo;
  final String explicacion;
  final DateTime fecha;
  final String? urlImagen; // null si es video o la URL no es https

  const FotoAstronomica(this.titulo, this.explicacion, this.fecha, this.urlImagen);

  factory FotoAstronomica.desdeJson(Map<String, dynamic> json) => FotoAstronomica(
        json['title'] as String,
        json['explanation'] as String,
        DateTime.parse(json['date'] as String),
        json['media_type'] == 'image' ? soloHttps(json['url']) : null,
      );
}
