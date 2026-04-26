import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleLogin() async {
    if (_userController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, llena todos los campos")),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final usuario = await _authService.login(
      _userController.text, 
      _passController.text
    );

    setState(() => _isLoading = false);

    if (usuario != null) {
      final prefs = await SharedPreferences.getInstance();
      
      // CORRECCIÓN AQUÍ: Usando acceso por propiedades de objeto
      await prefs.setInt('idUsuario', usuario.id); 
      await prefs.setString('nombreCompleto', usuario.nombreCompleto ?? "Empleado");
      await prefs.setString('username', usuario.username); 
      await prefs.setString('rol', usuario.rol ?? "USER"); 

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home'); 
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuario o contraseña incorrectos")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color azulPrincipal = Color(0xFFB3E5FC);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cake_rounded, size: 100, color: Color(0xFF81D4FA)),
                const SizedBox(height: 10),
                const Text(
                  "Dulce Día",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF37474F)),
                ),
                const Text("Gestión de Pastelería", style: TextStyle(color: Colors.blueGrey)),
                const SizedBox(height: 40),
                TextField(
                  controller: _userController,
                  decoration: InputDecoration(
                    labelText: "Usuario",
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    prefixIcon: const Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 30),
                _isLoading 
                  ? const CircularProgressIndicator(color: Color(0xFF81D4FA))
                  : ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azulPrincipal,
                        foregroundColor: Colors.blueGrey[900],
                        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 2,
                      ),
                      child: const Text("ENTRAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}