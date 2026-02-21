import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
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
  
  File? _nuevaImagen; // Para la nueva foto si el usuario la cambia
  final ImagePicker _picker = ImagePicker();
  
  List<Map<String, dynamic>> tamanos = [];
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController(text: widget.torta['nombre']);
    descCtrl = TextEditingController(text: widget.torta['descripcion']);
    
    if (widget.torta['tamanos'] != null) {
      for (var t in widget.torta['tamanos']) {
        tamanos.add({
          "id": t['id'],
          "capacidad": t['capacidad'],
          "precio": t['precio'].toDouble()
        });
      }
    }
  }

  Future<void> _cambiarFoto() async {
    final XFile? foto = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (foto != null) setState(() => _nuevaImagen = File(foto.path));
  }

  Future<void> guardarCambios() async {
    setState(() => guardando = true);

    try {
      final url = Uri.parse('http://192.168.1.86:8080/api/tortas/${widget.torta['id']}');
      var request = http.MultipartRequest('PUT', url);

      request.fields['nombre'] = nombreCtrl.text;
      request.fields['descripcion'] = descCtrl.text;
      request.fields['categoria'] = widget.torta['categoria'] ?? "Torta";
      request.fields['tamanosJson'] = json.encode(tamanos);

      if (_nuevaImagen != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file', 
          _nuevaImagen!.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      var streamedResponse = await request.send();
      if (streamedResponse.statusCode == 200) {
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // URL de la imagen que ya existe en el servidor
    String urlImagenActual = "http://192.168.1.86:8080/uploads/${widget.torta['imagenUrl']}";

    return Scaffold(
      appBar: AppBar(title: const Text("Editar Torta ✏️"), backgroundColor: Colors.orange),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Foto de la Torta:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _cambiarFoto,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange),
              ),
              child: _nuevaImagen != null
                  ? Image.file(_nuevaImagen!, fit: BoxFit.cover)
                  : Image.network(urlImagenActual, fit: BoxFit.cover, 
                      errorBuilder: (c, e, s) => const Icon(Icons.add_a_photo, size: 50)),
            ),
          ),
          const SizedBox(height: 20),
          TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre")),
          const SizedBox(height: 10),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Descripción")),
          
          const SizedBox(height: 30),
          const Text("📏 Editar Tamaños y Precios", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),

          ...tamanos.asMap().entries.map((entry) {
            int index = entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: tamanos[index]["capacidad"],
                      decoration: const InputDecoration(labelText: "Capacidad"),
                      onChanged: (val) => tamanos[index]["capacidad"] = val,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: tamanos[index]["precio"].toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Precio"),
                      onChanged: (val) => tamanos[index]["precio"] = double.tryParse(val) ?? 0.0,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => tamanos.removeAt(index)),
                  )
                ],
              ),
            );
          }),

          TextButton.icon(
            onPressed: () => setState(() => tamanos.add({"capacidad": "", "precio": 0.0})),
            icon: const Icon(Icons.add),
            label: const Text("Agregar nuevo tamaño"),
          ),

          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: guardando ? null : guardarCambios,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: guardando ? const CircularProgressIndicator(color: Colors.white) : const Text("GUARDAR CAMBIOS"),
          )
        ],
      ),
    );
  }
}