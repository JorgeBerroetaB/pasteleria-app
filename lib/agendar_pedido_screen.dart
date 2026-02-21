import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AgendarPedidoScreen extends StatefulWidget {
  final DateTime fechaSeleccionada;
  final Map<String, dynamic>? pedidoParaEditar;

  const AgendarPedidoScreen({
    super.key, 
    required this.fechaSeleccionada, 
    this.pedidoParaEditar
  });

  @override
  State<AgendarPedidoScreen> createState() => _AgendarPedidoScreenState();
}

class _AgendarPedidoScreenState extends State<AgendarPedidoScreen> {
  final nombreClienteCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final notasCtrl = TextEditingController();

  List<dynamic> todosLosProductos = [];
  List<dynamic> productosFiltrados = []; // Nueva lista para el filtro
  String categoriaSeleccionada = "Torta"; // Categoría por defecto

  Map<String, dynamic>? tortaSeleccionada;
  Map<String, dynamic>? tamanoSeleccionado;
  String bloqueSeleccionado = "TARDE";
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  String _obtenerSufijo(String nombre) {
    nombre = nombre.toLowerCase();
    return (nombre.contains("torta") || nombre.contains("pastel")) ? "personas" : "unidades";
  }

  // --- NUEVA FUNCIÓN DE FILTRADO ---
  void _filtrarProductos(String categoria) {
    setState(() {
      categoriaSeleccionada = categoria;
      productosFiltrados = todosLosProductos.where((p) {
        return (p['categoria']?.toString().toLowerCase() ?? "") == categoria.toLowerCase();
      }).toList();
      
      // Si cambiamos de categoría, reseteamos la torta seleccionada 
      // para evitar que el dropdown intente mostrar un ID que no está en la lista filtrada
      tortaSeleccionada = null;
      tamanoSeleccionado = null;
    });
  }

  Future<void> _cargarDatosIniciales() async {
    final url = Uri.parse('http://192.168.1.86:8080/api/tortas');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        setState(() {
          todosLosProductos = json.decode(res.body);
          
          if (widget.pedidoParaEditar != null) {
            final p = widget.pedidoParaEditar!;
            nombreClienteCtrl.text = p['nombreCliente'] ?? "";
            telefonoCtrl.text = p['telefono'] ?? "";
            notasCtrl.text = p['notas'] ?? "";
            bloqueSeleccionado = p['bloqueHorario'] ?? "TARDE";
            
            // Si editamos, detectamos la categoría del producto original
            tortaSeleccionada = todosLosProductos.firstWhere(
              (t) => t['id'] == p['torta']['id'],
              orElse: () => null,
            );

            if (tortaSeleccionada != null) {
              categoriaSeleccionada = tortaSeleccionada!['categoria'] ?? "Torta";
              
              List tamanos = tortaSeleccionada!['tamanos'];
              String numeroBd = p['detalleTamano'].toString().replaceAll(RegExp(r'[^0-9]'), '');
              
              tamanoSeleccionado = tamanos.firstWhere(
                (tam) => tam['capacidad'].toString().replaceAll(RegExp(r'[^0-9]'), '') == numeroBd,
                orElse: () => null,
              );
            }
          }
          
          // Aplicamos el filtro inicial
          _filtrarProductos(categoriaSeleccionada);
          cargando = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando datos: $e");
    }
  }

  Future<void> _guardarPedido() async {
    if (nombreClienteCtrl.text.isEmpty || tortaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Faltan datos")));
      return;
    }

    final isEdit = widget.pedidoParaEditar != null;
    final url = isEdit 
      ? Uri.parse('http://192.168.1.86:8080/api/pedidos/${widget.pedidoParaEditar!['id']}')
      : Uri.parse('http://192.168.1.86:8080/api/pedidos');

    final detalleRaw = tamanoSeleccionado != null 
        ? tamanoSeleccionado!['capacidad'] 
        : widget.pedidoParaEditar?['detalleTamano'];
    
    final detalleLimpio = detalleRaw.toString().replaceAll(RegExp(r'[^0-9]'), '');

    final datosPedido = {
      "nombreCliente": nombreClienteCtrl.text,
      "telefono": telefonoCtrl.text,
      "fechaEntrega": widget.fechaSeleccionada.toIso8601String().split('T')[0],
      "bloqueHorario": bloqueSeleccionado,
      "estado": isEdit ? widget.pedidoParaEditar!['estado'] : "PENDIENTE",
      "torta": {"id": tortaSeleccionada!['id']},
      "detalleTamano": detalleLimpio,
      "precioFinal": tamanoSeleccionado != null ? tamanoSeleccionado!['precio'] : widget.pedidoParaEditar?['precioFinal'],
      "notas": notasCtrl.text
    };

    try {
      final res = isEdit 
        ? await http.put(url, headers: {"Content-Type": "application/json"}, body: json.encode(datosPedido))
        : await http.post(url, headers: {"Content-Type": "application/json"}, body: json.encode(datosPedido));

      if (res.statusCode == 200 || res.statusCode == 201) Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.pedidoParaEditar != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Editar Pedido ✏️" : "Nuevo Pedido 📝"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: cargando 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(controller: nombreClienteCtrl, decoration: const InputDecoration(labelText: "Nombre del Cliente")),
              TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: "Teléfono"), keyboardType: TextInputType.phone),
              const SizedBox(height: 25),
              
              // --- SECCIÓN DE FILTRO POR CATEGORÍA ---
              const Text("1. Seleccione Categoría:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _filtroChip("Torta", Icons.cake),
                  _filtroChip("Tarta", Icons.pie_chart),
                  _filtroChip("Pastelito", Icons.cookie),
                ],
              ),

