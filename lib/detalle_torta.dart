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
  // Colores Pastel definidos para coherencia
  final Color azulPastelFondo = const Color(0xFFF0F8FF);
  final Color azulPastelPrincipal = const Color(0xFFB3E5FC);
  final Color azulPastelOscuro = const Color(0xFF81D4FA);

  // Variable para el tipo de cobertura seleccionada
  String coberturaSeleccionada = "Merengue";

  // Tabla de recargos fijos de tu Excel para Crema Chantilly
  final Map<String, int> recargosChantilly = {
    "10": 1500,
    "15": 3000,
    "20": 4500,
    "30": 6000,
    "40": 8000,
    "50": 10000,
  };

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

  // Función para calcular el precio final con recargo si aplica
  String calcularPrecio(dynamic precioBase, dynamic capacidad) {
    double base = double.tryParse(precioBase.toString()) ?? 0.0;
    
    if (coberturaSeleccionada == "Crema") {
      // Extraemos solo los números de la capacidad (ej: "20 personas" -> "20")
      String clave = capacidad.toString().replaceAll(RegExp(r'[^0-9]'), '');
      int extra = recargosChantilly[clave] ?? 0;
      return (base + extra).toStringAsFixed(0);
    }
    
    return base.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final List tamanos = widget.torta['tamanos'] is List ? widget.torta['tamanos'] : [];
    final String urlImagen = widget.torta['imagenUrl'] ?? "";
    // Verificamos si la torta permite cobertura variada desde el backend
    final bool permiteDobleCobertura = widget.torta['coberturaVariada'] == true || widget.torta['coberturaVariada'] == "true";

    return Scaffold(
      backgroundColor: azulPastelFondo,
      appBar: AppBar(
        title: Text(widget.torta['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: azulPastelPrincipal,
        foregroundColor: Colors.blueGrey[800],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: "Editar producto",
            onPressed: () async {
              final resultado = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditarTortaScreen(torta: widget.torta)),
              );
              if (resultado == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "Eliminar producto",
            onPressed: () => eliminarTorta(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: urlImagen.isNotEmpty 
              ? Image.network(
                  urlImagen, 
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Icon(Icons.cake, size: 100, color: azulPastelOscuro),
                )
              : Icon(Icons.cake, size: 100, color: azulPastelOscuro),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(25),
              children: [
                Text(
                  widget.torta['nombre'],
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.torta['categoria'] ?? "Repostería",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: azulPastelOscuro),
                ),
                const SizedBox(height: 15),
                Text(
                  widget.torta['descripcion'] ?? "Sin descripción disponible.",
                  style: TextStyle(fontSize: 16, height: 1.5, color: Colors.blueGrey[600]),
                ),
                
                // --- SECCIÓN NUEVA: SELECTOR DE COBERTURA ---
                if (permiteDobleCobertura) ...[
                  const SizedBox(height: 30),
                  Text("Tipo de Cobertura:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text("Merengue"),
                        selected: coberturaSeleccionada == "Merengue",
                        selectedColor: azulPastelPrincipal,
                        onSelected: (val) => setState(() => coberturaSeleccionada = "Merengue"),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text("Crema Chantilly"),
                        selected: coberturaSeleccionada == "Crema",
                        selectedColor: Colors.orange[100],
                        onSelected: (val) => setState(() => coberturaSeleccionada = "Crema"),
                      ),
                    ],
                  ),
                ],
                // --------------------------------------------

                const SizedBox(height: 35),
                Row(
                  children: [
                    Icon(Icons.payments_outlined, color: azulPastelOscuro),
                    const SizedBox(width: 10),
                    Text(
                      "Precios según Capacidad",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
                    ),
                  ],
                ),
                const Divider(),
                
                if (tamanos.isEmpty)
                  Text("Consulte disponibilidad.", style: TextStyle(color: Colors.blueGrey[400], fontStyle: FontStyle.italic))
                else
                  ...tamanos.map((t) {
                    String precioFinal = calcularPrecio(t['precio'], t['capacidad']);
                    
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: azulPastelPrincipal.withOpacity(0.3))
                      ),
                      child: ListTile(
                        leading: Icon(Icons.cake_outlined, color: azulPastelOscuro),
                        title: Text("${t['capacidad']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text(
                          "\$$precioFinal", 
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]),
                        ),
                      ),
                    );
                  }).toList(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}