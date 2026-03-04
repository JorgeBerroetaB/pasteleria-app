import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'agregar_torta.dart';
import 'detalle_torta.dart';
import 'calendario_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color azulPastelFondo = Color(0xFFF0F8FF);
    const Color azulPastelPrincipal = Color(0xFFB3E5FC);
    const Color azulPastelOscuro = Color(0xFF81D4FA);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pastelería Dulce Día',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
      locale: const Locale('es', 'ES'),
      theme: ThemeData(
        colorSchemeSeed: azulPastelOscuro,
        useMaterial3: true,
        scaffoldBackgroundColor: azulPastelFondo,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const ListaTortas(),
    );
  }
}

class ListaTortas extends StatefulWidget {
  const ListaTortas({super.key});
  @override
  State<ListaTortas> createState() => _ListaTortasState();
}

class _ListaTortasState extends State<ListaTortas> {
  List datos = [];
  bool cargando = true;

  final Color azulPastelPrincipal = const Color(0xFFB3E5FC);
  final Color azulPastelOscuro = const Color(0xFF81D4FA);

  final String _urlApi = 'https://pasteleria-backend-production-24fc.up.railway.app/api/tortas';

  @override
  void initState() {
    super.initState();
    cargarTortas();
  }

  Future<void> cargarTortas() async {
    if (!mounted) return;
    setState(() => cargando = true);
    try {
      final res = await http.get(Uri.parse(_urlApi));
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            datos = json.decode(res.body);
            cargando = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error cargando productos: $e");
      if (mounted) setState(() => cargando = false);
    }
  }

  List filtrarDatos(String categoria) {
    return datos.where((t) {
      return (t['categoria']?.toString().toLowerCase() ?? "") == categoria.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Pastelería Dulce Día", 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
          backgroundColor: azulPastelPrincipal,
          actions: [
            IconButton(
              icon: Icon(Icons.calendar_month_outlined, color: Colors.blueGrey[800]),
              tooltip: "Calendario de Pedidos",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CalendarioScreen()),
                );
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: azulPastelOscuro,
            indicatorWeight: 4,
            labelColor: Colors.blueGrey[800],
            unselectedLabelColor: Colors.blueGrey[400],
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Tortas", icon: Icon(Icons.cake_outlined)),
              Tab(text: "Tartas", icon: Icon(Icons.pie_chart_outline)),
              Tab(text: "Pastelitos", icon: Icon(Icons.cookie_outlined)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: azulPastelOscuro,
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white, size: 30),
          onPressed: () async {
            final resultado = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AgregarTortaScreen()),
            );
            if (resultado == true) cargarTortas();
          },
        ),
        body: cargando 
            ? Center(child: CircularProgressIndicator(color: azulPastelOscuro)) 
            : RefreshIndicator(
                color: azulPastelOscuro,
                onRefresh: cargarTortas,
                child: TabBarView(
                  children: [
                    _buildListaFiltrada("Torta"),
                    _buildListaFiltrada("Tarta"),
                    _buildListaFiltrada("Pastelito"),
                  ],
                ),
              ),
      ),
    );
  }

  // Widget para mostrar cuando NO hay imagen o hay error
  Widget _buildPlaceholderImage(String categoria) {
    IconData iconData;
    switch (categoria.toLowerCase()) {
      case 'tarta':
        iconData = Icons.pie_chart_outline;
        break;
      case 'pastelito':
        iconData = Icons.cookie_outlined;
        break;
      default:
        iconData = Icons.cake_outlined;
    }

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [azulPastelPrincipal.withOpacity(0.4), azulPastelOscuro.withOpacity(0.2)],
        ),
      ),
      child: Icon(iconData, size: 80, color: azulPastelOscuro.withOpacity(0.8)),
    );
  }

  Widget _buildListaFiltrada(String categoria) {
    final listaFiltrada = filtrarDatos(categoria);

    if (listaFiltrada.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_outlined, size: 80, color: azulPastelPrincipal),
              const SizedBox(height: 15),
              Text("No hay ${categoria}s aún", 
                style: TextStyle(color: Colors.blueGrey[300], fontSize: 18, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: listaFiltrada.length,
      itemBuilder: (context, i) {
        final torta = listaFiltrada[i];
        final precio = (torta['tamanos'] != null && (torta['tamanos'] as List).isNotEmpty)
            ? "\$${torta['tamanos'][0]['precio']}"
            : "Consultar";

        final String? urlImagen = torta['imagenUrl'];

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () async {
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetalleTortaScreen(torta: torta)),
                );
                if (resultado == true) cargarTortas();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      // Lógica de Imagen mejorada
                      (urlImagen != null && urlImagen.isNotEmpty)
                      ? Image.network(
                          urlImagen, 
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(categoria),
                        )
                      : _buildPlaceholderImage(categoria),
                      
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            precio,
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          torta['nombre'] ?? "Sin nombre",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          torta['descripcion'] ?? "Sin descripción",
                          style: TextStyle(color: Colors.blueGrey[500], fontSize: 14, height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}