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

  // --- LÓGICA DE CÁLCULO ACTUALIZADA ---
  double obtenerPrecioExtra(dynamic capacidad) {
    if (coberturaSeleccionada == null) return 0.0;
    
    List preciosExtra = coberturaSeleccionada!['precios'] ?? [];
    
    // Buscamos el precio extra que coincida con la capacidad del tamaño actual
    var precioExtraObj = preciosExtra.firstWhere(
      (p) => p['capacidad'].toString() == capacidad.toString(),
      orElse: () => null,
    );
    
    if (precioExtraObj != null) {
      // Usamos 'precioExtra' que es como lo definimos en el Backend
      return double.tryParse(precioExtraObj['precioExtra'].toString()) ?? 0.0;
    }
    return 0.0;
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
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final resultado = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditarTortaScreen(torta: widget.torta)),
              );
              // Si se editó algo, volvemos a la lista para refrescar
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
          Container(
            height: 230,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
            ),
            child: urlImagen.isNotEmpty 
              ? Image.network(urlImagen, fit: BoxFit.cover)
              : Icon(Icons.cake, size: 100, color: azulPastelOscuro.withOpacity(0.5)),
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
                  widget.torta['categoria']?.toUpperCase() ?? "REPOSTERÍA",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: azulPastelOscuro, letterSpacing: 1.2),
                ),
                const SizedBox(height: 15),
                Text(
                  widget.torta['descripcion'] ?? "Sin descripción.",
                  style: TextStyle(fontSize: 15, color: Colors.blueGrey[600], height: 1.4),
                ),
                
                if (coberturas.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  const Text("✨ Personaliza la Cobertura", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text("Base / Merengue"),
                        selected: coberturaSeleccionada == null,
                        onSelected: (val) => setState(() => coberturaSeleccionada = null),
                        selectedColor: azulPastelPrincipal,
                        backgroundColor: Colors.white,
                        checkmarkColor: Colors.blueGrey[800],
                        side: BorderSide(color: coberturaSeleccionada == null ? azulPastelOscuro : azulPastelPrincipal.withOpacity(0.5)),
                      ),
                      ...coberturas.map((cob) {
                        final isSelected = coberturaSeleccionada != null && coberturaSeleccionada!['id'] == cob['id'];
                        return ChoiceChip(
                          label: Text(cob['nombre']),
                          selected: isSelected,
                          selectedColor: azulPastelPrincipal,
                          backgroundColor: Colors.white,
                          checkmarkColor: Colors.blueGrey[800],
                          side: BorderSide(color: isSelected ? azulPastelOscuro : azulPastelPrincipal.withOpacity(0.5)),
                          onSelected: (val) => setState(() => coberturaSeleccionada = (val ? cob : null)),
                        );
                      }).toList(),
                    ],
                  ),
                ],

                const SizedBox(height: 30),
                Row(
                  children: [
                    Icon(Icons.payments_outlined, color: Colors.blueGrey[700]),
                    const SizedBox(width: 10),
                    const Text("Precios según Selección", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(),
                
                ...tamanos.map((t) {
                  double base = double.tryParse(t['precio'].toString()) ?? 0.0;
                  double extra = obtenerPrecioExtra(t['capacidad']);
                  double total = base + extra;
                  
                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: azulPastelPrincipal.withOpacity(0.5))
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      // ¡CORRECCIÓN AQUÍ! Ahora solo mostramos la capacidad tal cual la escribió el usuario
                      title: Text("${t['capacidad']}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
                      subtitle: extra > 0 
                        ? Text("Base: \$$base + Extra: \$$extra", style: TextStyle(fontSize: 12, color: Colors.blueGrey[500]))
                        : Text("Precio estándar", style: TextStyle(fontSize: 12, color: Colors.blueGrey[400])),
                      trailing: Text(
                        "\$${total.toStringAsFixed(0)}", 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]),
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