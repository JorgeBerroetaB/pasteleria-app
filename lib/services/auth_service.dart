import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';

class AuthService {
  // Asegúrate de que esta URL sea la de Railway
  final String baseUrl = "https://pasteleria-backend-production-24fc.up.railway.app/api";

  Future<Usuario?> login(String username, String password) async {
    try {
      final response = await http.post(
        // NOTA: Agregué /auth/login para coincidir con la ruta estándar del backend
        Uri.parse('$baseUrl/auth/login'), 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      print("Status Code: ${response.statusCode}"); // Para debug
      print("Response Body: ${response.body}");     // Para debug

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        Usuario usuario = Usuario.fromJson(userData);
        
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('usuarioId', usuario.id); // ¡Importante guardar el ID!
        await prefs.setString('username', usuario.username);
        await prefs.setString('nombreEmpleado', usuario.nombreCompleto);
        
        return usuario;
      } else {
        return null;
      }
    } catch (e) {
      print("Error en la conexión: $e");
      return null;
    }
  }Future<bool> registrar(String nombre, String username, String password) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/registrar'), // Ajusta según tu ruta
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "nombreCompleto": nombre,
      "username": username,
      "password": password,
      "rol": "USER",
      "activo": true
    }),
  );

  return response.statusCode == 200;
}
}