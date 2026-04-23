import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';

// --- IMPORTACIONES DE TUS PANTALLAS ---
import 'agregar_torta.dart';
import 'detalle_torta.dart';
import 'calendario_screen.dart';
import 'gestion_coberturas_screen.dart'; 

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
          // --- ÍCONO DE COBERTURAS A LA IZQUIERDA ---
          leading: IconButton(
            icon: Icon(Icons.palette_outlined, color: Colors.blueGrey[800]),
            tooltip: "Gestionar Coberturas",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GestionCoberturasScreen()),
              );
            },
          ),
          title: Text("Pastelería Dulce Día", 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800], fontSize: 18)),
          backgroundColor: azulPastelPrincipal,
          actions: [
            // --- ÍCONO DEL CALENDARIO A LA DERECHA ---
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

  String _obtenerPrecioTexto(dynamic torta) {
    if (torta['tamanos'] == null || (torta['tamanos'] as List).isEmpty) {
      return "Consultar";
    }
    List tamanos = torta['tamanos'];
    tamanos.sort((a, b) => (a['precio'] ?? 0).compareTo(b['precio'] ?? 0));
    double precioMasBajo = tamanos[0]['precio'].toDouble();
    if (tamanos.length > 1) {
      return "Desde \$${precioMasBajo.toStringAsFixed(0)}";
    } else {
      return "\$${precioMasBajo.toStringAsFixed(0)}";
    }
  }

  Widget _buildPlaceholderImage(String categoria) {
    IconData iconData;
    switch (categoria.toLowerCase()) {
      case 'tarta': iconData = Icons.pie_chart_outline; break;
      case 'pastelito': iconData = Icons.cookie_outlined; break;
      default: iconData = Icons.cake_outlined;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [azulPastelPrincipal.withOpacity(0.4), azulPastelOscuro.withOpacity(0.2)],
        ),
      ),
      child: Center(
        child: Icon(iconData, size: 40, color: azulPastelOscuro.withOpacity(0.8)),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: listaFiltrada.length,
      itemBuilder: (context, i) {
        final torta = listaFiltrada[i];
        final String precioTexto = _obtenerPrecioTexto(torta);
        final String? urlImagen = torta['imagenUrl'];

        // --- TARJETAS MÁS PEQUEÑAS TIPO LISTA ---
        return Container(
          height: 110, // Altura fija reducida para ver más ítems
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              onTap: () async {
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetalleTortaScreen(torta: torta)),
                );
                if (resultado == true) cargarTortas();
              },
              child: Row(
                children: [
                  // Imagen a la izquierda más pequeña
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: (urlImagen != null && urlImagen.isNotEmpty)
                        ? Image.network(
                            urlImagen,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(categoria),
                          )
                        : _buildPlaceholderImage(categoria),
                  ),
                  // Contenido a la derecha
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  torta['nombre'] ?? "Sin nombre",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (torta['coberturas'] != null && (torta['coberturas'] as List).isNotEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(Icons.stars, color: Colors.orangeAccent, size: 16),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            torta['descripcion'] ?? "Sin descripción",
                            style: TextStyle(color: Colors.blueGrey[500], fontSize: 12, height: 1.2),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          // Badge de precio
                          Text(
                            precioTexto,
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              color: azulPastelOscuro.withOpacity(0.9),
                              fontSize: 14
                            ),
                          ),
                        ],
                      ),
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