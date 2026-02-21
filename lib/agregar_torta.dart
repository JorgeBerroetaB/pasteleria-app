import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Para la cámara
import 'package:http_parser/http_parser.dart'; // Para el tipo de imagen
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
  
  // Variables para la imagen
  File? _imagen;
  final ImagePicker _picker = ImagePicker();

  String categoriaSeleccionada = "Torta";
  final List<String> categorias = ["Torta", "Tarta", "Pastelito"];

  List<Map<String, dynamic>> tamanos = [];
  bool guardando = false;

  // Función para capturar foto con la cámara
  Future<void> _tomarFoto() async {
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50, // Reduce el peso para que suba más rápido
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
    if (nombreCtrl.text.isEmpty || _imagen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, ponle nombre y una foto")),
      );
      return;
    }
    
    setState(() => guardando = true);

    try {
      final url = Uri.parse('http://192.168.1.86:8080/api/tortas');
      
      // CAMBIO IMPORTANTE: Usamos MultipartRequest para enviar el archivo
      var request = http.MultipartRequest('POST', url);

      // Campos de texto (Coinciden con @RequestParam en Java)
      request.fields['nombre'] = nombreCtrl.text;
      request.fields['descripcion'] = descCtrl.text;
      request.fields['categoria'] = categoriaSeleccionada;
      
      // Los tamaños deben ir como JSON string porque Multipart solo envía Strings o Files
      request.fields['tamanosJson'] = json.encode(tamanos);

      // Adjuntar la foto
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // Debe coincidir con @RequestParam("file") en Java
          _imagen!.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) Navigator.pop(context, true);
      } else {
        debugPrint("Error del servidor: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error al guardar: $e");
    } finally {
      setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nuevo Producto 🎂")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Selecciona el Tipo de Producto:", 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          DropdownButton<String>(
            value: categoriaSeleccionada,
            isExpanded: true,
            items: categorias.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                categoriaSeleccionada = newValue!;
              });
            },
          ),
          const SizedBox(height: 20),
          
          TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre")),
          const SizedBox(height: 10),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Descripción")),
          const SizedBox(height: 20),

          // --- SECCIÓN DE LA FOTO ---
          const Text("Foto del Producto:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _tomarFoto,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: _imagen == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 50, color: Colors.orange),
                        Text("Toca para tomar foto", style: TextStyle(color: Colors.orange)),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(_imagen!, fit: BoxFit.cover),
                    ),
            ),
          ),
          // --------------------------

          const SizedBox(height: 30),
          Text(
            categoriaSeleccionada == "Pastelito" 
              ? "💰 Precios por Cantidad" 
              : "📏 Tamaños y Precios", 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const Divider(),

          ...tamanos.asMap().entries.map((entry) {
            int index = entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: categoriaSeleccionada == "Pastelito" 
                          ? "Ej: Docena, Unidad..." 
                          : "Capacidad (Ej: 15 pers)"
                      ),
                      onChanged: (val) => tamanos[index]["capacidad"] = val,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Precio (\$)"),
                      onChanged: (val) => tamanos[index]["precio"] = double.tryParse(val) ?? 0.0,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => quitarTamano(index),
                  )
                ],
              ),
            );
          }),

          TextButton.icon(
            onPressed: agregarCampoTamano,
            icon: const Icon(Icons.add),
            label: Text(categoriaSeleccionada == "Pastelito" ? "Agregar Variedad" : "Agregar Tamaño"),
          ),

          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: guardando ? null : guardarTorta,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15)
            ),
            child: guardando 
              ? const CircularProgressIndicator(color: Colors.white) 
              : Text("GUARDAR $categoriaSeleccionada".toUpperCase()),
          )
        ],
      ),
    );
  }
}