              const SizedBox(height: 20),
              const Text("2. Producto:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<Map<String, dynamic>>(
                isExpanded: true,
                value: tortaSeleccionada,
                hint: Text("Elegir ${categoriaSeleccionada.toLowerCase()}"),
                items: productosFiltrados.map((t) => DropdownMenuItem<Map<String, dynamic>>(
                  value: t, 
                  child: Text(t['nombre'])
                )).toList(),
                onChanged: (val) => setState(() { tortaSeleccionada = val; tamanoSeleccionado = null; }),
              ),

              if (tortaSeleccionada != null) ...[
                const SizedBox(height: 20),
                const Text("3. Tamaño / Cantidad:", style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<Map<String, dynamic>>(
                  isExpanded: true,
                  value: tamanoSeleccionado,
                  hint: const Text("Elegir opción"),
                  items: (tortaSeleccionada!['tamanos'] as List).map((tam) {
                    String num = tam['capacidad'].toString().replaceAll(RegExp(r'[^0-9]'), '');
                    String sufijo = _obtenerSufijo(tortaSeleccionada!['nombre']);
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: tam, 
                      child: Text("$num $sufijo - \$${tam['precio']}")
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => tamanoSeleccionado = val),
                ),
              ],

              const SizedBox(height: 25),
              const Text("4. Horario de Entrega:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text("☀️ Tarde"), 
                    selected: bloqueSeleccionado == "TARDE", 
                    onSelected: (s) => setState(() => bloqueSeleccionado = "TARDE"),
                    selectedColor: Colors.orange[200],
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text("🌙 Noche"), 
                    selected: bloqueSeleccionado == "NOCHE", 
                    onSelected: (s) => setState(() => bloqueSeleccionado = "NOCHE"),
                    selectedColor: Colors.orange[200],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: notasCtrl, decoration: const InputDecoration(labelText: "Notas / Observaciones")),
              const SizedBox(height: 35),
              ElevatedButton(
                onPressed: _guardarPedido,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: Text(isEdit ? "GUARDAR CAMBIOS" : "CONFIRMAR PEDIDO", style: const TextStyle(fontSize: 16)),
              )
            ],
          ),
    );
  }

  // Widget pequeño para los botones de categoría
  Widget _filtroChip(String label, IconData icono) {
    bool seleccionada = categoriaSeleccionada == label;
    return ChoiceChip(
      avatar: Icon(icono, size: 18, color: seleccionada ? Colors.white : Colors.orange),
      label: Text(label),
      selected: seleccionada,
      onSelected: (bool selected) {
        if (selected) _filtrarProductos(label);
      },
      selectedColor: Colors.orange,
      labelStyle: TextStyle(color: seleccionada ? Colors.white : Colors.black),
    );
  }
}