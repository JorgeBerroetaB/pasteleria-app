import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'dart:convert';

class EditarTortaScreen extends StatefulWidget {
  final Map torta;
  const EditarTortaScreen({super.key, required this.torta});

  @override
  State<EditarTortaScreen> createState() => _EditarTortaScreenState();
}

class _EditarTortaScreenState extends State<EditarTortaScreen> {
  late TextEditingController nombreCtrl;
  late TextEditingController descCtrl;
  
  final Color azulPastelFondo = const Color(0xFFF0F8FF);
  final Color azulPastelPrincipal = const Color(0xFFB3E5FC);
  final Color azulPastelOscuro = const Color(0xFF81D4FA);

  File? _nuevaImagen;
  final ImagePicker _picker = ImagePicker();
  
  late String categoriaSeleccionada;
  final List<String> categorias = ["Torta", "Tarta", "Pastelito"];
  
  List<Map<String, dynamic>> tamanos = [];
  bool guardando = false;

  // --- VARIABLES PARA COBERTURAS ---
  List<dynamic> catalogoCoberturas = []; 
  List<int> coberturasSeleccionadasIds = [];
  bool cargandoCoberturas = true;

  final String _baseUrl = "https://pasteleria-backend-production-24fc.up.railway.app/api/tortas";

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController(text: widget.torta['nombre']);
    descCtrl = TextEditingController(text: widget.torta['descripcion']);
    categoriaSeleccionada = widget.torta['categoria'] ?? "Torta";
    
    // Cargar tamaños actuales
    if (widget.torta['tamanos'] != null) {
      for (var t in widget.torta['tamanos']) {
        tamanos.add({
          "id": t['id'], // Conservamos el ID para que el backend sepa que se está editando
          "capacidad": t['capacidad'].toString(),
          "precio": double.tryParse(t['precio'].toString()) ?? 0.0
        });
      }
    }

    // Pre-cargar las coberturas que ya tiene la torta
    if (widget.torta['coberturas'] != null) {
      for (var c in widget.torta['coberturas']) {
        coberturasSeleccionadasIds.add(c['id']);
      }
    }

