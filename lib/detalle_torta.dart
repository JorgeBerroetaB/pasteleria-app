import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'editar_torta.dart';

class DetalleTortaScreen extends StatefulWidget {
  final Map torta;

  const DetalleTortaScreen({super.key, required this.torta});

  @override
  State<DetalleTortaScreen> createState() => _DetalleTortaScreenState();
}

class _DetalleTortaScreenState extends State<DetalleTortaScreen> {
  final Color azulPastelFondo = const Color(0xFFF0F8FF);
  final Color azulPastelPrincipal = const Color(0xFFB3E5FC);
  final Color azulPastelOscuro = const Color(0xFF81D4FA);

  // Ahora la cobertura seleccionada es un objeto Map o null (Base/Merengue)
  Map<String, dynamic>? coberturaSeleccionada;

  Future<void> eliminarTorta(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: azulPastelFondo,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¿Eliminar Producto?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("¿Seguro que quieres borrar '${widget.torta['nombre']}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: Text("Cancelar", style: TextStyle(color: Colors.blueGrey[400]))
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("BORRAR", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final url = Uri.parse('https://pasteleria-backend-production-24fc.up.railway.app/api/tortas/${widget.torta['id']}');

    try {
      final res = await http.delete(url);
      if (res.statusCode == 200 || res.statusCode == 204) {
        if (context.mounted) Navigator.pop(context, true); 
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // --- NUEVA LÓGICA DE CÁLCULO DINÁMICO ---
  String calcularPrecio(dynamic precioBase, dynamic capacidad) {
    double total = double.tryParse(precioBase.toString()) ?? 0.0;
    
    if (coberturaSeleccionada != null) {
      // Buscamos en la cobertura seleccionada el precio extra para esta capacidad
      List preciosExtra = coberturaSeleccionada!['precios'] ?? [];
      var precioExtraObj = preciosExtra.firstWhere(
        (p) => p['capacidad'].toString() == capacidad.toString(),
        orElse: () => null,
      );
      
      if (precioExtraObj != null) {
        total += double.tryParse(precioExtraObj['precioAdicional'].toString()) ?? 0.0;
      }
    }
    
    return total.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final List tamanos = widget.torta['tamanos'] ?? [];
    final List coberturas = widget.torta['coberturas'] ?? [];
    final String urlImagen = widget.torta['imagenUrl'] ?? "";

    return Scaffold(
      backgroundColor: azulPastelFondo,
      appBar: AppBar(
        title: const Text("Detalle del Producto", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: azulPastelPrincipal,
        foregroundColor: Colors.blueGrey[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final resultado = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditarTortaScreen(torta: widget.torta)),
              );
              if (resultado == true && context.mounted) Navigator.pop(context, true);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => eliminarTorta(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Área de Imagen
          Container(
            height: 230,
            width: double.infinity,
            color: Colors.white,
            child: urlImagen.isNotEmpty 
              ? Image.network(urlImagen, fit: BoxFit.cover)
              : Icon(Icons.cake, size: 100, color: azulPastelOscuro),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(25),
              children: [
                Text(
                  widget.torta['nombre'] ?? "Sin nombre",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
                ),
                Text(
                  widget.torta['categoria'] ?? "Repostería",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: azulPastelOscuro),
                ),
                const SizedBox(height: 15),
                Text(
                  widget.torta['descripcion'] ?? "Sin descripción.",
                  style: TextStyle(fontSize: 15, color: Colors.blueGrey[600]),
                ),
                
                // --- SELECTOR DE COBERTURAS DINÁMICO ---
                if (coberturas.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  const Text("Personaliza tu cobertura:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      // Opción por defecto (Sin extra)
                      ChoiceChip(
                        label: const Text("Base / Merengue"),
                        selected: coberturaSeleccionada == null,
                        onSelected: (val) => setState(() => coberturaSeleccionada = null),
                      ),
                      // Opciones de la base de datos
                      ...coberturas.map((cob) {
                        return ChoiceChip(
                          label: Text(cob['nombre']),
                          selected: coberturaSeleccionada == cob,
                          selectedColor: azulPastelPrincipal,
                          onSelected: (val) => setState(() => coberturaSeleccionada = cob),
                        );
                      }).toList(),
                    ],
                  ),
                ],

                const SizedBox(height: 30),
                const Row(
                  children: [
                    Icon(Icons.list_alt, color: Colors.blueGrey),
                    SizedBox(width: 10),
                    Text("Precios Calculados", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(),
                
                ...tamanos.map((t) {
                  String precioFinal = calcularPrecio(t['precio'], t['capacidad']);
                  
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: azulPastelPrincipal.withOpacity(0.5))
                    ),
                    child: ListTile(
                      title: Text("${t['capacidad']} personas", style: const TextStyle(fontWeight: FontWeight.w500)),
                      trailing: Text(
                        "\$$precioFinal", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: azulPastelOscuro),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}