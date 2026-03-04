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
  
  File? _imagen;
  final ImagePicker _picker = ImagePicker();

  // Colores Pastel personalizados
  final Color azulPastelFondo = const Color(0xFFF0F8FF); 
  final Color azulPastelPrincipal = const Color(0xFFB3E5FC); 
  final Color azulPastelOscuro = const Color(0xFF81D4FA); 

  String categoriaSeleccionada = "Torta";
  final List<String> categorias = ["Torta", "Tarta", "Pastelito"];

  // Controla si la torta acepta Merengue o Crema
  bool coberturaVariada = false;

  List<Map<String, dynamic>> tamanos = [];
  bool guardando = false;

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
        const SnackBar(content: Text("Por favor, ingresa al menos el nombre del producto")),
      );
      return;
    }
    
    setState(() => guardando = true);

    try {
      final url = Uri.parse('https://pasteleria-backend-production-24fc.up.railway.app/api/tortas');
      var request = http.MultipartRequest('POST', url);

      request.fields['nombre'] = nombreCtrl.text;
      request.fields['descripcion'] = descCtrl.text;
      request.fields['categoria'] = categoriaSeleccionada;
      request.fields['tamanosJson'] = json.encode(tamanos);
      
      // Enviamos el valor del Switch al backend
      request.fields['coberturaVariada'] = coberturaVariada.toString();

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
        if (mounted) Navigator.pop(context, true);
      } else {
        debugPrint("Error del servidor: ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al guardar: ${response.statusCode}")),
          );
        }
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
          Text("Selecciona el Tipo de Producto:", 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
          DropdownButton<String>(
            value: categoriaSeleccionada,
            isExpanded: true,
            dropdownColor: azulPastelFondo,
            items: categorias.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                categoriaSeleccionada = newValue!;
                if (categoriaSeleccionada != "Torta") coberturaVariada = false;
              });
            },
          ),
          const SizedBox(height: 20),
          
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
          
          // --- WIDGET: REGLA DE COBERTURA (Solo para Tortas) ---
          if (categoriaSeleccionada == "Torta") ...[
            const SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
              ),
              child: SwitchListTile(
                title: const Text("Doble Cobertura", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Permite elegir entre Merengue o Crema Chantilly"),
                value: coberturaVariada,
                activeColor: azulPastelOscuro,
                onChanged: (bool value) {
                  setState(() => coberturaVariada = value);
                },
                secondary: Icon(Icons.layers_outlined, color: azulPastelOscuro),
              ),
            ),
          ],

          const SizedBox(height: 20),
          Text("Foto del Producto (Opcional):", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
          const SizedBox(height: 10),
          _buildFotoArea(),
          
          const SizedBox(height: 30),
          Text(
            categoriaSeleccionada == "Pastelito" ? "💰 Precios por Cantidad" : "📏 Tamaños y Precios", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])
          ),
          const Divider(),

          // Lista dinámica de tamaños
          ...tamanos.asMap().entries.map((entry) => _buildTamanoItem(entry.key)),

          TextButton.icon(
            onPressed: agregarCampoTamano,
            icon: Icon(Icons.add_circle_outline, color: azulPastelOscuro),
            label: Text(
              categoriaSeleccionada == "Pastelito" ? "Agregar Variedad" : "Agregar Tamaño",
              style: TextStyle(color: azulPastelOscuro, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: guardando ? null : guardarTorta,
            style: ElevatedButton.styleFrom(
              backgroundColor: azulPastelPrincipal,
              foregroundColor: Colors.blueGrey[800],
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            child: guardando 
              ? CircularProgressIndicator(color: azulPastelOscuro) 
              : const Text("GUARDAR EN CATÁLOGO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // --- MÉTODOS DE AYUDA PARA DISEÑO ---

  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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
          border: Border.all(color: azulPastelPrincipal),
        ),
        child: _imagen == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 60, color: azulPastelOscuro),
                  Text("Toca para abrir la cámara", style: TextStyle(color: azulPastelOscuro)),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(_imagen!, fit: BoxFit.cover, width: double.infinity),
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
            flex: 1, 
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: _inputStyle(categoriaSeleccionada == "Pastelito" ? "Cant." : "Cap."),
              onChanged: (val) => tamanos[index]["capacidad"] = val,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2, 
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: _inputStyle("Precio \$"),
              onChanged: (val) => tamanos[index]["precio"] = double.tryParse(val) ?? 0.0,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => quitarTamano(index),
          )
        ],
      ),
    );
  }
}