import 'package:flutter/material.dart';
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
    setState(() => _isLoading = true);
    
    final usuario = await _authService.login(
      _userController.text, 
      _passController.text
    );

    setState(() => _isLoading = false);

    if (usuario != null) {
      // Si el login es éxito, vamos a la pantalla principal
      // Reemplaza 'HomeScreen' por el nombre de tu pantalla de inicio
      Navigator.pushReplacementNamed(context, '/home'); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Usuario o contraseña incorrectos")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // Fondo azul clarito
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cake, size: 100, color: Colors.blue[300]),
                SizedBox(height: 20),
                Text(
                  "Pastelería Login",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                ),
                SizedBox(height: 40),
                TextField(
                  controller: _userController,
                  decoration: InputDecoration(
                    labelText: "Usuario",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _passController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                SizedBox(height: 30),
                _isLoading 
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[300],
                        padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text("Entrar", style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}