    _cargarCatalogoCoberturas();
  }

  Future<void> _cargarCatalogoCoberturas() async {
    try {
      final res = await http.get(Uri.parse('https://pasteleria-backend-production-24fc.up.railway.app/api/coberturas'));
      if (res.statusCode == 200) {
        if(mounted) {
          setState(() {
            catalogoCoberturas = json.decode(res.body);
            cargandoCoberturas = false;
          });
        }
      } else {
        if(mounted) setState(() => cargandoCoberturas = false);
      }
    } catch (e) {
      debugPrint("Error cargando catálogo: $e");
      if(mounted) setState(() => cargandoCoberturas = false);
    }
  }

  Future<void> _tomarFoto() async {
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (foto != null) {
      setState(() => _nuevaImagen = File(foto.path));
    }
  }

  void agregarCampoTamano() {
    setState(() {
      // Un nuevo tamaño no tiene ID aún, el backend se lo asignará
      tamanos.add({"capacidad": "", "precio": 0.0});
    });
  }

  void quitarTamano(int index) {
    setState(() {
      tamanos.removeAt(index);
    });
  }

  Future<void> actualizarTorta() async {
    if (nombreCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El nombre es obligatorio")));
      return;
    }

    if (tamanos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Agrega al menos un precio")));
      return;
    }

    setState(() => guardando = true);

    try {
      final url = Uri.parse('$_baseUrl/${widget.torta['id']}');
      var request = http.MultipartRequest('PUT', url);

      request.fields['nombre'] = nombreCtrl.text;
      request.fields['descripcion'] = descCtrl.text;
      request.fields['categoria'] = categoriaSeleccionada;
      request.fields['tamanosJson'] = json.encode(tamanos);
      
      if (categoriaSeleccionada == "Torta") {
         request.fields['coberturasIds'] = json.encode(coberturasSeleccionadasIds);
      } else {
         request.fields['coberturasIds'] = "[]";
      }

      if (_nuevaImagen != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file', 
            _nuevaImagen!.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Producto actualizado!")));
          Navigator.pop(context, true);
        }
      } else {
        debugPrint("Error: ${response.body}");
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al actualizar")));
      }
    } catch (e) {
      debugPrint("Error al actualizar: $e");
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: azulPastelFondo,
      appBar: AppBar(
        title: const Text("Editar Producto", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: azulPastelPrincipal,
        foregroundColor: Colors.blueGrey[800],
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- TARJETA DATOS BÁSICOS ---
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: azulPastelPrincipal.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tipo de Producto", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: azulPastelFondo,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: azulPastelPrincipal.withOpacity(0.5)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: categoriaSeleccionada,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        icon: Icon(Icons.keyboard_arrow_down, color: azulPastelOscuro),
                        items: categorias.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: TextStyle(color: Colors.blueGrey[800])),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            categoriaSeleccionada = newValue!;
                            if (categoriaSeleccionada != "Torta") coberturasSeleccionadasIds.clear();
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(controller: nombreCtrl, decoration: _inputStyle("Nombre del producto")),
                  const SizedBox(height: 15),
                  TextField(controller: descCtrl, maxLines: 3, decoration: _inputStyle("Descripción")),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          Text("Foto del Producto", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
          const SizedBox(height: 10),
          _buildFotoArea(),

          const SizedBox(height: 20),

          // --- TARJETA DE TAMAÑOS ---
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: azulPastelPrincipal.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(categoriaSeleccionada == "Pastelito" ? Icons.cookie : Icons.straighten, color: azulPastelOscuro),
                      const SizedBox(width: 8),
                      Text(
                        categoriaSeleccionada == "Pastelito" ? "Precios por Cantidad" : "Tamaños y Precios", 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),

                  ...tamanos.asMap().entries.map((entry) => _buildTamanoItem(entry.key)),

                  Center(
                    child: TextButton.icon(
                      onPressed: agregarCampoTamano,
                      icon: Icon(Icons.add_circle_outline, color: azulPastelOscuro),
                      label: Text(
                        categoriaSeleccionada == "Pastelito" ? "Agregar Variedad" : "Agregar Tamaño",
                        style: TextStyle(color: azulPastelOscuro, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- TARJETA DE COBERTURAS ---
          if (categoriaSeleccionada == "Torta") ...[
            const SizedBox(height: 20),
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: azulPastelPrincipal.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette, color: azulPastelOscuro),
                        const SizedBox(width: 8),
                        Text("Coberturas Disponibles", 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text("Gestiona qué coberturas se ofrecen para este producto.", 
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const Divider(),
                    
                    cargandoCoberturas 
                      ? Center(child: Padding(padding: const EdgeInsets.all(20.0), child: CircularProgressIndicator(color: azulPastelOscuro)))
                      : catalogoCoberturas.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("No hay coberturas creadas.", style: TextStyle(color: Colors.redAccent, fontStyle: FontStyle.italic)),
                          )
                        : Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: catalogoCoberturas.map((cob) {
                              final isSelected = coberturasSeleccionadasIds.contains(cob['id']);
                              return FilterChip(
                                label: Text(cob['nombre']),
                                selected: isSelected,
                                selectedColor: azulPastelPrincipal,
                                checkmarkColor: Colors.blueGrey[800],
                                backgroundColor: azulPastelFondo,
                                side: BorderSide(color: isSelected ? azulPastelOscuro : azulPastelPrincipal.withOpacity(0.5)),
                                onSelected: (bool seleccionado) {
                                  setState(() {
                                    if (seleccionado) {
                                      coberturasSeleccionadasIds.add(cob['id']);
                                    } else {
                                      coberturasSeleccionadasIds.remove(cob['id']);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: guardando ? null : actualizarTorta,
            style: ElevatedButton.styleFrom(
              backgroundColor: azulPastelOscuro,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: guardando 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text("GUARDAR CAMBIOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- WIDGETS DE APOYO REFACTORIZADOS ---

  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.blueGrey[400]),
      filled: true,
      fillColor: azulPastelFondo.withOpacity(0.5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: azulPastelPrincipal.withOpacity(0.5)), borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: azulPastelPrincipal, width: 2), borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildFotoArea() {
    return GestureDetector(
      onTap: _tomarFoto,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: azulPastelPrincipal.withOpacity(0.8), width: 2),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: _nuevaImagen != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.file(_nuevaImagen!, fit: BoxFit.cover, width: double.infinity),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.network(
                      widget.torta['imagenUrl'] ?? "",
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (c, e, s) => Icon(Icons.cake, size: 60, color: azulPastelOscuro.withOpacity(0.5)),
                    ),
                  ),
            ),
            Positioned(
              bottom: 10, right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTamanoItem(int i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: tamanos[i]['capacidad'].toString(),
              keyboardType: TextInputType.text,
              decoration: _inputStyle(categoriaSeleccionada == "Pastelito" ? "Ej: Docena" : "Ej: 15 pax"),
              onChanged: (val) => tamanos[i]['capacidad'] = val,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: tamanos[i]['precio'].toString(),
              keyboardType: TextInputType.number,
              decoration: _inputStyle("Precio \$"),
              onChanged: (val) => tamanos[i]['precio'] = double.tryParse(val) ?? 0.0,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
            onPressed: () => quitarTamano(i),
          )
        ],
      ),
    );
  }
}