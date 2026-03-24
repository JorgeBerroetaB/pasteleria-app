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

  Future<void> _guardarCobertura(String nombre, List<Map<String, dynamic>> precios, {int? id}) async {
    final body = json.encode({
      "nombre": nombre,
      "precios": precios 
    });
    
    try {
      http.Response res;
      if (id == null) {
        res = await http.post(
          Uri.parse('$_baseUrl/coberturas'),
          headers: {"Content-Type": "application/json"},
          body: body,
        );
      } else {
        res = await http.put(
          Uri.parse('$_baseUrl/coberturas/$id'),
          headers: {"Content-Type": "application/json"},
          body: body,
        );
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        _mostrarMensaje(id == null ? "Cobertura creada" : "Cobertura actualizada");
        _cargarCoberturas();
      } else {
        _mostrarMensaje("Error al guardar. Verifica los datos.");
        debugPrint("Error del server: ${res.body}");
      }
    } catch (e) {
      debugPrint("Error: $e");
      _mostrarMensaje("Error de conexión al guardar");
    }
  }

  Future<void> _eliminarCobertura(int id) async {
    try {
      final res = await http.delete(Uri.parse('$_baseUrl/coberturas/$id'));
      if (res.statusCode == 200 || res.statusCode == 204) {
        _mostrarMensaje("Cobertura eliminada");
        _cargarCoberturas();
      } else {
        _mostrarMensaje("No se pudo eliminar (Puede estar en uso)");
      }
    } catch (e) {
      debugPrint("Error: $e");
      _mostrarMensaje("Error de conexión al eliminar");
    }
  }

  void _mostrarFormulario({Map<String, dynamic>? coberturaActual}) {
    final TextEditingController nombreCtrl = TextEditingController(
      text: coberturaActual != null ? coberturaActual['nombre'] : ""
    );

    final TextEditingController capacidadCtrl = TextEditingController();
    final TextEditingController precioCtrl = TextEditingController();

    List<Map<String, dynamic>> precios = [];
    if (coberturaActual != null && coberturaActual['precios'] != null) {
      precios = List<Map<String, dynamic>>.from(coberturaActual['precios']);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: azulPastelFondo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: Text(
                coberturaActual == null ? "Nueva Cobertura" : "Editar Cobertura",
                style: TextStyle(color: Colors.blueGrey[800], fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreCtrl,
                      decoration: InputDecoration(
                        labelText: "Nombre (Ej: Crema Chantilly)",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: azulPastelPrincipal.withOpacity(0.5))),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Text("Precios Adicionales", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
                    const Divider(),
                    
                    ...precios.map((p) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text("${p['capacidad']} pax"),
                      subtitle: Text("\$${p['precioAdicional'] ?? 0}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                        onPressed: () {
                          setStateDialog(() {
                            precios.remove(p);
                          });
                        },
                      ),
                    )),

                    const SizedBox(height: 10),
                    
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: capacidadCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Pax (Ej: 15)",
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: precioCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Precio \$",
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
                          onPressed: () {
                            if (capacidadCtrl.text.isNotEmpty && precioCtrl.text.isNotEmpty) {
                              setStateDialog(() {
                                precios.add({
                                  "capacidad": int.tryParse(capacidadCtrl.text.trim()) ?? 0,
                                  "precioAdicional": double.tryParse(precioCtrl.text.trim()) ?? 0.0
                                });
                                capacidadCtrl.clear();
                                precioCtrl.clear();
                              });
                            }
                          },
                        )
                      ],
                    )
                  ],
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
                        precios, 
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
    );
  }

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
                      // --- AHORA TODA LA CARTA SE PUEDE PRESIONAR PARA EDITAR ---
                      child: ListTile(
                        onTap: () => _mostrarFormulario(coberturaActual: cob),
                        leading: CircleAvatar(
                          backgroundColor: azulPastelFondo,
                          child: Icon(Icons.palette_outlined, color: azulPastelOscuro),
                        ),
                        title: Text(
                          cob['nombre'], 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800])
                        ),
                        // --- SOLO QUEDA EL BOTÓN DE BORRAR A LA DERECHA ---
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _confirmarEliminacion(cob['id'], cob['nombre']),
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