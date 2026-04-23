import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:barcode_widget/barcode_widget.dart'; // ¡Importación nueva!

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
  final abonoCtrl = TextEditingController(); 

  final Color azulPastelFondo = const Color(0xFFF0F8FF); 
  final Color azulPastelPrincipal = const Color(0xFFB3E5FC); 
  final Color azulPastelOscuro = const Color(0xFF81D4FA); 

  List<dynamic> todosLosProductos = [];
  List<dynamic> productosFiltrados = []; 
  String categoriaSeleccionada = "Torta"; 

  Map<String, dynamic>? tortaSeleccionada;
  Map<String, dynamic>? tamanoSeleccionado;
  String bloqueSeleccionado = "MAÑANA"; 
  
  Map<String, dynamic>? coberturaSeleccionada;

  bool cargando = true;
  final String _baseUrl = "https://pasteleria-backend-production-24fc.up.railway.app/api";

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  double _getPrecioFinal() {
    if (tamanoSeleccionado == null) return 0.0;
    double precioBase = double.tryParse(tamanoSeleccionado!['precio'].toString()) ?? 0.0;
    
    double precioExtra = 0.0;
    if (coberturaSeleccionada != null && coberturaSeleccionada!['precios'] != null) {
      List precios = coberturaSeleccionada!['precios'];
      var coincidencia = precios.firstWhere(
        (p) => p['capacidad'].toString() == tamanoSeleccionado!['capacidad'].toString(),
        orElse: () => null,
      );
      if (coincidencia != null) {
        precioExtra = double.tryParse(coincidencia['precioAdicional'].toString()) ?? 0.0;
      }
    }
    
    return precioBase + precioExtra;
  }

  String _obtenerSufijo(String nombre) {
    nombre = nombre.toLowerCase();
    return (nombre.contains("torta") || nombre.contains("pastel")) ? "personas" : "unidades";
  }

  // ¡CAMBIO AQUÍ! Agregamos resetearSeleccion para que no borre los datos al editar
  void _filtrarProductos(String categoria, {bool resetearSeleccion = true}) {
    setState(() {
      categoriaSeleccionada = categoria;
      productosFiltrados = todosLosProductos.where((p) {
        return (p['categoria']?.toString().toLowerCase() ?? "") == categoria.toLowerCase();
      }).toList();
      
      if (resetearSeleccion) {
        tortaSeleccionada = null;
        tamanoSeleccionado = null;
        coberturaSeleccionada = null;
      }
    });
  }

  Future<void> _cargarDatosIniciales() async {
    final url = Uri.parse('$_baseUrl/tortas');
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
            bloqueSeleccionado = p['bloqueHorario'] ?? "MAÑANA"; 
            
            if (p['montoAbonado'] != null) {
              abonoCtrl.text = p['montoAbonado'].toString();
            }

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

              if (tortaSeleccionada!['coberturas'] != null && tortaSeleccionada!['coberturas'].isNotEmpty) {
                 coberturaSeleccionada = tortaSeleccionada!['coberturas'][0];
              }
            }
          }
          
          // ¡CAMBIO AQUÍ! Le decimos que NO resetee la selección porque la acabamos de cargar
          _filtrarProductos(categoriaSeleccionada, resetearSeleccion: false);
          cargando = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando datos: $e");
    }
  }

  // Generador dinámico del código EAN-13 para balanza/POS
  String _generarCodigoDeBalanza() {
    if (tortaSeleccionada == null) return "200000000000";
    
    // Rellenamos el ID con ceros a la izquierda para tener 5 dígitos
    String idPad = tortaSeleccionada!['id'].toString().padLeft(5, '0');
    
    double totalFinal = _getPrecioFinal();
    double abonoIngresado = double.tryParse(abonoCtrl.text) ?? 0.0;
    double loQueFalta = totalFinal - abonoIngresado;
    if (loQueFalta < 0) loQueFalta = 0; // Evitar negativos

    // Rellenamos el precio con ceros a la izquierda para tener 5 dígitos
    String precioPad = loQueFalta.toInt().toString().padLeft(5, '0');
    
    // EAN-13 usa 12 dígitos y calcula el 13avo automáticamente. Prefijo 20.
    return "20$idPad$precioPad"; 
  }

  Future<void> _guardarPedido() async {
    if (nombreClienteCtrl.text.isEmpty || tortaSeleccionada == null || tamanoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, selecciona producto y tamaño"))
      );
      return;
    }

    final isEdit = widget.pedidoParaEditar != null;
    final url = isEdit 
      ? Uri.parse('$_baseUrl/pedidos/${widget.pedidoParaEditar!['id']}')
      : Uri.parse('$_baseUrl/pedidos');

    final detalleLimpio = tamanoSeleccionado!['capacidad'].toString().replaceAll(RegExp(r'[^0-9]'), '');
    
    double total = _getPrecioFinal();
    double abono = double.tryParse(abonoCtrl.text) ?? 0.0;
    double faltaPagar = total - abono;

    String notasFinales = notasCtrl.text;
    
    String registroFinanzas = "[ABONO: \$${abono.toInt()} | FALTA: \$${faltaPagar.toInt()}]";
    if (!notasFinales.contains("ABONO:")) {
       notasFinales = "$registroFinanzas\n$notasFinales";
    }

    if (coberturaSeleccionada != null) {
      String nombreCob = coberturaSeleccionada!['nombre'].toString().toUpperCase();
      if (!notasFinales.contains("[COBERTURA")) {
        notasFinales = "[COBERTURA $nombreCob]\n$notasFinales";
      }
    }

    final datosPedido = {
      "nombreCliente": nombreClienteCtrl.text,
      "telefono": telefonoCtrl.text,
      "fechaEntrega": widget.fechaSeleccionada.toIso8601String().split('T')[0],
      "bloqueHorario": bloqueSeleccionado,
      "estado": isEdit ? widget.pedidoParaEditar!['estado'] : "PENDIENTE",
      "torta": {"id": tortaSeleccionada!['id']},
      "detalleTamano": detalleLimpio,
      "precioTotal": total,        
      "montoAbonado": abono,       
      "notas": notasFinales.trim()
    };

    try {
      final res = isEdit 
        ? await http.put(url, headers: {"Content-Type": "application/json"}, body: json.encode(datosPedido))
        : await http.post(url, headers: {"Content-Type": "application/json"}, body: json.encode(datosPedido));

      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        debugPrint("Error del servidor: ${res.body}");
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.pedidoParaEditar != null;
    
    final List<dynamic> coberturasDisponibles = tortaSeleccionada != null && tortaSeleccionada!['coberturas'] != null 
        ? tortaSeleccionada!['coberturas'] 
        : [];

    return Scaffold(
      backgroundColor: azulPastelFondo,
      appBar: AppBar(
        title: Text(isEdit ? "Editar Pedido ✏️" : "Nuevo Pedido 📝", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: azulPastelPrincipal,
        foregroundColor: Colors.blueGrey[800],
      ),
      body: cargando 
        ? Center(child: CircularProgressIndicator(color: azulPastelOscuro))
        : ListView(
            padding: const EdgeInsets.all(25),
            children: [
              _buildSectionTitle("Información del Cliente"),
              const SizedBox(height: 15),
              _buildTextField(nombreClienteCtrl, "Nombre del Cliente", Icons.person_outline),
              const SizedBox(height: 15),
              _buildTextField(telefonoCtrl, "Teléfono", Icons.phone_android_outlined, keyboardType: TextInputType.phone),
              
              const SizedBox(height: 30),
              _buildSectionTitle("1. Categoría"),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _filtroChip("Torta", Icons.cake_outlined),
                  _filtroChip("Tarta", Icons.pie_chart_outline),
                  _filtroChip("Pastelito", Icons.cookie_outlined),
                ],
              ),

              const SizedBox(height: 30),
              _buildSectionTitle("2. Producto"),
              const SizedBox(height: 10),
              _buildDropdownContainer(
                DropdownButton<Map<String, dynamic>>(
                  isExpanded: true,
                  value: tortaSeleccionada,
                  underline: const SizedBox(),
                  hint: Text("Elegir ${categoriaSeleccionada.toLowerCase()}"),
                  items: productosFiltrados.map((t) => DropdownMenuItem<Map<String, dynamic>>(
                    value: t, child: Text(t['nombre'])
                  )).toList(),
                  onChanged: (val) {
                    setState(() { 
                      tortaSeleccionada = val; 
                      tamanoSeleccionado = null; 
                      coberturaSeleccionada = null; 
                    });
                  },
                ),
              ),

              if (tortaSeleccionada != null) ...[
                const SizedBox(height: 25),
                _buildSectionTitle("3. Tamaño / Cantidad"),
                const SizedBox(height: 10),
                _buildDropdownContainer(
                  DropdownButton<Map<String, dynamic>>(
                    isExpanded: true,
                    value: tamanoSeleccionado,
                    underline: const SizedBox(),
                    hint: const Text("Elegir opción"),
                    items: (tortaSeleccionada!['tamanos'] as List).map((tam) {
                      String num = tam['capacidad'].toString().replaceAll(RegExp(r'[^0-9]'), '');
                      String sufijo = _obtenerSufijo(tortaSeleccionada!['nombre']);
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: tam, child: Text("$num $sufijo - \$${tam['precio']}")
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => tamanoSeleccionado = val),
                  ),
                ),
              ],

              if (coberturasDisponibles.isNotEmpty && tamanoSeleccionado != null) ...[
                const SizedBox(height: 25),
                _buildSectionTitle("4. Tipo de Cobertura"),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 15,
                  runSpacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text("Base / Normal"),
                      selected: coberturaSeleccionada == null,
                      onSelected: (s) => setState(() => coberturaSeleccionada = null),
                      selectedColor: azulPastelPrincipal,
                    ),
                    ...coberturasDisponibles.map((cob) {
                      bool isSelected = coberturaSeleccionada != null && coberturaSeleccionada!['id'] == cob['id'];
                      return ChoiceChip(
                        label: Text(cob['nombre']),
                        selected: isSelected,
                        onSelected: (s) => setState(() => coberturaSeleccionada = s ? cob : null),
                        selectedColor: azulPastelPrincipal,
                      );
                    }).toList(),
                  ],
                ),
              ],

              const SizedBox(height: 30),
              _buildSectionTitle("5. Horario de Entrega"),
              const SizedBox(height: 10),
              Row(
                children: [
                  _choiceChipHorario("🌅 Mañana", "MAÑANA"), 
                  const SizedBox(width: 15),
                  _choiceChipHorario("☀️ Tarde", "TARDE"),
                ],
              ),

              const SizedBox(height: 30),
              _buildSectionTitle("6. Abono / Pago Anticipado"),
              const SizedBox(height: 10),
              _buildTextField(
                abonoCtrl, 
                "Monto abonado (Dejar vacío si no hay)", 
                Icons.payments_outlined, 
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  setState(() {});
                }
              ),

              const SizedBox(height: 25),
              _buildTextField(notasCtrl, "Notas u observaciones", Icons.edit_note, maxLines: 2),
              
              const SizedBox(height: 30),
              if (tamanoSeleccionado != null) ...[
                Builder(
                  builder: (context) {
                    double totalFinal = _getPrecioFinal();
                    double abonoIngresado = double.tryParse(abonoCtrl.text) ?? 0.0;
                    double loQueFalta = totalFinal - abonoIngresado;

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[800],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("TOTAL:", style: TextStyle(color: Colors.white70, fontSize: 16)),
                              Text("\$${totalFinal.toInt()}", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("ABONO:", style: TextStyle(color: Colors.greenAccent, fontSize: 16)),
                              Text("- \$${abonoIngresado.toInt()}", style: const TextStyle(color: Colors.greenAccent, fontSize: 16)),
                            ],
                          ),
                          const Divider(color: Colors.white24, height: 20, thickness: 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("FALTA PAGAR:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              Text("\$${loQueFalta.toInt()}", 
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                ),
                
                // ¡AQUÍ ESTÁ EL NUEVO CÓDIGO DE BARRAS! (Solo visible en edición)
                if (isEdit) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: azulPastelPrincipal, width: 2),
                    ),
                    child: Column(
                      children: [
                        const Text("ESCANEAR EN CAJA", 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.5)
                        ),
                        const SizedBox(height: 15),
                        BarcodeWidget(
                          barcode: Barcode.ean13(), // Usamos EAN-13 para las balanzas
                          data: _generarCodigoDeBalanza(),
                          width: double.infinity,
                          height: 80,
                          drawText: true,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                        ),
                        const SizedBox(height: 10),
                        const Text("Monto cobrado por el POS: Lo que falta pagar", 
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)
                        )
                      ],
                    ),
                  ),
                ]
              ],

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _guardarPedido,
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulPastelOscuro, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                child: Text(isEdit ? "GUARDAR CAMBIOS" : "CONFIRMAR PEDIDO", 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
    );
  }

  Widget _buildDropdownContainer(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: azulPastelPrincipal),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey[800]));
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text, int maxLines = 1, void Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: azulPastelOscuro),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: azulPastelPrincipal.withOpacity(0.5))),
      ),
    );
  }

  Widget _choiceChipHorario(String label, String value) {
    bool selected = bloqueSeleccionado == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (s) => setState(() => bloqueSeleccionado = value),
      selectedColor: azulPastelPrincipal,
    );
  }

  Widget _filtroChip(String label, IconData icono) {
    bool seleccionada = categoriaSeleccionada == label;
    return ChoiceChip(
      avatar: Icon(icono, size: 18),
      label: Text(label),
      selected: seleccionada,
      onSelected: (bool s) { if (s) _filtrarProductos(label); },
      selectedColor: azulPastelPrincipal,
    );
  }
}