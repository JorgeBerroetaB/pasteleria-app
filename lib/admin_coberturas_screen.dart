import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminCoberturasScreen extends StatefulWidget {
  @override
  _AdminCoberturasScreenState createState() => _AdminCoberturasScreenState();
}

class _AdminCoberturasScreenState extends State<AdminCoberturasScreen> {
  final TextEditingController _nombreController = TextEditingController();
  List<Map<String, dynamic>> preciosExtra = [];

  void _agregarPrecio() {
    setState(() {
      preciosExtra.add({"capacidad": "", "precioExtra": 0.0});
    });
  }

  Future<void> _guardarCobertura() async {
    final url = Uri.parse('TU_URL_DE_RAILWAY/api/coberturas');
    
    final body = {
      "nombre": _nombreController.text,
      "precios": preciosExtra.map((p) => {
        "capacidad": int.parse(p['capacidad']),
        "precioExtra": double.parse(p['precioExtra'].toString())
      }).toList()
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cobertura guardada!")));
      Navigator.pop(context); // Volver atrás
    } else {
      print("Error: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nueva Cobertura Global")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(labelText: "Nombre de la Cobertura (ej: Chantilly)"),
            ),
            Divider(),
            Text("Precios Extra por Capacidad"),
            Expanded(
              child: ListView.builder(
                itemCount: preciosExtra.length,
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(labelText: "Capacidad"),
                          onChanged: (v) => preciosExtra[index]['capacidad'] = v,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(labelText: "Precio Extra \$"),
                          onChanged: (v) => preciosExtra[index]['precioExtra'] = v,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ElevatedButton(onPressed: _agregarPrecio, child: Text("Añadir Regla de Precio")),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _guardarCobertura,
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              child: Text("GUARDAR EN CATÁLOGO"),
            )
          ],
        ),
      ),
    );
  }
}