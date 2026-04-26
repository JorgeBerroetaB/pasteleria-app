import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegistroEmpleadoScreen extends StatefulWidget {
  @override
  _RegistroEmpleadoScreenState createState() => _RegistroEmpleadoScreenState();
}

class _RegistroEmpleadoScreenState extends State<RegistroEmpleadoScreen> {
  final _nombreController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _authService = AuthService();
  bool _isLoader = false; // Para mostrar que está cargando

  void _crearCuenta() async {
    if (_nombreController.text.isEmpty || _userController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Por favor, llena todos los campos")));
      return;
    }

    setState(() => _isLoader = true);
    
    final exito = await _authService.registrar(
      _nombreController.text,
      _userController.text,
      _passController.text,
    );

    setState(() => _isLoader = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("¡Empleado creado con éxito!")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al crear cuenta. Revisa si el usuario ya existe.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AQUÍ ESTABA EL ERROR: Cambiado de app_bar a appBar
      appBar: AppBar(
        title: Text("Registrar Nuevo Empleado"),
        backgroundColor: Colors.blue[300],
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView( // Para que no de error si el teclado tapa los campos
          child: Column(
            children: [
              TextField(
                controller: _nombreController, 
                decoration: InputDecoration(labelText: "Nombre Completo", icon: Icon(Icons.person))
              ),
              TextField(
                controller: _userController, 
                decoration: InputDecoration(labelText: "Usuario (Login)", icon: Icon(Icons.account_circle))
              ),
              TextField(
                controller: _passController, 
                obscureText: true, // Para que la contraseña no se vea
                decoration: InputDecoration(labelText: "Contraseña", icon: Icon(Icons.lock))
              ),
              SizedBox(height: 30),
              _isLoader 
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _crearCuenta, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[300],
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    child: Text("Guardar Empleado", style: TextStyle(color: Colors.white))
                  )
            ],
          ),
        ),
      ),
    );
  }
}