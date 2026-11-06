import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import 'tablero_viewmodel.dart';

class PantallaTablero extends StatefulWidget {
  final TableroViewModel vm;
  const PantallaTablero({super.key, required this.vm});
  @override
  State<PantallaTablero> createState() => _PantallaTableroState();
}

class _PantallaTableroState extends State<PantallaTablero> {
  @override
  void initState() {
    super.initState();
    widget.vm.cargarTodo();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    return AnimatedBuilder(
      animation: vm,
      builder: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Dolores Hoy')),
        body: RefreshIndicator(
          onRefresh: vm.cargarTodo,
          child: ListView(padding: const EdgeInsets.all(12), children: [
            TarjetaCarga<Clima>(
              titulo: 'Clima en Dolores Hidalgo', icono: Icons.wb_sunny, carga: vm.clima,
              construir: (c) {
                final (emoji, texto) = describirClima(c.codigo);
                return Text('$emoji $texto · ${c.temperatura.toStringAsFixed(1)} °C\n'
                    'Humedad ${c.humedad}% · Viento ${c.viento.toStringAsFixed(0)} km/h');
              },
            ),
            TarjetaCarga<TipoCambio>(
              titulo: 'Tipo de cambio', icono: Icons.attach_money, carga: vm.cambio,
              construir: (t) => Text(
                  '1 USD = \$${t.pesosPorUnidad('USD').toStringAsFixed(2)} MXN\n'
                  '1 EUR = \$${t.pesosPorUnidad('EUR').toStringAsFixed(2)} MXN\n'
                  'Actualizado: ${t.fecha.toIso8601String().substring(0, 10)}'),
            ),
            TarjetaCarga<List<Festivo>>(
              titulo: 'Próximos festivos', icono: Icons.celebration, carga: vm.festivos,
              construir: (lista) => Text(lista.isEmpty
                  ? 'No hay más festivos este año.'
                  : lista.map((f) => '${f.fecha.day}/${f.fecha.month} · ${f.nombre}').join('\n')),
            ),
            TarjetaCarga<ResumenWiki>(
              titulo: 'Wikipedia', icono: Icons.menu_book, carga: vm.wiki,
              construir: (w) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(w.titulo, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(w.extracto, maxLines: 6, overflow: TextOverflow.ellipsis),
              ]),
            ),
            TarjetaCarga<FotoAstronomica>(
              titulo: 'Foto astronómica (NASA)', icono: Icons.rocket_launch, carga: vm.nasa,
              construir: (f) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.titulo, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (f.urlImagen != null)
                  Image.network(f.urlImagen!,
                      errorBuilder: (_, __, ___) => const Text('No se pudo cargar la imagen'))
                else
                  const Text('(Hoy la NASA publicó un video; no se muestra por seguridad)'),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class TarjetaCarga<T> extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Carga<T> carga;
  final Widget Function(T) construir;

  const TarjetaCarga({
    super.key,
    required this.titulo,
    required this.icono,
    required this.carga,
    required this.construir,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icono),
            const SizedBox(width: 8),
            Text(titulo, style: Theme.of(context).textTheme.titleSmall),
          ]),
          const SizedBox(height: 10),
          switch (carga.estado) {
            Estado.cargando => const LinearProgressIndicator(),
            Estado.error => Text(carga.error ?? 'Error',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            Estado.listo => construir(carga.dato as T),
          },
        ]),
      ),
    );
  }
}
