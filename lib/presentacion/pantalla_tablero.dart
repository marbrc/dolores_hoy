import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import 'tablero_viewmodel.dart';

const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
];

/// Colores del panel del clima según el código del tiempo.
List<Color> _coloresClima(int codigo) {
  if (codigo <= 1) return [Colors.orange.shade400, Colors.deepOrange.shade300];
  if (codigo <= 48) return [Colors.blueGrey.shade400, Colors.blue.shade300];
  if (codigo <= 82) return [Colors.indigo.shade600, Colors.blue.shade500];
  return [Colors.deepPurple.shade700, Colors.indigo.shade500];
}

class PantallaTablero extends StatefulWidget {
  final TableroViewModel vm;
  const PantallaTablero({super.key, required this.vm});
  @override
  State<PantallaTablero> createState() => _PantallaTableroState();
}

class _PantallaTableroState extends State<PantallaTablero> {
  final _busqueda = TextEditingController();

  void _buscar() {
    FocusScope.of(context).unfocus();
    widget.vm.buscarWiki(_busqueda.text);
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    widget.vm.cargarTodo();
  }

  void _verCompleta(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(children: [
          Center(child: InteractiveViewer(child: Image.network(url))),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final tema = Theme.of(context);
    return AnimatedBuilder(
      animation: vm,
      builder: (_, __) => Scaffold(
        backgroundColor: tema.colorScheme.surfaceContainerLow,
        appBar: AppBar(
          title: const Text('Dolores Hoy',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: vm.cargarTodo,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            children: [
              // ☀️ CLIMA
              TarjetaCarga<Clima>(
                titulo: 'Clima en Dolores Hidalgo',
                icono: Icons.wb_sunny,
                color: Colors.orange,
                carga: vm.clima,
                construir: (c) {
                  final (emoji, texto) = describirClima(c.codigo);
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _coloresClima(c.codigo),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      Text(emoji, style: const TextStyle(fontSize: 56)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${c.temperatura.toStringAsFixed(1)} °C',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold)),
                            Text(texto,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16)),
                            const SizedBox(height: 6),
                            Text(
                                '💧 ${c.humedad}%    💨 ${c.viento.toStringAsFixed(0)} km/h',
                                style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ]),
                  );
                },
              ),

              // 💵 TIPO DE CAMBIO
              TarjetaCarga<TipoCambio>(
                titulo: 'Tipo de cambio',
                icono: Icons.attach_money,
                color: Colors.green,
                carga: vm.cambio,
                construir: (t) => Column(children: [
                  Row(children: [
                    Expanded(
                        child: _Moneda(
                            etiqueta: '💵 Dólar',
                            valor: t.pesosPorUnidad('USD'))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _Moneda(
                            etiqueta: '💶 Euro',
                            valor: t.pesosPorUnidad('EUR'))),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                      'Actualizado: ${t.fecha.toIso8601String().substring(0, 10)}',
                      style: tema.textTheme.bodySmall),
                ]),
              ),

              // 🎉 FESTIVOS
              TarjetaCarga<List<Festivo>>(
                titulo: 'Próximos festivos',
                icono: Icons.celebration,
                color: Colors.pink,
                carga: vm.festivos,
                construir: (lista) => lista.isEmpty
                    ? const Text('No hay más festivos este año.')
                    : Column(
                        children: lista
                            .map((f) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(children: [
                                    Container(
                                      width: 54,
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      decoration: BoxDecoration(
                                        color: tema.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(children: [
                                        Text('${f.fecha.day}',
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold)),
                                        Text(_meses[f.fecha.month - 1].toUpperCase(),
                                            style: const TextStyle(fontSize: 11)),
                                      ]),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Text(f.nombre,
                                            style: tema.textTheme.bodyLarge)),
                                  ]),
                                ))
                            .toList(),
                      ),
              ),

              // 📖 WIKIPEDIA
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _busqueda,
                  maxLength: 80,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _buscar(),
                  decoration: InputDecoration(
                    hintText: 'Busca en Wikipedia (ej. Miguel Hidalgo)',
                    counterText: '',
                    filled: true,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _buscar,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              TarjetaCarga<ResumenWiki>(
                titulo: 'Wikipedia',
                icono: Icons.menu_book,
                color: Colors.blueGrey,
                carga: vm.wiki,
                construir: (w) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (w.urlImagen != null) ...[
                        ImagenRed(url: w.urlImagen!, alto: 170),
                        const SizedBox(height: 10),
                      ],
                      Text(w.titulo, style: tema.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(w.extracto, maxLines: 6, overflow: TextOverflow.ellipsis),
                    ]),
              ),

              // 🚀 NASA
              TarjetaCarga<FotoAstronomica>(
                titulo: 'Foto astronómica (NASA)',
                icono: Icons.rocket_launch,
                color: Colors.deepPurple,
                carga: vm.nasa,
                construir: (f) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (f.urlImagen != null)
                        GestureDetector(
                          onTap: () => _verCompleta(f.urlImagen!),
                          child: Stack(children: [
                            ImagenRed(url: f.urlImagen!, alto: 240),
                            const Positioned(
                              right: 8,
                              bottom: 8,
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.zoom_out_map,
                                    size: 18, color: Colors.white),
                              ),
                            ),
                          ]),
                        )
                      else
                        Container(
                          height: 120,
                          width: double.infinity,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                                '🎬 Hoy la NASA publicó un video; no se muestra por seguridad',
                                textAlign: TextAlign.center),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(f.titulo, style: tema.textTheme.titleLarge),
                      Text(f.fecha.toIso8601String().substring(0, 10),
                          style: tema.textTheme.bodySmall),
                      const SizedBox(height: 6),
                      Text(f.explicacion,
                          maxLines: 3, overflow: TextOverflow.ellipsis),
                    ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Imagen de internet con esquinas redondeadas, cargando y error amable.
class ImagenRed extends StatelessWidget {
  final String url;
  final double alto;
  const ImagenRed({super.key, required this.url, required this.alto});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        url,
        height: alto,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progreso) => progreso == null
            ? child
            : SizedBox(
                height: alto,
                child: const Center(child: CircularProgressIndicator())),
        errorBuilder: (_, __, ___) => SizedBox(
            height: alto,
            child: const Center(child: Icon(Icons.broken_image_outlined, size: 40))),
      ),
    );
  }
}

class _Moneda extends StatelessWidget {
  final String etiqueta;
  final double valor;
  const _Moneda({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Text(etiqueta),
        const SizedBox(height: 4),
        Text('\$${valor.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const Text('MXN', style: TextStyle(fontSize: 12)),
      ]),
    );
  }
}

class TarjetaCarga<T> extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final Carga<T> carga;
  final Widget Function(T) construir;

  const TarjetaCarga({
    super.key,
    required this.titulo,
    required this.icono,
    required this.carga,
    required this.construir,
    this.color = Colors.indigo,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icono, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(titulo,
                  style: tema.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 12),
          switch (carga.estado) {
            Estado.cargando => const LinearProgressIndicator(),
            Estado.error => Row(children: [
                Icon(Icons.error_outline, color: tema.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(carga.error ?? 'Error',
                      style: TextStyle(color: tema.colorScheme.error)),
                ),
              ]),
            Estado.listo => construir(carga.dato as T),
          },
        ]),
      ),
    );
  }
}