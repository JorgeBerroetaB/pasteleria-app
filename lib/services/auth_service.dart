import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';

class AuthService {
  // Cambia esta URL por tu IP local o la de Railway después
  final String baseUrl = "https://pasteleria-backend-production-24fc.up.railway.app/api";

  Future<Usuario?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      Usuario usuario = Usuario.fromJson(userData);
      
      // Guardamos el nombre para usarlo en los pedidos
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', usuario.username);
      await prefs.setString('nombreEmpleado', usuario.nombreCompleto);
      
      return usuario;
    }
    return null;
  }
}