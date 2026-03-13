import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GestionCoberturasScreen extends StatefulWidget {
  const GestionCoberturasScreen({super.key});

  @override
  State<GestionCoberturasScreen> createState() => _GestionCoberturasScreenState();
}

class _GestionCoberturasScreenState extends State<GestionCoberturasScreen> {
  final Color azulPastelFondo = const Color(0xFFF0F8FF); 
  final Color azulPastelPrincipal = const Color(0xFFB3E5FC); 
  final Color azulPastelOscuro = const Color(0xFF81D4FA); 

  final String _baseUrl = "https://pasteleria-backend-production-24fc.up.railway.app/api";
  
  List<dynamic> coberturas = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCoberturas();
  }

  // --- OBTENER TODAS LAS COBERTURAS ---
  Future<void> _cargarCoberturas() async {
    setState(() => cargando = true);
    try {
      final url = Uri.parse('$_baseUrl/coberturas');
      final res = await http.get(url);
      
      if (res.statusCode == 200) {
        setState(() {
          coberturas = json.decode(res.body);
          cargando = false;
        });
      } else {
        _mostrarMensaje("Error al cargar las coberturas");
        setState(() => cargando = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      _mostrarMensaje("Error de conexión al cargar");
      setState(() => cargando = false);
    }
  }

  // --- CREAR O EDITAR COBERTURA ---
  Future<void> _guardarCobertura(String nombre, {int? id}) async {
    final body = json.encode({"nombre": nombre});
    
    try {
      http.Response res;
      if (id == null) {
        // Crear
        res = await http.post(
          Uri.parse('$_baseUrl/coberturas'),
          headers: {"Content-Type": "application/json"},
          body: body,
        );
      } else {
        // Editar
        res = await http.put(
          Uri.parse('$_baseUrl/coberturas/$id'),
          headers: {"Content-Type": "application/json"},
          body: body,
        );
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        _mostrarMensaje(id == null ? "Cobertura creada" : "Cobertura actualizada");
        _cargarCoberturas(); // Recargar la lista
      } else {
        _mostrarMensaje("Error al guardar la cobertura");
      }
    } catch (e) {
      debugPrint("Error: $e");
      _mostrarMensaje("Error de conexión al guardar");
    }
  }

  // --- ELIMINAR COBERTURA ---
  Future<void> _eliminarCobertura(int id) async {
    try {
      final res = await http.delete(Uri.parse('$_baseUrl/coberturas/$id'));
      if (res.statusCode == 200 || res.statusCode == 204) {
        _mostrarMensaje("Cobertura eliminada");
        _cargarCoberturas();
      } else {
        _mostrarMensaje("No se pudo eliminar (Puede estar en uso por un producto)");
      }
    } catch (e) {
      debugPrint("Error: $e");
      _mostrarMensaje("Error de conexión al eliminar");
    }
  }

  // --- DIÁLOGO FORMULARIO ---
  void _mostrarFormulario({Map<String, dynamic>? coberturaActual}) {
    final TextEditingController nombreCtrl = TextEditingController(
      text: coberturaActual != null ? coberturaActual['nombre'] : ""
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: azulPastelFondo,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            coberturaActual == null ? "Nueva Cobertura" : "Editar Cobertura",
            style: TextStyle(color: Colors.blueGrey[800], fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: nombreCtrl,
            decoration: InputDecoration(
              labelText: "Nombre de la cobertura",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: azulPastelPrincipal.withOpacity(0.5))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nombreCtrl.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  _guardarCobertura(
                    nombreCtrl.text.trim(), 
                    id: coberturaActual?['id']
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: azulPastelOscuro,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("GUARDAR"),
            ),
          ],
        );
      }
    );
  }

  // --- DIÁLOGO DE CONFIRMACIÓN PARA ELIMINAR ---
  void _confirmarEliminacion(int id, String nombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: azulPastelFondo,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("¿Eliminar cobertura?"),
        content: Text("¿Estás seguro de que deseas eliminar '$nombre'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarCobertura(id);
            },
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _mostrarMensaje(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: Colors.blueGrey[900])),
        backgroundColor: azulPastelPrincipal,
        duration: const Duration(seconds: 2),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: azulPastelFondo,
      appBar: AppBar(
        title: const Text("Gestionar Coberturas 🧁", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: azulPastelPrincipal,
        foregroundColor: Colors.blueGrey[800],
        elevation: 0,
      ),
      body: cargando
          ? Center(child: CircularProgressIndicator(color: azulPastelOscuro))
          : coberturas.isEmpty
              ? Center(
                  child: Text("No hay coberturas registradas",
                      style: TextStyle(color: Colors.blueGrey[300], fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: coberturas.length,
                  itemBuilder: (context, index) {
                    final cob = coberturas[index];
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: azulPastelPrincipal.withOpacity(0.5)),
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: azulPastelFondo,
                          child: Icon(Icons.palette_outlined, color: azulPastelOscuro),
                        ),
                        title: Text(
                          cob['nombre'], 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800])
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () => _mostrarFormulario(coberturaActual: cob),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _confirmarEliminacion(cob['id'], cob['nombre']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(),
        backgroundColor: azulPastelOscuro,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Nueva Cobertura", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}