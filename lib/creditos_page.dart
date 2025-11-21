import 'package:flutter/material.dart';
//import 'package:go_router/go_router.dart';
import 'app_scaffold.dart';

class CreditosPage extends StatelessWidget {
  const CreditosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Créditos",
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Créditos",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 20),
            Text(
              "Desarrollado por: Luis Eduardo Martinez Espinoza y Daniel Elias Ulloa Mada",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 10),
            Text(
              "Institución: Universidad de Sonora",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 10),
            Text(
              "Curso: Desarrollo de Aplicaciones Móviles",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 10),
            Text(
              "Mapas y geocodificacion obtenidos por OpenStreetMap y Nominatim.\nClima proporcionado por Meteomatics AG.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
