import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; 
import 'package:http_parser/http_parser.dart'; 
import 'dart:io';
import 'dart:convert';

class AgregarTortaScreen extends StatefulWidget {
  const AgregarTortaScreen({super.key});

  @override
  State<AgregarTortaScreen> createState() => _AgregarTortaScreenState();
}

class _AgregarTortaScreenState extends State<AgregarTortaScreen> {
  final nombreCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final codigoCtrl = TextEditingController(); // NUEVO: Controlador para el código
  
  File? _imagen;
  final ImagePicker _picker = ImagePicker();

  final Color azulPastelFondo = const Color(0xFFF0F8FF); 
  final Color azulPastelPrincipal = const Color(0xFFB3E5FC); 
  final Color azulPastelOscuro = const Color(0xFF81D4FA); 

  String categoriaSeleccionada = "Torta";
  final List<String> categorias = ["Torta", "Tarta", "Pastelito"];

  // --- ESTRUCTURA ESCALABLE ---
  List<Map<String, dynamic>> tamanos = [];
  bool guardando = false;

  // --- VARIABLES PARA EL CATÁLOGO GLOBAL ---
  List<dynamic> catalogoCoberturas = []; 
  List<int> coberturasSeleccionadasIds = [];
  bool cargandoCoberturas = true;

  @override
  void initState() {
    super.initState();
    _cargarCatalogoCoberturas();
  }

  // Descarga las coberturas disponibles desde el backend
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
      setState(() {
        _imagen = File(foto.path);
      });
    }
  }

  void agregarCampoTamano() {
    setState(() {
      tamanos.add({"capacidad": "", "precio": 0.0});
    });
  }

  void quitarTamano(int index) {
    setState(() {
      tamanos.removeAt(index);
    });
  }

  Future<void> guardarTorta() async {
    if (nombreCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, ingresa el nombre")),
      );
      return;
    }

    if (tamanos.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Agrega al menos un tamaño o cantidad con su precio.")),
      );
      return;
    }
    
    setState(() => guardando = true);

    try {
      final url = Uri.parse('https://pasteleria-backend-production-24fc.up.railway.app/api/tortas');
      var request = http.MultipartRequest('POST', url);

      // Datos básicos
      request.fields['nombre'] = nombreCtrl.text;
      request.fields['descripcion'] = descCtrl.text;
      request.fields['categoria'] = categoriaSeleccionada;
      
      // NUEVO: Enviamos el código de barras/venta rápida si no está vacío
      if (codigoCtrl.text.isNotEmpty) {
        request.fields['codigoBarrasBase'] = codigoCtrl.text;
      }
      
      // Enviamos los tamaños como JSON String
      request.fields['tamanosJson'] = json.encode(tamanos);
      
      // Enviamos los IDs como JSON String solo si es Torta
      if (categoriaSeleccionada == "Torta") {
         request.fields['coberturasIds'] = json.encode(coberturasSeleccionadasIds);
      } else {
         request.fields['coberturasIds'] = "[]";
      }

      if (_imagen != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file', 
            _imagen!.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Producto guardado!")));
          Navigator.pop(context, true);
        }
      } else {
        debugPrint("Error del servidor: ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al guardar. Verifica los datos.")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error al guardar: $e");
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error de conexión al guardar el producto.")),
          );
        }
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: azulPastelFondo,
      appBar: AppBar(
        title: const Text("Nuevo Producto 🎂", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: azulPastelPrincipal,
        foregroundColor: Colors.blueGrey[800],
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- TARJETA DE INFORMACIÓN BÁSICA ---
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
                  Text("Tipo de Producto", 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
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
                  TextField(
                    controller: codigoCtrl, 
                    keyboardType: TextInputType.number, // Teclado numérico para el código rápido
                    decoration: _inputStyle("Código de producto (Ej: 10001)"),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: nombreCtrl, 
                    decoration: _inputStyle("Nombre del producto"),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: descCtrl, 
                    maxLines: 3,
                    decoration: _inputStyle("Descripción"),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // --- SECCIÓN DE FOTO ---
          Text("Foto del Producto (Opcional)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
          const SizedBox(height: 10),
          _buildFotoArea(),
          
          const SizedBox(height: 20),

          // --- SECCIÓN DE PRECIOS Y TAMAÑOS ---
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
                      Icon(categoriaSeleccionada == "Pastelito" ? Icons.cookie : Icons.straighten, 
                           color: azulPastelOscuro),
                      const SizedBox(width: 8),
                      Text(
                        categoriaSeleccionada == "Pastelito" ? "Precios por Cantidad" : "Tamaños y Precios", 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),

                  if (tamanos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text("Agrega al menos un precio para este producto.", 
                        style: TextStyle(color: Colors.blueGrey[300], fontStyle: FontStyle.italic)),
                    ),

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

          // --- SECCIÓN DE COBERTURAS (SOLO TORTAS) ---
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
                        Text("Coberturas Adicionales", 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text("Marca las coberturas disponibles para esta torta.", 
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const Divider(),
                    
                    cargandoCoberturas 
                      ? Center(child: Padding(padding: const EdgeInsets.all(20.0), child: CircularProgressIndicator(color: azulPastelOscuro)))
                      : catalogoCoberturas.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("No hay coberturas creadas. Créalas primero en la Administración.", 
                              style: TextStyle(color: Colors.redAccent, fontStyle: FontStyle.italic)),
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
            onPressed: guardando ? null : guardarTorta,
            style: ElevatedButton.styleFrom(
              backgroundColor: azulPastelOscuro, 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
            child: guardando 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : const Text("GUARDAR PRODUCTO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

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
        child: _imagen == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 60, color: azulPastelOscuro),
                  const SizedBox(height: 8),
                  const Text("Toca para abrir la cámara", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500)),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13), 
                    child: Image.file(_imagen!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                        onPressed: _tomarFoto,
                      ),
                    ),
                  )
                ],
              ),
      ),
    );
  }

  Widget _buildTamanoItem(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3, 
            child: TextField(
              // NUEVO: Esto fuerza a que salga el teclado numérico de Instagram que querías
              keyboardType: TextInputType.number, 
              decoration: _inputStyle(categoriaSeleccionada == "Pastelito" ? "Ej: 12" : "Ej: 15"),
              onChanged: (val) => tamanos[index]["capacidad"] = val,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3, 
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: _inputStyle("Precio \$"),
              onChanged: (val) => tamanos[index]["precio"] = double.tryParse(val) ?? 0.0,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
            onPressed: () => quitarTamano(index),
          )
        ],
      ),
    );
  }
}