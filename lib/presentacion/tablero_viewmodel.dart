import 'package:flutter/foundation.dart';

import '../datos/servicios.dart';
import '../dominio/excepciones.dart';
import '../dominio/modelos.dart';

enum Estado { cargando, listo, error }

/// Estado de UNA tarjeta. Cada API tiene el suyo: si una falla, las demás viven.
class Carga<T> {
  final Estado estado;
  final T? dato;
  final String? error;
  const Carga._(this.estado, this.dato, this.error);
  const Carga.cargando() : this._(Estado.cargando, null, null);
  const Carga.listo(T dato) : this._(Estado.listo, dato, null);
  const Carga.fallo(String error) : this._(Estado.error, null, error);
}

class TableroViewModel extends ChangeNotifier {
  final ServicioClima _clima;
  final ServicioCambio _cambio;
  final ServicioFestivos _festivos;
  final ServicioWikipedia _wikipedia;
  final ServicioNasa _nasa;

  TableroViewModel({
    required ServicioClima clima,
    required ServicioCambio cambio,
    required ServicioFestivos festivos,
    required ServicioWikipedia wikipedia,
    required ServicioNasa nasa,
  })  : _clima = clima,
        _cambio = cambio,
        _festivos = festivos,
        _wikipedia = wikipedia,
        _nasa = nasa;

  Carga<Clima> clima = const Carga.cargando();
  Carga<TipoCambio> cambio = const Carga.cargando();
  Carga<List<Festivo>> festivos = const Carga.cargando();
  Carga<ResumenWiki> wiki = const Carga.cargando();
  Carga<FotoAstronomica> nasa = const Carga.cargando();

  /// Último tema que sí funcionó: al recargar, Wikipedia vuelve a pedir este.
  String _temaWiki = 'Dolores Hidalgo';

  Future<void> cargarTodo() async {
    clima = const Carga.cargando();
    cambio = const Carga.cargando();
    festivos = const Carga.cargando();
    wiki = const Carga.cargando();
    nasa = const Carga.cargando();
    notifyListeners();

    // Las 5 peticiones salen al mismo tiempo (en paralelo).
    await Future.wait([
      _cargar(() => _clima.actual(), (c) => clima = c),
      _cargar(() => _cambio.deMxn(), (c) => cambio = c),
      _cargar(() => _festivos.proximos(), (c) => festivos = c),
      _cargar(() => _wikipedia.resumen(_temaWiki), (c) => wiki = c),
      _cargar(() => _nasa.fotoDelDia(), (c) => nasa = c),
    ]);
  }

  /// Busca otro tema SOLO en Wikipedia: las otras 4 tarjetas no se tocan.
  /// El texto del usuario se valida dentro de ServicioWikipedia.
  Future<void> buscarWiki(String tema) async {
    wiki = const Carga.cargando();
    notifyListeners();
    await _cargar(() async {
      final r = await _wikipedia.resumen(tema);
      _temaWiki = tema.trim();
      return r;
    }, (c) => wiki = c);
  }

  Future<void> _cargar<T>(Future<T> Function() pedir, void Function(Carga<T>) poner) async {
    try {
      poner(Carga.listo(await pedir()));
    } catch (e) {
      poner(Carga.fallo(mensajeSeguro(e)));
    }
    notifyListeners();
  }
}
