import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:intl/intl.dart';

class ClimaCarouselView extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> ciudadesGuardadas;
  final Function(Map<String, dynamic>) actualizaClima;
  const ClimaCarouselView({
    super.key,
    required this.ciudadesGuardadas,
    required this.actualizaClima,
  });
  @override
  State<ClimaCarouselView> createState() => _ClimaCarouselViewState();
}

class _ClimaCarouselViewState extends State<ClimaCarouselView> {
  int _currentIndex = 0; // Índice de la página actual en el PageView
  final PageController _pageCtrl = PageController(
    viewportFraction: 0.88,
  ); //  cards style

  // Mapa de íconos del clima
  IconData _obtenerIconoClima(int simbolo) {
    switch (simbolo) {
      case 0:
        return WeatherIcons.na;
      case 1:
        return WeatherIcons.day_sunny;
      case 2:
        return WeatherIcons.day_sunny_overcast;
      case 3:
        return WeatherIcons.day_cloudy;
      case 4:
        return WeatherIcons.cloud;
      case 101:
        return WeatherIcons.night_clear;
      case 102:
        return WeatherIcons.night_alt_cloudy_gusts;
      case 103:
        return WeatherIcons.night_partly_cloudy;
      case 104:
        return WeatherIcons.night_cloudy;
      default:
        return WeatherIcons.na;
    }
  }

  String _obtenerDescripcionClima(int simbolo) {
    switch (simbolo) {
      case 0:
        return 'Sin datos';

      case 1:
        return 'Despejado';
      case 2:
        return 'Mayormente despejado';
      case 3:
        return 'Parcialmente Nublado';
      case 4:
        return 'Nublado';
      case 101:
        return 'Despejado (noche)';
      case 102:
        return 'Mayormente despejado (noche)';
      case 103:
        return 'Parcialmente nublado (noche)';
      case 104:
        return 'Nublado (noche)';
      default:
        return 'Desconocido';
    }
  }

  String _formatearHora(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return 'Desconocido';
    try {
      final fecha = DateTime.parse(timestamp);
      return DateFormat('HH:mm').format(fecha.toLocal());
    } catch (e) {
      return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.ciudadesGuardadas,
      builder: (context, snapshot) {
        // Mostrar 'Loading' mientras se cargan los datos
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade400, Colors.blue.shade700],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        // Manejar errores
        if (snapshot.hasError) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade400, Colors.blue.shade700],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 50),
                  const SizedBox(height: 10),
                  Text(
                    'Error al cargar ciudades: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        // Acceder a la lista de ciudades
        final ciudades = snapshot.data ?? [];
        if (ciudades.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade400, Colors.blue.shade700],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, color: Colors.white, size: 60),
                  SizedBox(height: 20),
                  Text(
                    'No hay ciudades guardadas',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          );
        }
        // Mostrar el Carousel de ciudades
        return _buildCarousel(ciudades);
      },
    );
  }

  Widget _buildCarousel(List<Map<String, dynamic>> ciudades) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        //  Fondo sutil para que las tarjetas destaquen
        Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade300, Colors.blue.shade900],
            ),
          ),
        ),

        //  Slider tipo "tarjetas" estilo iOS Weather
        PageView.builder(
          controller: _pageCtrl,
          itemCount: ciudades.length,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (context, index) {
            final ciudad = ciudades[index];

            return AnimatedBuilder(
              animation: _pageCtrl,
              builder: (context, child) {
                double value = 1.0;
                if (_pageCtrl.position.haveDimensions) {
                  value = (_pageCtrl.page! - index).abs();
                  value = (1 - (value * 0.12)).clamp(0.90, 1.0);
                }
                return Center(
                  child: Transform.scale(scale: value, child: child),
                );
              },
              child: GestureDetector(
                onTap: () {
                  context.push('/detalle_clima', extra: ciudad);
                },
                child: _buildCiudadCard(ciudad),
              ),
            );
          },
        ),

        //  Botón refrescar
        Positioned(
          top: 52,
          right: 16,
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              if (_currentIndex < ciudades.length) {
                widget.actualizaClima(ciudades[_currentIndex]);
              }
            },
          ),
        ),

        //  Indicadores
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(ciudades.length, (i) {
              final active = i == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 16 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.white54,
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildCiudadCard(Map<String, dynamic> ciudad) {
    final temperatura = (ciudad['temperatura'] ?? 0.0) as num;
    final simoboloClima = ciudad['simbolo_clima'] ?? 0;
    final velocidadViento = (ciudad['velocidad_viento'] ?? 0.0) as num;
    final nombre = ciudad['nombre'] ?? 'Desconocido';
    final ultimaActualizacion = ciudad['ultima_actualizacion'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(top: 90, bottom: 64, left: 8, right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 22,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    //  Nombre de la ciudad
                    Text(
                      nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),

                    //  Descripción
                    Text(
                      _obtenerDescripcionClima(simoboloClima),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const Spacer(),

                    //  Icono del clima
                    Icon(
                      _obtenerIconoClima(simoboloClima),
                      color: Colors.white,
                      size: 110,
                    ),
                    const SizedBox(height: 6),

                    //  Temperatura grande
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          temperatura.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 86,
                            fontWeight: FontWeight.w200,
                            height: 1.0,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 10, left: 2),
                          child: Text(
                            '°C',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    //  Info inferior en fila
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInfoItem(
                            Icons.air,
                            '${velocidadViento.toStringAsFixed(1)} m/s',
                            'Viento',
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white24,
                          ),
                          _buildInfoItem(
                            Icons.access_time,
                            _formatearHora(ultimaActualizacion),
                            'Actualizado',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}
