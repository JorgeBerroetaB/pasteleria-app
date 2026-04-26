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
  final codigoCtrl = TextEditingController(); 
  
  File? _imagen;
  final ImagePicker _picker = ImagePicker();

  final Color azulPastelFondo = const Color(0xFFF0F8FF); 
  final Color azulPastelPrincipal = const Color(0xFFB3E5FC); 
  final Color azulPastelOscuro = const Color(0xFF81D4FA); 

  String categoriaSeleccionada = "Torta";
  final List<String> categorias = ["Torta", "Tarta", "Pastelito"];

  List<Map<String, dynamic>> tamanos = [];
  bool guardando = false;

  List<dynamic> catalogoCoberturas = []; 
  List<int> coberturasSeleccionadasIds = [];
  bool cargandoCoberturas = true;

  @override
  void initState() {
    super.initState();
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
    // 1. Validaciones previas
    if (nombreCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, ingresa el nombre")),
      );
      return;
    }

    if (tamanos.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Agrega al menos un precio.")),
      );
      return;
    }
    
    setState(() => guardando = true);

    try {
      final url = Uri.parse('https://pasteleria-backend-production-24fc.up.railway.app/api/tortas');
      var request = http.MultipartRequest('POST', url);

      
      // 2. Mapeo de campos
      request.fields['nombre'] = nombreCtrl.text;
      request.fields['descripcion'] = descCtrl.text;
      request.fields['categoria'] = categoriaSeleccionada;

      // ESTA LÍNEA ES LA IMPORTANTE:
      // El nombre 'codigoBarrasBase' debe ser idéntico al del @RequestParam del Java
      if (codigoCtrl.text.isNotEmpty) {
        request.fields['codigoBarrasBase'] = codigoCtrl.text; 
      }

      request.fields['tamanosJson'] = json.encode(tamanos);
      request.fields['coberturasIds'] = json.encode(coberturasSeleccionadasIds);

      // 3. Manejo de la foto
      if (_imagen != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file', 
            _imagen!.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      // 4. Envío y respuesta
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("¡Producto guardado correctamente! 🎂"))
          );
          Navigator.pop(context, true); // Cierra la pantalla y refresca la lista
        }
      } else {
        debugPrint("Error del servidor: ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al guardar en el servidor.")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error de conexión: $e");
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
                        items: categorias.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
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
                    keyboardType: TextInputType.number,
                    decoration: _inputStyle("Código (Ej: 650)"),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: nombreCtrl, 
                    decoration: _inputStyle("Nombre del producto"),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: descCtrl, 
                    maxLines: 2,
                    decoration: _inputStyle("Descripción"),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          Text("Foto del Producto", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
          const SizedBox(height: 10),
          _buildFotoArea(),
          
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
                  Text("Tamaños y Precios", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
                  const Divider(),
                  ...tamanos.asMap().entries.map((entry) => _buildTamanoItem(entry.key)),
                  Center(
                    child: TextButton.icon(
                      onPressed: agregarCampoTamano,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text("Agregar Tamaño"),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (categoriaSeleccionada == "Torta") ...[
            const SizedBox(height: 20),
            _buildCoberturasSeccion(),
          ],

          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: guardando ? null : guardarTorta,
            style: ElevatedButton.styleFrom(
              backgroundColor: azulPastelOscuro, 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: guardando 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Text("GUARDAR PRODUCTO", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCoberturasSeccion() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: azulPastelPrincipal.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Coberturas Adicionales", style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            cargandoCoberturas 
              ? const Center(child: CircularProgressIndicator())
              : Wrap(
                  spacing: 8.0,
                  children: catalogoCoberturas.map((cob) {
                    final isSelected = coberturasSeleccionadasIds.contains(cob['id']);
                    return FilterChip(
                      label: Text(cob['nombre']),
                      selected: isSelected,
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
    );
  }

  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: azulPastelFondo.withOpacity(0.5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: azulPastelPrincipal.withOpacity(0.5)), borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildFotoArea() {
    return GestureDetector(
      onTap: _tomarFoto,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: azulPastelPrincipal.withOpacity(0.8), width: 2),
        ),
        child: _imagen == null
            ? const Center(child: Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey))
            : ClipRRect(
                borderRadius: BorderRadius.circular(13), 
                child: Image.file(_imagen!, fit: BoxFit.cover),
              ),
      ),
    );
  }

  Widget _buildTamanoItem(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number, 
              decoration: _inputStyle("Capacidad"),
              onChanged: (val) => tamanos[index]["capacidad"] = val,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: _inputStyle("Precio \$"),
              onChanged: (val) => tamanos[index]["precio"] = double.tryParse(val) ?? 0.0,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
            onPressed: () => quitarTamano(index),
          )
        ],
      ),
    );
  }
}