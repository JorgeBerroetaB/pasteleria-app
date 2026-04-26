import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String nombre = "";
  String rol = "";
  String usuario = "";
  int? idUsuario;
  
  final _passController = TextEditingController();
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nombre = prefs.getString('nombreCompleto') ?? "Usuario";
      rol = prefs.getString('rol') ?? "Sin Rol";
      usuario = prefs.getString('username') ?? "Desconocido";
      // IMPORTANTE: Asegúrate de guardar 'idUsuario' en el Login
      idUsuario = prefs.getInt('usuarioId') ?? prefs.getInt('idUsuario'); 
    });
  }

  Future<void> _actualizarPassword() async {
    if (_passController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La contraseña debe tener al menos 4 caracteres")),
      );
      return;
    }

    if (idUsuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: No se encontró el ID de usuario")),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      // URL corregida al nuevo endpoint de AuthController
      final url = Uri.parse('https://pasteleria-backend-production-24fc.up.railway.app/api/auth/cambiar-password');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usuarioId': idUsuario, 
          'nuevaPassword': _passController.text,
        }),
      );

      if (response.statusCode == 200) {
        _passController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green, 
              content: Text("¡Contraseña actualizada correctamente! 🔐")
            ),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? "Error en el servidor");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent, 
            content: Text("Error: ${e.toString()}")
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), 
      appBar: AppBar( // <--- AQUÍ: Antes decía app_bar, ahora appBar
        title: const Text("Mi Perfil", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFB3E5FC),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 55,
              backgroundColor: Color(0xFFB3E5FC),
              child: Icon(Icons.person, size: 70, color: Color(0xFF81D4FA)),
            ),
            const SizedBox(height: 20),
            Text(nombre, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFB3E5FC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(rol, style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 30),
            
            _buildInfoCard(),
            
            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("  Seguridad", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey)),
            ),
            const SizedBox(height: 10),
            
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    TextField(
                      controller: _passController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Nueva Contraseña",
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF81D4FA)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE1F5FE)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _cargando ? null : _actualizarPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF81D4FA),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _cargando 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("ACTUALIZAR CONTRASEÑA", 
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFF0F8FF),
          child: Icon(Icons.alternate_email, color: Color(0xFF81D4FA)),
        ),
        title: const Text("Nombre de Usuario", style: TextStyle(fontSize: 14, color: Colors.grey)),
        subtitle: Text(usuario, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ),
    );
  }
}