import 'package:dolores_hoy/datos/config_claves.dart';
import 'package:dolores_hoy/dominio/excepciones.dart';
import 'package:dolores_hoy/dominio/modelos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConfigClaves', () {
    test('toString nunca imprime la clave completa', () {
      const c = ConfigClaves(nasa: 'abcdef123456');
      expect(c.toString(), isNot(contains('abcdef123456')));
      expect(c.toString(), contains('ab***56'));
    });

    test('claves muy cortas se ocultan por completo', () {
      expect(const ConfigClaves(nasa: 'abc').toString(), contains('****'));
    });

    test('detecta que se está usando la clave de demostración', () {
      expect(const ConfigClaves(nasa: 'DEMO_KEY').usaClaveDemo, true);
      expect(const ConfigClaves(nasa: 'otra').usaClaveDemo, false);
    });

    test('clave vacía no es válida', () {
      expect(() => const ConfigClaves(nasa: '').validar(),
          throwsA(isA<ClaveFaltanteException>()));
    });
  });

  group('mensajeSeguro', () {
    test('errores de la app muestran su mensaje', () {
      expect(mensajeSeguro(const SinConexionException()), contains('conexión'));
    });

    test('errores inesperados NO filtran detalles internos', () {
      final msg = mensajeSeguro(StateError('clave=SECRETO en /home/usuario/app'));
      expect(msg, isNot(contains('SECRETO')));
      expect(msg, isNot(contains('/home')));
      expect(msg, contains('inesperado'));
    });
  });

  group('soloHttps', () {
    test('acepta https y rechaza lo demás', () {
      expect(soloHttps('https://a.com/x.jpg'), 'https://a.com/x.jpg');
      expect(soloHttps('http://a.com/x.jpg'), isNull);
      expect(soloHttps('javascript:alert(1)'), isNull);
      expect(soloHttps(null), isNull);
      expect(soloHttps(42), isNull);
    });
  });
}
