import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // --- LÓGICA DE PRECIOS ---
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

  // --- GENERADOR DE CÓDIGO EAN-13 (NUEVA VERSIÓN DOBLE) ---
  String _generarCodigoParaMonto(double monto) {
    if (tortaSeleccionada == null) return "200000000000";
    
    String prefijo = "20";
    var valorCodigo = tortaSeleccionada!['codigoBarrasBase'] 
                   ?? tortaSeleccionada!['codigo_barras_base'] 
                   ?? tortaSeleccionada!['id'] 
                   ?? 0;
                   
    String idPad = valorCodigo.toString().padLeft(5, '0');
    String montoPad = monto.toInt().toString().padLeft(5, '0');
    
    return "$prefijo$idPad$montoPad"; 
  }

  // --- MÉTODOS DE DATOS ---
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
    try {
      final res = await http.get(Uri.parse('$_baseUrl/tortas'));
      if (res.statusCode == 200) {
        setState(() {
          todosLosProductos = json.decode(res.body);
          
          if (widget.pedidoParaEditar != null) {
            final p = widget.pedidoParaEditar!;
            nombreClienteCtrl.text = p['nombreCliente'] ?? "";
            telefonoCtrl.text = p['telefono'] ?? "";
            
            String notasOriginales = p['notas'] ?? "";
            notasCtrl.text = notasOriginales.contains(']') ? notasOriginales.split(']').last.trim() : notasOriginales;

            bloqueSeleccionado = p['bloqueHorario'] ?? "MAÑANA"; 
            if (p['montoAbonado'] != null) abonoCtrl.text = p['montoAbonado'].toInt().toString();

            tortaSeleccionada = todosLosProductos.firstWhere(
              (t) => t['id'] == p['torta']['id'],
              orElse: () => null,
            );

            if (tortaSeleccionada != null) {
              categoriaSeleccionada = tortaSeleccionada!['categoria'] ?? "Torta";
              List tamanos = tortaSeleccionada!['tamanos'];
              String capacidadBd = p['detalleTamano'].toString();
              tamanoSeleccionado = tamanos.firstWhere(
                (tam) => tam['capacidad'].toString() == capacidadBd,
                orElse: () => null,
              );
            }
          }
          _filtrarProductos(categoriaSeleccionada, resetearSeleccion: false);
          cargando = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando datos: $e");
    }
  }

  Future<void> _guardarPedido() async {
    if (nombreClienteCtrl.text.isEmpty || tortaSeleccionada == null || tamanoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Completa Cliente, Producto y Tamaño")));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final int? usuarioId = prefs.getInt('usuarioId') ?? prefs.getInt('idUsuario'); 

    final isEdit = widget.pedidoParaEditar != null;
    final url = Uri.parse(isEdit ? '$_baseUrl/pedidos/${widget.pedidoParaEditar!['id']}' : '$_baseUrl/pedidos');

    double total = _getPrecioFinal();
    double abono = double.tryParse(abonoCtrl.text) ?? 0.0;
    
    String cobInfo = coberturaSeleccionada != null ? "[${coberturaSeleccionada!['nombre'].toUpperCase()}] " : "";
    String notasFinales = "${cobInfo}[ABONO: \$${abono.toInt()}]\n${notasCtrl.text}".trim();

    final datosPedido = {
      "nombreCliente": nombreClienteCtrl.text,
      "telefono": telefonoCtrl.text,
      "fechaEntrega": widget.fechaSeleccionada.toIso8601String().split('T')[0],
      "bloqueHorario": bloqueSeleccionado,
      "estado": isEdit ? widget.pedidoParaEditar!['estado'] : "PENDIENTE",
      "torta": {"id": tortaSeleccionada!['id']},
      "empleado": usuarioId != null ? {"id": usuarioId} : null,
      "detalleTamano": tamanoSeleccionado!['capacidad'].toString(),
      "precioTotal": total,        
      "montoAbonado": abono,       
      "notas": notasFinales
    };

    try {
      final res = isEdit 
        ? await http.put(url, headers: {"Content-Type": "application/json"}, body: json.encode(datosPedido))
        : await http.post(url, headers: {"Content-Type": "application/json"}, body: json.encode(datosPedido));

      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${res.body}")));
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.pedidoParaEditar != null;
    final List<dynamic> coberturasDisponibles = tortaSeleccionada != null && tortaSeleccionada!['coberturas'] != null 
        ? tortaSeleccionada!['coberturas'] : [];

    return Scaffold(
      backgroundColor: azulPastelFondo,
      appBar: AppBar(
        title: Text(isEdit ? "Editar Pedido ✏️" : "Nuevo Pedido 📝", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: azulPastelPrincipal,
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
                    value: Map<String, dynamic>.from(t), child: Text(t['nombre'])
                  )).toList(),
                  onChanged: (val) => setState(() { 
                    tortaSeleccionada = val; 
                    tamanoSeleccionado = null; 
                    coberturaSeleccionada = null; 
                  }),
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
                      String cap = tam['capacidad'].toString();
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: Map<String, dynamic>.from(tam), child: Text("$cap - \$${tam['precio']}")
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
                  spacing: 15, runSpacing: 10,
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
                abonoCtrl, "Monto abonado (\$)", Icons.payments_outlined, 
                keyboardType: TextInputType.number,
                onChanged: (val) => setState(() {})
              ),

              const SizedBox(height: 25),
              _buildTextField(notasCtrl, "Notas u observaciones", Icons.edit_note, maxLines: 2),
              
              const SizedBox(height: 30),
              if (tamanoSeleccionado != null) ...[
                _buildResumenPago(),
                _buildCodigosBarrasDoble(),
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
              const SizedBox(height: 40),
            ],
          ),
    );
  }

  Widget _buildResumenPago() {
    double totalFinal = _getPrecioFinal();
    double abonoIngresado = double.tryParse(abonoCtrl.text) ?? 0.0;
    double loQueFalta = (totalFinal - abonoIngresado).clamp(0, 99999);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueGrey[800],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _rowResumen("TOTAL:", "\$${totalFinal.toInt()}", Colors.white70),
          const SizedBox(height: 5),
          _rowResumen("ABONO:", "- \$${abonoIngresado.toInt()}", Colors.greenAccent),
          const Divider(color: Colors.white24, height: 20),
          _rowResumen("FALTA PAGAR:", "\$${loQueFalta.toInt()}", Colors.white, isBold: true),
        ],
      ),
    );
  }

  Widget _rowResumen(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: isBold ? 18 : 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(color: color, fontSize: isBold ? 24 : 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  // --- WIDGET DE CÓDIGOS DOBLES ---
  Widget _buildCodigosBarrasDoble() {
    double totalFinal = _getPrecioFinal();
    double abonoIngresado = double.tryParse(abonoCtrl.text) ?? 0.0;
    double loQueFalta = (totalFinal - abonoIngresado).clamp(0, 99999);

    return Column(
      children: [
        const SizedBox(height: 20),
        if (abonoIngresado > 0)
          _cardCodigoIndividual(
            titulo: "PASO 1: COBRAR ABONO AHORA",
            monto: abonoIngresado,
            color: Colors.green[700]!,
            codigo: _generarCodigoParaMonto(abonoIngresado),
          ),
        const SizedBox(height: 20),
        _cardCodigoIndividual(
          titulo: loQueFalta > 0 ? "PASO 2: COBRAR SALDO AL ENTREGAR" : "PEDIDO PAGADO",
          monto: loQueFalta,
          color: loQueFalta > 0 ? Colors.orange[800]! : Colors.blueGrey,
          codigo: _generarCodigoParaMonto(loQueFalta),
        ),
      ],
    );
  }

  Widget _cardCodigoIndividual({required String titulo, required double monto, required Color color, required String codigo}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
          const SizedBox(height: 5),
          Text("\$${monto.toInt()}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 10),
          BarcodeWidget(
            barcode: Barcode.ean13(),
            data: codigo,
            width: double.infinity, height: 70,
            drawText: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownContainer(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(10),
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
      controller: controller, keyboardType: keyboardType,
      maxLines: maxLines, onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: azulPastelOscuro),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE1F5FE))),
      ),
    );
  }

  Widget _choiceChipHorario(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: bloqueSeleccionado == value,
      onSelected: (s) => setState(() => bloqueSeleccionado = value),
      selectedColor: azulPastelPrincipal,
    );
  }

  Widget _filtroChip(String label, IconData icono) {
    return ChoiceChip(
      avatar: Icon(icono, size: 18),
      label: Text(label),
      selected: categoriaSeleccionada == label,
      onSelected: (bool s) { if (s) _filtrarProductos(label); },
      selectedColor: azulPastelPrincipal,
    );
  }
}