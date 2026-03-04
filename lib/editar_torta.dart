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
  
  // Colores Pastel definidos
  final Color azulPastelFondo = const Color(0xFFF0F8FF);
  final Color azulPastelPrincipal = const Color(0xFFB3E5FC);
  final Color azulPastelOscuro = const Color(0xFF81D4FA);

  File? _nuevaImagen;
  final ImagePicker _picker = ImagePicker();
  
  late String categoriaSeleccionada;
  final List<String> categorias = ["Torta", "Tarta", "Pastelito"];
  
  List<Map<String, dynamic>> tamanos = [];
  bool guardando = false;

  final String _baseUrl = "https://pasteleria-backend-production-24fc.up.railway.app/api/tortas";

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController(text: widget.torta['nombre']);
    descCtrl = TextEditingController(text: widget.torta['descripcion']);
    categoriaSeleccionada = widget.torta['categoria'] ?? "Torta";
    
    if (widget.torta['tamanos'] != null) {
      for (var t in widget.torta['tamanos']) {
        tamanos.add({
          "id": t['id'], 
          "capacidad": t['capacidad'],
          "precio": t['precio']
        });
      }
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

  Future<void> actualizarTorta() async {
    setState(() => guardando = true);

    try {
      final url = Uri.parse('$_baseUrl/${widget.torta['id']}');
      var request = http.MultipartRequest('PUT', url);

      request.fields['nombre'] = nombreCtrl.text;
      request.fields['descripcion'] = descCtrl.text;
      request.fields['categoria'] = categoriaSeleccionada;
      request.fields['tamanosJson'] = json.encode(tamanos);

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
        if (mounted) Navigator.pop(context, true);
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
        padding: const EdgeInsets.all(25),
        children: [
          _buildLabel("Datos Generales"),
          const SizedBox(height: 10),
          _buildTextField(nombreCtrl, "Nombre del producto", Icons.shopping_basket_outlined),
          const SizedBox(height: 15),
          _buildTextField(descCtrl, "Descripción", Icons.description_outlined, maxLines: 2),
          
          const SizedBox(height: 25),
          _buildLabel("Foto del Producto"),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _tomarFoto,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: azulPastelPrincipal),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Stack(
                children: [
                  Center(
                    child: _nuevaImagen != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(_nuevaImagen!, fit: BoxFit.cover, width: double.infinity),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            widget.torta['imagenUrl'] ?? "",
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (c, e, s) => Icon(Icons.camera_alt_outlined, size: 50, color: azulPastelOscuro),
                          ),
                        ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: CircleAvatar(
                      backgroundColor: azulPastelPrincipal,
                      child: const Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),
          _buildLabel("📏 Tamaños y Precios"),
          const Divider(height: 30),

          ...tamanos.asMap().entries.map((entry) {
            int i = entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      null, 
                      "Capacidad", 
                      Icons.people_outline, 
                      initialText: tamanos[i]['capacidad'],
                      onChanged: (val) => tamanos[i]['capacidad'] = val,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: _buildTextField(
                      null, 
                      "Precio", 
                      Icons.attach_money, 
                      initialText: tamanos[i]['precio'].toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => tamanos[i]['precio'] = double.tryParse(val) ?? 0.0,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: guardando ? null : actualizarTorta,
            style: ElevatedButton.styleFrom(
              backgroundColor: azulPastelPrincipal,
              foregroundColor: Colors.blueGrey[800],
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: azulPastelOscuro.withOpacity(0.5))
              ),
            ),
            child: guardando 
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.blueGrey[800], strokeWidth: 2)) 
                : const Text("GUARDAR CAMBIOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
    );
  }

  Widget _buildTextField(
    TextEditingController? controller, 
    String label, 
    IconData icon, 
    {TextInputType keyboardType = TextInputType.text, 
    int maxLines = 1,
    String? initialText,
    Function(String)? onChanged}
  ) {
    return TextField(
      controller: controller ?? (initialText != null ? TextEditingController(text: initialText) : null),
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: azulPastelOscuro, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: azulPastelPrincipal.withOpacity(0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: azulPastelOscuro, width: 2)),
      ),
    );
  }
}