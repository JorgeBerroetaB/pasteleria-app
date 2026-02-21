import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'agregar_torta.dart';
import 'detalle_torta.dart';
import 'calendario_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.orange,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFF8E1),
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

  // URL base para las imágenes (Asegúrate de que la IP sea la correcta de tu PC)
  final String urlBaseImagenes = "http://192.168.1.86:8080/uploads/";

  Future<void> cargarTortas() async {
    final url = Uri.parse('http://192.168.1.86:8080/api/tortas'); 
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        setState(() {
          datos = json.decode(res.body);
          cargando = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() => cargando = false);
    }
  }

  @override
  void initState() {
    super.initState();
    cargarTortas();
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
          title: const Text("🍰 Pastelería Dulce Día"),
          centerTitle: true,
          backgroundColor: Colors.orangeAccent,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CalendarioScreen()),
                );
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Tortas", icon: Icon(Icons.cake)),
              Tab(text: "Tartas", icon: Icon(Icons.pie_chart)),
              Tab(text: "Pastelitos", icon: Icon(Icons.cookie)),
            ],
          ),
        ),

        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.orange,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () async {
            final resultado = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AgregarTortaScreen()),
            );
            if (resultado == true) cargarTortas();
          },
        ),

        body: cargando 
            ? const Center(child: CircularProgressIndicator()) 
            : TabBarView(
                children: [
                  _buildListaFiltrada("Torta"),
                  _buildListaFiltrada("Tarta"),
                  _buildListaFiltrada("Pastelito"),
                ],
              ),
      ),
    );
  }

  Widget _buildListaFiltrada(String categoria) {
    final listaFiltrada = filtrarDatos(categoria);

    if (listaFiltrada.isEmpty) {
      return Center(
        child: Text("No hay ${categoria}s aún", style: const TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: listaFiltrada.length,
      itemBuilder: (context, i) {
        final torta = listaFiltrada[i];
        final precio = (torta['tamanos'] != null && torta['tamanos'].isNotEmpty)
            ? "\$${torta['tamanos'][0]['precio']}"
            : "Consultar";

        // Construimos la URL completa usando la IP y el nombre que viene de Java
        final String nombreImagen = torta['imagenUrl'] ?? "";
        final String urlCompletaImagen = "$urlBaseImagenes$nombreImagen";

        return GestureDetector(
          onTap: () async {
            final resultado = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DetalleTortaScreen(torta: torta)),
            );
            if (resultado == true) cargarTortas();
          },
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.network(
                    urlCompletaImagen, // URL CORREGIDA AQUÍ
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        color: Colors.orange[50],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: Colors.orange[100],
                        child: const Center(
                          child: Icon(Icons.cake, size: 50, color: Colors.orange),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            torta['nombre'],
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            precio,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        torta['descripcion'] ?? "",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}