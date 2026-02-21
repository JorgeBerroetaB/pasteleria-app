import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'editar_torta.dart';

class DetalleTortaScreen extends StatelessWidget {
  final Map torta;

  const DetalleTortaScreen({super.key, required this.torta});

  Future<void> eliminarTorta(BuildContext context) async {
    final confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar Torta?"),
        content: Text("¿Seguro que quieres borrar la '${torta['nombre']}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text("Cancelar")
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("BORRAR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final url = Uri.parse('http://192.168.1.86:8080/api/tortas/${torta['id']}');

    try {
      final res = await http.delete(url);

      if (res.statusCode == 200 || res.statusCode == 204) {
        if (context.mounted) {
           Navigator.pop(context, true); 
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al borrar: ${res.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error de conexión con el servidor")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List tamanos = torta['tamanos'] is List ? torta['tamanos'] : [];
    
    // --- CONSTRUCCIÓN DE LA URL DE LA IMAGEN ---
    final String nombreImagen = torta['imagenUrl'] ?? "";
    final String urlCompleta = "http://192.168.1.86:8080/uploads/$nombreImagen";

    return Scaffold(
      appBar: AppBar(
        title: Text(torta['nombre']),
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final resultado = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditarTortaScreen(torta: torta)),
              );
              if (resultado == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => eliminarTorta(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 250,
            width: double.infinity,
            color: Colors.orange[50],
            child: Image.network(
              urlCompleta, // USAMOS LA URL CONSTRUIDA
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (c, e, s) => const Icon(Icons.cake, size: 100, color: Colors.orange),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  torta['nombre'],
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.brown),
                ),
                const SizedBox(height: 10),
                Text(
                  torta['descripcion'] ?? "Sin descripción",
                  style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                ),
                const SizedBox(height: 30),
                const Text(
                  "📏 Tamaños y Precios",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const Divider(),
                
                if (tamanos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text("Consulte disponibilidad y precios en el local."),
                  )
                else
                  ...tamanos.map((t) => ListTile(
                    leading: const Icon(Icons.groups, color: Colors.orangeAccent),
                    title: Text("Capacidad: ${t['capacidad']}"), 
                    trailing: Text(
                      "\$${t['precio']}", 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  )).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}