import 'dart:convert'; //  forecast parse

import 'package:http/http.dart' as http; //  forecast request

import 'package:flutter_dotenv/flutter_dotenv.dart'; // ⭐ access .env

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; //  cache token
import 'package:weather_icons/weather_icons.dart';

class DetalleClimaPage extends StatefulWidget {
  final Map<String, dynamic> ciudad;

  const DetalleClimaPage({super.key, required this.ciudad});

  @override
  State<DetalleClimaPage> createState() => _DetalleClimaPageState();
}

class _DetalleClimaPageState extends State<DetalleClimaPage> {
  late final Future<List<Map<String, dynamic>>> _pronosticoHoras;

  //  mismo patrón que main.dart
  static String get apiTokenUrl =>
      dotenv.env['meteomatics_api_url'] ??
      'https://login.meteomatics.com/api/v1/token';
  static String get username => dotenv.env['meteomatics_user'] ?? '';
  static String get password => dotenv.env['meteomatics_pwd'] ?? '';

  String _apiToken = '';

  @override
  void initState() {
    super.initState();
    _pronosticoHoras = _obtenerPronosticoProximasHoras(); //
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.ciudad['nombre'] ?? 'Ciudad';
    final temp = (widget.ciudad['temperatura'] ?? 0.0) as num;
    final viento = (widget.ciudad['velocidad_viento'] ?? 0.0) as num;
    final simbolo = widget.ciudad['simbolo_clima'] ?? 0;
    final lat = widget.ciudad['latitud'] ?? 0.0;
    final lon = widget.ciudad['longitud'] ?? 0.0;
    final ultima = widget.ciudad['ultima_actualizacion']?.toString();

    return Material(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade300, Colors.blue.shade900],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                centerTitle: true,
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      //  Estado del clima
                      Text(
                        _obtenerDescripcionClima(simbolo),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),

                      //  Icono grande
                      Icon(
                        _obtenerIconoClima(simbolo),
                        color: Colors.white,
                        size: 120,
                      ),
                      const SizedBox(height: 8),

                      //  Temperatura hero
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            temp.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 92,
                              fontWeight: FontWeight.w200,
                              height: 1.0,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 12, left: 2),
                            child: Text(
                              "°C",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      //  Actualización
                      Text(
                        ultima == null
                            ? "Sin actualización"
                            : "Actualizado: ${_formatearFechaCompleta(ultima)}",
                        style: const TextStyle(color: Colors.white60),
                      ),

                      const SizedBox(height: 22),

                      //  Cards principales
                      Row(
                        children: [
                          Expanded(
                            child: _miniCard(
                              icon: Icons.air,
                              value: "${viento.toStringAsFixed(1)} m/s",
                              label: "Viento",
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _miniCard(
                              icon: Icons.my_location,
                              value:
                                  "${lat.toStringAsFixed(3)}, ${lon.toStringAsFixed(3)}",
                              label: "Coords",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      //  Card grande para futuras métricas (humedad, presión, etc.)
                      _bigCard(
                        title: "Resumen",
                        children: [
                          _rowInfo(
                            "Temperatura",
                            "${temp.toStringAsFixed(1)} °C",
                          ),
                          _rowInfo(
                            "Viento",
                            "${viento.toStringAsFixed(1)} m/s",
                          ),
                          _rowInfo("Símbolo", simbolo.toString()),
                        ],
                      ),

                      const SizedBox(height: 18),

                      //  Placeholder pro para forecast (lo llenamos después)
                      _bigCard(
                        title: "Próximas horas",
                        children: [
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _pronosticoHoras,
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (snap.hasError) {
                                return Text(
                                  'No se pudo cargar pronóstico: ${snap.error}',
                                  style: const TextStyle(color: Colors.white70),
                                );
                              }
                              final data = snap.data ?? [];
                              if (data.isEmpty) {
                                return const Text(
                                  'Sin datos de pronóstico.',
                                  style: TextStyle(color: Colors.white70),
                                );
                              }

                              return SizedBox(
                                height: 120,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: data.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, i) {
                                    final h = data[i];
                                    final hora = h['hora'] as String? ?? '';
                                    final t = (h['temp'] as num?) ?? 0;
                                    final w = (h['wind'] as num?) ?? 0;
                                    final s =
                                        (h['symbol'] as num?)?.toInt() ?? 0;

                                    return Container(
                                      width: 90,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.15),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            hora,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Icon(
                                            _obtenerIconoClima(s),
                                            color: Colors.white,
                                            size: 26,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${t.toStringAsFixed(0)}°',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '${w.toStringAsFixed(0)} m/s',
                                            style: const TextStyle(
                                              color: Colors.white60,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- UI helpers ----------

  Widget _miniCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _bigCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _rowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- formatting / mapping ----------

  String _formatearFechaCompleta(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return DateFormat("EEE d MMM, HH:mm", "es").format(dt);
    } catch (e) {
      print("------Error al formatear fecha: $e");
      return timestamp;
    }
  }

  // Obtiene token de Meteomatics igual que en main.dart
  Future<String> _obtenerToken() async {
    if (_apiToken.isNotEmpty) return _apiToken;

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('meteomatics_access_token') ?? '';
    if (cached.isNotEmpty) {
      _apiToken = cached;
      return _apiToken;
    }

    if (username.isEmpty || password.isEmpty) {
      throw Exception('Faltan meteomatics_user / meteomatics_pwd en .env');
    }

    final response = await http.get(
      Uri.parse(apiTokenUrl),
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$username:$password'))}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al obtener token: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final token = (data['access_token'] ?? '').toString();
    if (token.isEmpty) {
      throw Exception('Respuesta sin access_token');
    }

    _apiToken = token;
    await prefs.setString('meteomatics_access_token', token);
    return _apiToken;
  }

  //  Meteomatics: pronóstico por hora para las próximas N horas
  Future<List<Map<String, dynamic>>> _obtenerPronosticoProximasHoras({
    int horas = 12,
  }) async {
    final ciudad = widget.ciudad;
    final lat = (ciudad['latitud'] ?? ciudad['lat'] ?? 0.0) as num;
    final lon = (ciudad['longitud'] ?? ciudad['lon'] ?? 0.0) as num;

    final token = await _obtenerToken(); //  mismo patrón main

    final ahoraUtc = DateTime.now().toUtc();
    final finUtc = ahoraUtc.add(Duration(hours: horas));

    String iso(DateTime d) => '${d.toIso8601String().split('.').first}Z';

    // Sintaxis de rango: start--end:PT1H (1 hora)
    final start = iso(ahoraUtc);
    final end = iso(finUtc);

    final url =
        'https://api.meteomatics.com/$start--$end:PT1H/'
        't_2m:C,wind_speed_10m:ms,weather_symbol_1h:idx/'
        '${lat.toDouble()},${lon.toDouble()}/json?access_token=$token';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
    }

    final jsonRes = json.decode(res.body) as Map<String, dynamic>;
    final data = (jsonRes['data'] as List).cast<Map<String, dynamic>>();

    // Armamos un mapa por fecha
    final Map<String, Map<String, dynamic>> porHora = {};

    for (final serie in data) {
      final param = serie['parameter'] as String? ?? '';
      final coords =
          (serie['coordinates'] as List).first as Map<String, dynamic>;
      final dates = (coords['dates'] as List).cast<Map<String, dynamic>>();

      for (final d in dates) {
        final fechaIso = d['date'] as String;
        final value = d['value'];
        porHora.putIfAbsent(fechaIso, () => {'date': fechaIso});
        if (param.startsWith('t_2m')) porHora[fechaIso]!['temp'] = value;
        if (param.startsWith('wind_speed_10m'))
          porHora[fechaIso]!['wind'] = value;
        if (param.startsWith('weather_symbol_1h'))
          porHora[fechaIso]!['symbol'] = value;
      }
    }

    final lista = porHora.values.toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    return lista.map((e) {
      final dt = DateTime.tryParse(e['date']?.toString() ?? '')?.toLocal();
      return {
        'hora': dt == null ? '' : DateFormat('HH:mm', 'es').format(dt),
        'temp': (e['temp'] as num?) ?? 0,
        'wind': (e['wind'] as num?) ?? 0,
        'symbol': (e['symbol'] as num?) ?? 0,
        'date': e['date'],
      };
    }).toList();
  }

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
      case 5:
        return WeatherIcons.fog;
      case 6:
        return WeatherIcons.showers;
      case 7:
        return WeatherIcons.rain;
      case 8:
        return WeatherIcons.thunderstorm;
      case 9:
        return WeatherIcons.snow;
      default:
        return WeatherIcons.day_sunny;
    }
  }

  String _obtenerDescripcionClima(int simbolo) {
    switch (simbolo) {
      case 0:
        return 'Sin datos';
      case 1:
        return 'Soleado';
      case 2:
        return 'Parcialmente nublado';
      case 3:
        return 'Nublado';
      case 4:
        return 'Muy nublado';
      case 5:
        return 'Neblina';
      case 6:
        return 'Llovizna';
      case 7:
        return 'Lluvia';
      case 8:
        return 'Tormenta';
      case 9:
        return 'Nieve';
      default:
        return 'Clima';
    }
  }
}
