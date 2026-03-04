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

  // Paleta de Colores Pastel
  final Color azulPastelFondo = const Color(0xFFF0F8FF);
  final Color azulPastelPrincipal = const Color(0xFFB3E5FC);
  final Color azulPastelOscuro = const Color(0xFF81D4FA);
  final Color rosaPastelAlerta = const Color(0xFFFFB7B2); // Para días bloqueados

  List<dynamic> _pedidosDelDia = [];
  List<dynamic> _bloqueosCompletos = [];
  List<DateTime> _diasBloqueados = [];

  final Map<DateTime, bool> _escudoTemporal = {};
  Map<DateTime, List<dynamic>> _eventosDePedidos = {};
  bool _cargando = false;

  final String _baseUrl = "https://pasteleria-backend-production-24fc.up.railway.app/api";

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    await _obtenerDiasBloqueados();
    await _cargarMarcadoresDelMes(_diaEnfocado);
    await _obtenerPedidosPorFecha(_diaSeleccionado);
  }

  List<dynamic> _getEventosDelDia(DateTime day) {
    DateTime fechaLimpia = DateTime(day.year, day.month, day.day);
    return _eventosDePedidos[fechaLimpia] ?? [];
  }

  Future<void> _cargarMarcadoresDelMes(DateTime mesFoco) async {
    final url = Uri.parse('$_baseUrl/pedidos/mes?anio=${mesFoco.year}&mes=${mesFoco.month}');
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        List<dynamic> fechasStr = json.decode(res.body);
        if (mounted) {
          setState(() {
            _eventosDePedidos = {};
            for (var fStr in fechasStr) {
              DateTime f = DateTime.parse(fStr);
              DateTime fLimpia = DateTime(f.year, f.month, f.day);
              _eventosDePedidos[fLimpia] = [true];
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error cargando marcadores: $e");
    }
  }

  Future<void> _obtenerDiasBloqueados() async {
    final url = Uri.parse('$_baseUrl/dias-bloqueados');
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        List<dynamic> data = json.decode(res.body);
        if (mounted) {
          setState(() {
            _bloqueosCompletos = data;
            _diasBloqueados = data.map((d) => DateTime.parse(d['fecha'])).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error cargando bloqueos: $e");
    }
  }

  Future<void> _obtenerPedidosPorFecha(DateTime fecha) async {
    if (!mounted) return;
    setState(() => _cargando = true);
    String fechaStr = "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
    final url = Uri.parse('$_baseUrl/pedidos/fecha/$fechaStr');

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        List<dynamic> pedidos = json.decode(res.body);
        if (mounted) {
          setState(() {
            _pedidosDelDia = pedidos;
            DateTime fechaLimpia = DateTime(fecha.year, fecha.month, fecha.day);
            if (pedidos.isNotEmpty) {
              _eventosDePedidos[fechaLimpia] = [true];
            } else {
              _eventosDePedidos.remove(fechaLimpia);
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error obteniendo pedidos: $e");
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _gestionarBloqueo(DateTime fecha) async {
    DateTime fechaLimpia = DateTime(fecha.year, fecha.month, fecha.day);
    String fechaStr = "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";

    dynamic bloqueoExistente;
    try {
      bloqueoExistente = _bloqueosCompletos.firstWhere((d) {
        DateTime fServer = DateTime.parse(d['fecha']);
        return isSameDay(fServer, fechaLimpia);
      });
    } catch (e) {
      bloqueoExistente = null;
    }

    setState(() {
      if (bloqueoExistente != null) {
        _diasBloqueados.removeWhere((d) => isSameDay(d, fechaLimpia));
        _escudoTemporal[fechaLimpia] = false;
      } else {
        _diasBloqueados.add(fechaLimpia);
        _escudoTemporal[fechaLimpia] = true;
      }
    });

    try {
      if (bloqueoExistente != null) {
        final id = bloqueoExistente['id'];
        final res = await http.delete(Uri.parse('$_baseUrl/dias-bloqueados/$id'))
            .timeout(const Duration(seconds: 15));

        if (res.statusCode == 200 || res.statusCode == 204) {
          _mostrarMensaje("Día disponible nuevamente 🔓");
        }
      } else {
        final res = await http.post(
          Uri.parse('$_baseUrl/dias-bloqueados'),
          headers: {"Content-Type": "application/json"},
          body: json.encode({"fecha": fechaStr, "motivo": "Cerrado"})
        ).timeout(const Duration(seconds: 15));

        if (res.statusCode == 200 || res.statusCode == 201) {
          _mostrarMensaje("Día bloqueado con éxito 🔒");
        }
      }
    } catch (e) {
      _mostrarMensaje("Error de conexión");
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      _obtenerDiasBloqueados();
      if (mounted) {
        setState(() => _escudoTemporal.remove(fechaLimpia));
      }
    }
  }

  void _mostrarMensaje(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: azulPastelOscuro,
        content: Text(msg, style: TextStyle(color: Colors.blueGrey[900])), 
        duration: const Duration(seconds: 2)
      )
    );
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
          Icon(Icons.assignment_turned_in_rounded, size: 20, color: azulPastelOscuro),
          const SizedBox(width: 10),
          Text(
            "Hoy tienes $total ${total == 1 ? 'pedido' : 'pedidos'}",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarPedido(int id) async {
    final url = Uri.parse('$_baseUrl/pedidos/$id');
    try {
      final res = await http.delete(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 204) {
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
        backgroundColor: azulPastelFondo,
        title: const Text("¿Eliminar pedido?"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCELAR", style: TextStyle(color: Colors.blueGrey[400]))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarPedido(id);
            },
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool diaEstaBloqueado = _diasBloqueados.any((d) => isSameDay(d, _diaSeleccionado));

    return Scaffold(
      backgroundColor: azulPastelFondo,
      appBar: AppBar(
        title: const Text("Agenda de Pedidos 📅", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: azulPastelPrincipal,
        foregroundColor: Colors.blueGrey[800],
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _inicializarDatos)
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TableCalendar(
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _diaEnfocado,
              calendarFormat: _formatoCalendario,
              eventLoader: _getEventosDelDia,
              locale: 'es_ES',
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(color: Colors.blueGrey[800], fontWeight: FontWeight.bold, fontSize: 17),
              ),
              onFormatChanged: (format) => setState(() => _formatoCalendario = format),
              selectedDayPredicate: (day) => isSameDay(_diaSeleccionado, day),
              onDayLongPressed: (selectedDay, focusedDay) => _gestionarBloqueo(selectedDay),
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
                      decoration: BoxDecoration(color: rosaPastelAlerta, shape: BoxShape.circle),
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
                      color: estaBloqueado ? rosaPastelAlerta.withOpacity(0.8) : azulPastelOscuro,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text('${day.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  );
                },
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: azulPastelPrincipal.withOpacity(0.5), shape: BoxShape.circle),
                todayTextStyle: TextStyle(color: Colors.blueGrey[900], fontWeight: FontWeight.bold),
                markerDecoration: BoxDecoration(color: azulPastelOscuro, shape: BoxShape.circle),
                markersMaxCount: 1,
              ),
            ),
          ),
          const Divider(height: 1),
          if (!_cargando) _buildContadorPedidos(),
          Expanded(
            child: _cargando
                ? Center(child: CircularProgressIndicator(color: azulPastelOscuro))
                : _pedidosDelDia.isEmpty
                    ? Center(child: Text("No hay pedidos para este día", style: TextStyle(color: Colors.blueGrey[300], fontSize: 16)))
                    : ListView.builder(
                        itemCount: _pedidosDelDia.length,
                        itemBuilder: (context, index) {
                          final pedido = _pedidosDelDia[index];
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: azulPastelPrincipal.withOpacity(0.3))),
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
                                backgroundColor: pedido['bloqueHorario'] == "TARDE" ? Colors.amber[50] : Colors.blue[50],
                                child: Icon(
                                  pedido['bloqueHorario'] == "TARDE" ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                                  color: pedido['bloqueHorario'] == "TARDE" ? Colors.orange[300] : Colors.blue[300],
                                ),
                              ),
                              title: Text("${pedido['nombreCliente']} - ${pedido['torta']['nombre']}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
                              subtitle: Text("${pedido['bloqueHorario']} | ${_formatearDetalle(pedido['detalleTamano'], pedido['torta']['nombre'])}"),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
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
        onPressed: diaEstaBloqueado
            ? () => _mostrarMensaje("⚠️ Día cerrado para pedidos")
            : () async {
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AgendarPedidoScreen(fechaSeleccionada: _diaSeleccionado)),
                );
                if (resultado == true) {
                  _obtenerPedidosPorFecha(_diaSeleccionado);
                  _cargarMarcadoresDelMes(_diaEnfocado);
                }
              },
        backgroundColor: diaEstaBloqueado ? Colors.blueGrey[100] : azulPastelPrincipal,
        elevation: 2,
        child: Icon(Icons.add_task, color: diaEstaBloqueado ? Colors.blueGrey[300] : Colors.blueGrey[800]),
      ),
    );
  }
}