import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'app_scaffold.dart';

class ConfiguracionPage extends StatelessWidget {
  const ConfiguracionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AppScaffold(
      title: 'Configuración',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  color: Colors.black.withValues(alpha: 0.05),
                ),
              ],
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Modo oscuro'),
              subtitle: Text(themeProvider.isDark ? 'Activado' : 'Desactivado'),
              value: themeProvider.isDark,
              onChanged: (v) => themeProvider.toggleDark(v),
              secondary: Icon(
                themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Usar tema del sistema'),
              subtitle: Text(
                'Tema actual del sistema: ${MediaQuery.of(context).platformBrightness == Brightness.dark ? 'Oscuro' : 'Claro'}',
              ),
              value:
                  themeProvider.themeMode ==
                  ThemeMode.system, // refleja selección
              onChanged: (v) {
                if (v) {
                  themeProvider.setThemeMode(ThemeMode.system);
                } else {
                  // Si se apaga, vuelve al modo claro por defecto
                  themeProvider.setThemeMode(ThemeMode.light);
                }
              },
              secondary: Icon(Icons.phone_iphone),
            ),
          ),
        ],
      ),
    );
  }
}
