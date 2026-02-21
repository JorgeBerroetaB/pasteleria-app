import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'agendar_pedido_screen.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _diaSeleccionado = DateTime.now();
  DateTime _diaEnfocado = DateTime.now();
  CalendarFormat _formatoCalendario = CalendarFormat.month;
  
  List<dynamic> _pedidosDelDia = [];
  List<DateTime> _diasBloqueados = [];
  
  // MAPA PARA LOS PUNTITOS: Guarda { Fecha: Lista de pedidos }
  Map<DateTime, List<dynamic>> _eventosDePedidos = {};
  
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  // Carga inicial de todo lo necesario
  Future<void> _inicializarDatos() async {
    await _obtenerDiasBloqueados();
    await _cargarMarcadoresDelMes(_diaEnfocado); // Carga puntitos desde el nuevo endpoint de Java
    await _obtenerPedidosPorFecha(_diaSeleccionado); // Detalle del día actual
  }

  // Función para que TableCalendar sepa qué días tienen puntitos
  List<dynamic> _getEventosDelDia(DateTime day) {
    DateTime fechaLimpia = DateTime(day.year, day.month, day.day);
    return _eventosDePedidos[fechaLimpia] ?? [];
  }

  // --- FUNCIÓN ACTUALIZADA CON EL NUEVO ENDPOINT DE JAVA ---
  Future<void> _cargarMarcadoresDelMes(DateTime mesFoco) async {
    final url = Uri.parse('http://192.168.1.86:8080/api/pedidos/mes?anio=${mesFoco.year}&mes=${mesFoco.month}');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        List<dynamic> fechasStr = json.decode(res.body);
        setState(() {
          _eventosDePedidos = {};
          for (var fStr in fechasStr) {
            DateTime f = DateTime.parse(fStr);
            DateTime fLimpia = DateTime(f.year, f.month, f.day);
            _eventosDePedidos[fLimpia] = [true]; // Marcador para que aparezca el punto
          }
        });
      }
    } catch (e) {
      debugPrint("Error cargando marcadores: $e");
    }
  }

  Future<void> _obtenerDiasBloqueados() async {
    final url = Uri.parse('http://192.168.1.86:8080/api/dias-bloqueados');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        List<dynamic> data = json.decode(res.body);
        setState(() {
          _diasBloqueados = data.map((d) => DateTime.parse(d['fecha'])).toList();
        });
      }
    } catch (e) {
      debugPrint("Error cargando bloqueos: $e");
    }
  }

  Future<void> _obtenerPedidosPorFecha(DateTime fecha) async {
    setState(() => _cargando = true);
    String fechaStr = "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
    final url = Uri.parse('http://192.168.1.86:8080/api/pedidos/fecha/$fechaStr');

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        List<dynamic> pedidos = json.decode(res.body);
        setState(() {
          _pedidosDelDia = pedidos;
          
          // Actualizamos el marcador del día seleccionado localmente para que sea instantáneo
          DateTime fechaLimpia = DateTime(fecha.year, fecha.month, fecha.day);
          if (pedidos.isNotEmpty) {
            _eventosDePedidos[fechaLimpia] = [true];
          } else {
            _eventosDePedidos.remove(fechaLimpia);
          }
        });
      }
    } catch (e) {
      debugPrint("Error obteniendo pedidos: $e");
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _gestionarBloqueo(DateTime fecha) async {
    String fechaStr = "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
    bool yaBloqueado = _diasBloqueados.any((d) => isSameDay(d, fecha));

    try {
      if (yaBloqueado) {
        final res = await http.delete(Uri.parse('http://192.168.1.86:8080/api/dias-bloqueados/$fechaStr'));
        if (res.statusCode == 200) {
          _mostrarMensaje("Día desbloqueado 🔓");
          _obtenerDiasBloqueados();
        }
      } else {
        final res = await http.post(
          Uri.parse('http://192.168.1.86:8080/api/dias-bloqueados'),
          headers: {"Content-Type": "application/json"},
          body: json.encode({"fecha": fechaStr, "motivo": "Cerrado"})
        );
        if (res.statusCode == 200 || res.statusCode == 201) {
          _mostrarMensaje("Día bloqueado 🔒");
          _obtenerDiasBloqueados();
        }
      }
    } catch (e) {
      debugPrint("Error gestionando bloqueo: $e");
    }
  }

  void _mostrarMensaje(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
  }

  String _formatearDetalle(dynamic detalle, String nombreProducto) {
    String texto = detalle.toString().toLowerCase().trim();
    String soloNumero = texto.replaceAll(RegExp(r'[^0-9]'), '');
    if (soloNumero.isEmpty) return detalle.toString();

    String nombre = nombreProducto.toLowerCase();
    if (nombre.contains("torta") || nombre.contains("pastel")) {
      return "$soloNumero personas";
    } else {
      return "$soloNumero unidades";
    }
  }

  Widget _buildContadorPedidos() {
    if (_pedidosDelDia.isEmpty) return const SizedBox.shrink();
    int total = _pedidosDelDia.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.assignment_turned_in_rounded, size: 20, color: Colors.orange),
          const SizedBox(width: 10),
          Text(
            "Hoy tienes $total ${total == 1 ? 'pedido' : 'pedidos'}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarPedido(int id) async {
    final url = Uri.parse('http://192.168.1.86:8080/api/pedidos/$id');
    try {
      final res = await http.delete(url);
      if (res.statusCode == 200) {
        _obtenerPedidosPorFecha(_diaSeleccionado);
        _mostrarMensaje("Pedido eliminado correctamente");
      }
    } catch (e) {
      debugPrint("Error al eliminar: $e");
    }
  }

  void _mostrarConfirmacionBorrado(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar pedido?"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () { Navigator.pop(context); _eliminarPedido(id); },
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agenda de Pedidos 📅"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: _inicializarDatos, 
          )
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _diaEnfocado,
            calendarFormat: _formatoCalendario,
            eventLoader: _getEventosDelDia, // Muestra los puntitos

            onFormatChanged: (format) => setState(() => _formatoCalendario = format),
            selectedDayPredicate: (day) => isSameDay(_diaSeleccionado, day),
            enabledDayPredicate: (day) => true, 
            onDayLongPressed: (selectedDay, focusedDay) => _gestionarBloqueo(selectedDay),

            // CARGAR PUNTITOS AL CAMBIAR DE MES
            onPageChanged: (focusedDay) {
              _diaEnfocado = focusedDay;
              _cargarMarcadoresDelMes(focusedDay);
            },

            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _diaSeleccionado = selectedDay;
                _diaEnfocado = focusedDay;
              });
              _obtenerPedidosPorFecha(selectedDay);
            },

            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                if (_diasBloqueados.any((d) => isSameDay(d, day))) {
                  return Container(
                    margin: const EdgeInsets.all(6.0),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    child: Text('${day.day}', style: const TextStyle(color: Colors.white)),
                  );
                }
                return null;
              },
              selectedBuilder: (context, day, focusedDay) {
                bool estaBloqueado = _diasBloqueados.any((d) => isSameDay(d, day));
                return Container(
                  margin: const EdgeInsets.all(6.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: estaBloqueado ? Colors.red.shade900 : Colors.orange,
                    shape: BoxShape.circle,
                    border: estaBloqueado ? Border.all(color: Colors.white, width: 2) : null,
                  ),
                  child: Text('${day.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                );
              },
            ),

            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              markerDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              markersMaxCount: 1, 
            ),
          ),
          const Divider(height: 1),
          if (!_cargando) _buildContadorPedidos(),
          Expanded(
            child: _cargando 
              ? const Center(child: CircularProgressIndicator())
              : _pedidosDelDia.isEmpty 
                ? const Center(child: Text("No hay pedidos para este día", style: TextStyle(color: Colors.grey, fontSize: 16)))
                : ListView.builder(
                    itemCount: _pedidosDelDia.length,
                    itemBuilder: (context, index) {
                      final pedido = _pedidosDelDia[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                        elevation: 2,
                        child: ListTile(
                          onTap: () async {
                            final resultado = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AgendarPedidoScreen(
                                  fechaSeleccionada: _diaSeleccionado,
                                  pedidoParaEditar: pedido,
                                ),
                              ),
                            );
                            if (resultado == true) _obtenerPedidosPorFecha(_diaSeleccionado);
                          },
                          leading: CircleAvatar(
                            backgroundColor: pedido['bloqueHorario'] == "TARDE" ? Colors.orange.shade100 : Colors.indigo.shade100,
                            child: Icon(
                              pedido['bloqueHorario'] == "TARDE" ? Icons.wb_sunny : Icons.nightlight_round,
                              color: pedido['bloqueHorario'] == "TARDE" ? Colors.orange : Colors.indigo,
                            ),
                          ),
                          title: Text("${pedido['nombreCliente']} - ${pedido['torta']['nombre']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${pedido['bloqueHorario']} | ${_formatearDetalle(pedido['detalleTamano'], pedido['torta']['nombre'])}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                            onPressed: () => _mostrarConfirmacionBorrado(pedido['id']),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _diasBloqueados.any((d) => isSameDay(d, _diaSeleccionado)) 
          ? () => _mostrarMensaje("⚠️ Día cerrado para pedidos") 
          : () async {
              final resultado = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AgendarPedidoScreen(fechaSeleccionada: _diaSeleccionado)),
              );
              if (resultado == true) {
                _obtenerPedidosPorFecha(_diaSeleccionado);
                _cargarMarcadoresDelMes(_diaEnfocado); // Actualiza puntitos al volver
              }
            },
        backgroundColor: _diasBloqueados.any((d) => isSameDay(d, _diaSeleccionado)) ? Colors.grey : Colors.orange,
        child: const Icon(Icons.add_task, color: Colors.white),
      ),
    );
  }
}