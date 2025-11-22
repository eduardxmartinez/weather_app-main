import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
//import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'app_scaffold.dart';

class AgregarCiudadesPage extends StatefulWidget {
  const AgregarCiudadesPage({super.key});
  @override
  State<AgregarCiudadesPage> createState() => _AgregarCiudadesPageState();
}

class _AgregarCiudadesPageState extends State<AgregarCiudadesPage> {
  final TextEditingController _cityController = TextEditingController();
  final MapController _mapController = MapController();
  final FocusNode _cityFocus = FocusNode(); //  mejor UX

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  ); //  títulos consistentes

  List ciudadData = [];
  double dLat = 29.0948207;
  double dLon = -110.9692202;
  double selectedLat = 29.0948207;
  double selectedLon = -110.9692202;
  int? selectedIndex;
  bool _selectedFromSaved = false;
  Future<List<Map<String, dynamic>>> ciudadesGuardadas =
      Future<List<Map<String, dynamic>>>.value([]);

  bool _isSearching = false; //  spinner buscar
  bool _isAddingCity = false; //  spinner agregar

  bool _yaEstaGuardada(String nombre, List<Map<String, dynamic>> guardadas) {
    final n = nombre.trim().toLowerCase();
    return guardadas.any(
      (c) => (c['nombre'] ?? '').toString().trim().toLowerCase() == n,
    );
  }

  @override
  void initState() {
    super.initState();
    ciudadesGuardadas = _ciudadesGuardadas();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _cityFocus.dispose(); //
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Agregar Ciudades",
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //  Header
            Text(
              "Agrega nuevas ciudades",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),

            _sectionTitle("Buscar ciudad"),

            //  Campo de búsqueda en tarjeta
            Card(
              elevation: 0.6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: TextField(
                  controller: _cityController,
                  focusNode: _cityFocus,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _onBuscarCiudad(), //  buscar al enter
                  decoration: InputDecoration(
                    hintText: 'Ej: Hermosillo, Sonora',
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _cityController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _cityController.clear();
                                ciudadData = [];
                                selectedIndex = null;
                              });
                            },
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            //  Botón buscar
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: _isSearching ? null : _onBuscarCiudad,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSearching) ...[
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text("Buscando..."),
                    ] else ...[
                      const Icon(Icons.travel_explore),
                      const SizedBox(width: 8),
                      const Text("Buscar ciudad"),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            //  Resultados de búsqueda
            if (_isSearching) ...[
              const SizedBox(height: 10),
              const Center(child: CircularProgressIndicator()),
            ] else if (ciudadData.isNotEmpty) ...[
              _sectionTitle("Resultados"),
              SizedBox(
                height: 220,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: ciudadesGuardadas,
                  builder: (context, snapGuardadas) {
                    final guardadas =
                        snapGuardadas.data ?? const <Map<String, dynamic>>[];

                    return ListView.separated(
                      itemCount: ciudadData.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final ciudadInfo = ciudadData[index];
                        final nombreCiudad = (ciudadInfo['display_name'] ?? '')
                            .toString();
                        final isSelected = selectedIndex == index;
                        final isSavedAlready = _yaEstaGuardada(
                          nombreCiudad,
                          guardadas,
                        ); //

                        return Opacity(
                          opacity: isSavedAlready ? 0.55 : 1.0, //  apagada
                          child: Card(
                            elevation: isSelected ? 1.2 : 0.3,
                            color: isSelected
                                ? Colors.blue.withOpacity(0.08)
                                : (isSavedAlready
                                      ? Colors.grey.withOpacity(0.05)
                                      : null),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              enabled: !isSavedAlready, //  no permite tap
                              leading: Icon(
                                Icons.location_city,
                                color: isSavedAlready ? Colors.grey : null,
                              ),
                              title: Text(
                                nombreCiudad,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'Lat: ${ciudadInfo['lat']}, Lon: ${ciudadInfo['lon']}',
                              ),
                              selected: isSelected,
                              trailing: isSavedAlready
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            size: 16,
                                            color: Colors.green,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Guardada',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : null,
                              onTap: isSavedAlready
                                  ? null
                                  : () {
                                      setState(() {
                                        selectedIndex = index;
                                        _selectedFromSaved = false; //
                                        _cityController.text = nombreCiudad;
                                        selectedLat = double.parse(
                                          ciudadInfo['lat'],
                                        );
                                        selectedLon = double.parse(
                                          ciudadInfo['lon'],
                                        );
                                        _mapController.move(
                                          LatLng(selectedLat, selectedLon),
                                          10,
                                        );
                                      });
                                      _showMapSheet(
                                        ciudad: ciudadInfo,
                                        lat: selectedLat,
                                        lon: selectedLon,
                                        isSaved: false,
                                        isSearching: true,
                                      );
                                    },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              //  Botón agregar (solo si hay selección)
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: (selectedIndex == null || _isAddingCity)
                      ? null
                      : () => _agregarCiudad(
                          _cityController.text,
                          selectedLat,
                          selectedLon,
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isAddingCity) ...[
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text("Agregando..."),
                      ] else ...[
                        const Icon(Icons.add_location_alt),
                        const SizedBox(width: 8),
                        const Text("Agregar ciudad seleccionada"),
                      ],
                    ],
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 6),
              Text(
                "Busca una ciudad para agregarla a tu lista.",
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],

            const SizedBox(height: 18),

            _sectionTitle("Ciudades guardadas"),

            //  Lista de guardadas con cards
            SizedBox(
              height: 220,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: ciudadesGuardadas,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Error ${snapshot.error}');
                  }
                  final data = snapshot.data ?? const <Map<String, dynamic>>[];
                  if (data.isEmpty) {
                    return const Center(
                      child: Text('No hay ciudades guardadas.'),
                    );
                  }
                  return ListView.separated(
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final ciudad = data[index];
                      final isSelected = selectedIndex == index;

                      return Card(
                        elevation: isSelected ? 1.2 : 0.3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.place),
                          title: Text(ciudad['nombre'].toString()),
                          subtitle: Text(
                            'Lat: ${ciudad["latitud"]}  Lon: ${ciudad["longitud"]}',
                          ),
                          selected: isSelected,
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _eliminarCiudad(index),
                          ),
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                              _selectedFromSaved = true; //

                              selectedLat = ciudad['latitud'];
                              selectedLon = ciudad['longitud'];
                              _mapController.move(
                                LatLng(selectedLat, selectedLon),
                                10,
                              );
                            });
                            _showMapSheet(
                              ciudad: ciudad,
                              lat: selectedLat,
                              lon: selectedLon,
                              isSaved: true,
                              savedIndex: index,
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            _sectionTitle("Mapa"),

            //  Mapa con bordes y sombra
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 320,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(selectedLat, selectedLon),
                    initialZoom: 10,
                    maxZoom: 18,
                    minZoom: 3,
                    onTap: (tapPosition, point) {
                      setState(() {
                        selectedLat = point.latitude;
                        selectedLon = point.longitude;
                        selectedIndex = null;
                        _selectedFromSaved = false;
                      });
                      _mapController.move(point, _mapController.camera.zoom);
                      _showMapSheet(
                        nombre: _cityController.text.trim().isEmpty
                            ? null
                            : _cityController.text.trim(),
                        lat: selectedLat,
                        lon: selectedLon,
                        isSaved: false,
                      );
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.weather_app',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(selectedLat, selectedLon),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () {
                              _showMapSheet(
                                ciudad: _selectedFromSaved
                                    ? null
                                    : (selectedIndex != null &&
                                              selectedIndex! < ciudadData.length
                                          ? ciudadData[selectedIndex!]
                                          : null),
                                lat: selectedLat,
                                lon: selectedLon,
                                isSaved: _selectedFromSaved,
                                savedIndex: _selectedFromSaved
                                    ? selectedIndex
                                    : null,
                              );
                            },
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 36,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }

  // ---Bottom sheet interactivo con mapa ---

  void _showMapSheet({
    Map<String, dynamic>? ciudad,
    String? nombre,
    required double lat,
    required double lon,
    required bool isSaved,
    bool isSearching = false,
    int? savedIndex,
  }) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final ciudadNormalizada = <String, dynamic>{
          ...(ciudad ?? <String, dynamic>{}),
          'latitud': lat,
          'longitud': lon,
        };

        // prioridad: nombre param > ciudad['nombre'] > ciudad['display_name']
        final titulo = (nombre != null && nombre.trim().isNotEmpty)
            ? nombre.trim()
            : (ciudadNormalizada['nombre']?.toString().trim().isNotEmpty == true
                  ? ciudadNormalizada['nombre'].toString().trim()
                  : (ciudadNormalizada['display_name']
                                ?.toString()
                                .trim()
                                .isNotEmpty ==
                            true
                        ? ciudadNormalizada['display_name'].toString().trim()
                        : 'Ubicación seleccionada'));

        ciudadNormalizada['nombre'] = titulo;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                //  Handle
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),

                _sheetRow(Icons.my_location, 'Lat: ${lat.toStringAsFixed(5)}'),
                _sheetRow(Icons.my_location, 'Lon: ${lon.toStringAsFixed(5)}'),

                const SizedBox(height: 12),

                //  Acciones
                if (!isSaved) ...[
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_location_alt),
                      label: const Text('Agregar esta ciudad'),
                      onPressed: _isAddingCity
                          ? null
                          : () {
                              Navigator.pop(context);
                              _agregarCiudad(titulo, lat, lon);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Quitar de guardadas'),
                      onPressed: savedIndex == null
                          ? null
                          : () {
                              Navigator.pop(context);
                              _eliminarCiudad(savedIndex);
                            },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_outlined),
                    label: const Text('Ver clima de esta ciudad'),
                    onPressed: isSearching
                        ? null
                        : () {
                            Navigator.pop(context);
                            context.push(
                              '/detalle_clima',
                              extra: ciudadNormalizada,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey.shade800)),
          ),
        ],
      ),
    );
  }

  Future<void> _onBuscarCiudad() async {
    final ciudad = _cityController.text.trim();
    if (ciudad.isEmpty) return;

    // esconder teclado
    if (mounted) {
      FocusScope.of(context).unfocus();
    }

    setState(() => _isSearching = true); //
    try {
      final resultados = await _buscarCiudad(ciudad);
      if (!mounted) return;
      setState(() {
        ciudadData = resultados;
        selectedIndex = null;
      });
    } finally {
      if (mounted) setState(() => _isSearching = false); //
    }
  }

  Future<List> _buscarCiudad(String nombreCiudad) async {
    // Aquí iría la lógica para buscar la ciudad en una base de datos o API
    // Por ahora, devolvemos un mapa simulado
    // Necesitamos armar el url para  consultar Nominatim con el nombreCiudad
    final url =
        'https://nominatim.openstreetmap.org/search?q=$nombreCiudad&format=json&addressdetails=1';
    debugPrint('URL de búsqueda: $url');
    // Hacemos la peticion a Nominatim con el url formado
    final response = await http.get(
      Uri.parse(url),
      headers: const {
        'User-Agent':
            'weather_app_flutter/1.0 (contact: example@email.com)', //  requerido por Nominatim
      },
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      if (data.isNotEmpty) {
        //final ciudadInfo = data[0];
        return data;
      }
    }
    return [];
  }

  void _eliminarCiudad(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> listaciudadesGuardadas = prefs.getStringList('ciudades') ?? [];
    if (index >= 0 && index < listaciudadesGuardadas.length) {
      listaciudadesGuardadas.removeAt(index);
      await prefs.setStringList('ciudades', listaciudadesGuardadas);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ciudad eliminada')));
      // Forzamos la reconstrucción
      setState(() {
        ciudadesGuardadas = _ciudadesGuardadas();
      });
    }
  }

  void _agregarCiudad(String nombre, double lat, double lon) async {
    if (_isAddingCity) return; //  evita doble tap
    final nombreLimpio = nombre.trim();
    if (nombreLimpio.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una ciudad válida.')),
      );
      return;
    }

    debugPrint('=== Iniciando _agregarCiudad ===');
    debugPrint('Nombre: $nombreLimpio, Lat: $lat, Lon: $lon');

    if (mounted) setState(() => _isAddingCity = true); //  spinner
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> listaciudadesGuardadas =
          prefs.getStringList('ciudades') ?? [];
      debugPrint('Ciudades antes de agregar: ${listaciudadesGuardadas.length}');

      String ciudadString = json.encode({
        'nombre': nombreLimpio,
        'latitud': lat,
        'longitud': lon,
      });
      debugPrint('Ciudad a agregar (JSON): $ciudadString');

      final yaExiste = listaciudadesGuardadas.any((c) {
        try {
          final m = json.decode(c);
          return (m['nombre']?.toString().toLowerCase() ==
              nombreLimpio.toLowerCase());
        } catch (_) {
          return false;
        }
      });

      if (yaExiste) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$nombreLimpio" ya está guardada.')),
        );
        return;
      }

      listaciudadesGuardadas.add(ciudadString);
      await prefs.setStringList('ciudades', listaciudadesGuardadas);
      debugPrint(
        'Ciudades después de agregar: ${listaciudadesGuardadas.length}',
      );

      // Verificamos que se guardó correctamente
      final verificacion = prefs.getStringList('ciudades') ?? [];
      debugPrint(
        'Verificación - Total ciudades guardadas: ${verificacion.length}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ciudad agregada: $nombreLimpio')));
      // Forzamos la reconstrucción
      setState(() {
        ciudadesGuardadas = _ciudadesGuardadas();
      });
      debugPrint('=== Fin _agregarCiudad ===');
    } finally {
      if (mounted) setState(() => _isAddingCity = false); //
    }
  }

  Future<List<Map<String, dynamic>>> _ciudadesGuardadas() async {
    debugPrint('=== Cargando ciudades guardadas ===');
    final prefs = await SharedPreferences.getInstance();
    final ciudadesString = prefs.getStringList('ciudades') ?? [];
    debugPrint('Total ciudades en SharedPreferences: ${ciudadesString.length}');

    if (ciudadesString.isNotEmpty) {
      debugPrint('Primera ciudad: ${ciudadesString.first}');
    }

    final resultado = ciudadesString
        .map((ciudadStr) => json.decode(ciudadStr) as Map<String, dynamic>)
        .toList();
    debugPrint('=== Fin carga ciudades ===');
    return resultado;
  }
}
