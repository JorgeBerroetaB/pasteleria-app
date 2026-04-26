import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- IMPORTACIONES DE TUS PANTALLAS ---
import 'agregar_torta.dart';
import 'detalle_torta.dart';
import 'calendario_screen.dart';
import 'gestion_coberturas_screen.dart'; 
import 'login_screen.dart'; 
import 'registro_empleado_screen.dart';
import 'perfil_screen.dart';

void main() => runApp(const MyApp());

const Color azulPastelFondo = Color(0xFFF0F8FF);
const Color azulPastelPrincipal = Color(0xFFB3E5FC);
const Color azulPastelOscuro = Color(0xFF81D4FA);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pastelería Dulce Día',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
      locale: const Locale('es', 'ES'),
      theme: ThemeData(
        colorSchemeSeed: azulPastelOscuro,
        useMaterial3: true,
        scaffoldBackgroundColor: azulPastelFondo,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => const ListaTortas(),
      },
    );
  }
}

class ListaTortas extends StatefulWidget {
  const ListaTortas({super.key});
  @override
  State<ListaTortas> createState() => _ListaTortasState();
}

class _ListaTortasState extends State<ListaTortas> {
  List datos = [];
  bool cargando = true;
  String nombreUsuario = "Cargando...";
  String rolUsuario = "USER";

  final String _urlApi = 'https://pasteleria-backend-production-24fc.up.railway.app/api/tortas';

  @override
  void initState() {
    super.initState();
    _cargarInfoUsuario();
    cargarTortas();
  }

  Future<void> _cargarInfoUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Leemos el nombre completo que guardamos en el Login
      nombreUsuario = prefs.getString('nombreCompleto') ?? "Empleado";
      rolUsuario = prefs.getString('rol') ?? "USER";
    });
  }

  Future<void> cargarTortas() async {
    if (!mounted) return;
    setState(() => cargando = true);
    try {
      final res = await http.get(Uri.parse(_urlApi));
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            datos = json.decode(res.body);
            cargando = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error cargando productos: $e");
      if (mounted) setState(() => cargando = false);
    }
  }

  void _mostrarAlertaCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Estás seguro de que quieres salir del sistema?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); 
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: const Text("Salir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List filtrarDatos(String categoria) {
    return datos.where((t) {
      return (t['categoria']?.toString().toLowerCase() ?? "") == categoria.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Pastelería Dulce Día", 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800], fontSize: 18)),
          backgroundColor: azulPastelPrincipal,
          actions: [
            IconButton(
              icon: Icon(Icons.calendar_month_outlined, color: Colors.blueGrey[800]),
              tooltip: "Calendario de Pedidos",
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarioScreen()));
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: azulPastelOscuro,
            indicatorWeight: 4,
            labelColor: Colors.blueGrey[800],
            unselectedLabelColor: Colors.blueGrey[400],
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Tortas", icon: Icon(Icons.cake_outlined)),
              Tab(text: "Tartas", icon: Icon(Icons.pie_chart_outline)),
              Tab(text: "Pastelitos", icon: Icon(Icons.cookie_outlined)),
            ],
          ),
        ),

        drawer: Drawer(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [azulPastelPrincipal, azulPastelOscuro],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                // AQUÍ SE MUESTRA EL NOMBRE DEL USUARIO LOGUEADO
                accountName: Text(
                  nombreUsuario, 
                  style: const TextStyle(color: Color(0xFF37474F), fontWeight: FontWeight.bold, fontSize: 18)
                ),
                // AQUÍ SE MUESTRA EL ROL
                accountEmail: Text(
                  "Rol: $rolUsuario", 
                  style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)
                ),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_rounded, size: 45, color: azulPastelOscuro),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.manage_accounts_outlined, color: Colors.blueGrey),
                title: const Text("Mi Perfil"),
                subtitle: const Text("Cambiar contraseña y datos"),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const PerfilScreen()));
                  _cargarInfoUsuario(); // Recargamos por si cambió el nombre en el perfil
                },
              ),
              ListTile(
                leading: const Icon(Icons.palette_outlined, color: Colors.blueGrey),
                title: const Text("Gestionar Coberturas"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const GestionCoberturasScreen()));
                },
              ),
              
              if (rolUsuario == "ADMIN") 
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1_outlined, color: Colors.blueAccent),
                  title: const Text("Registrar Empleado"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => RegistroEmpleadoScreen()));
                  },
                ),

              const Spacer(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text("Cerrar Sesión"),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarAlertaCerrarSesion(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),

        floatingActionButton: FloatingActionButton(
          backgroundColor: azulPastelOscuro,
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white, size: 30),
          onPressed: () async {
            final resultado = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AgregarTortaScreen()),
            );
            if (resultado == true) cargarTortas();
          },
        ),
        body: cargando 
            ? const Center(child: CircularProgressIndicator(color: azulPastelOscuro)) 
            : RefreshIndicator(
                color: azulPastelOscuro,
                onRefresh: cargarTortas,
                child: TabBarView(
                  children: [
                    _buildListaFiltrada("Torta"),
                    _buildListaFiltrada("Tarta"),
                    _buildListaFiltrada("Pastelito"),
                  ],
                ),
              ),
      ),
    );
  }

  // --- MÉTODOS DE APOYO (Mantener igual que antes) ---

  String _obtenerPrecioTexto(dynamic torta) {
    if (torta['tamanos'] == null || (torta['tamanos'] as List).isEmpty) return "Consultar";
    List tamanos = torta['tamanos'];
    tamanos.sort((a, b) => (a['precio'] ?? 0).compareTo(b['precio'] ?? 0));
    double precioMasBajo = tamanos[0]['precio'].toDouble();
    return tamanos.length > 1 ? "Desde \$${precioMasBajo.toStringAsFixed(0)}" : "\$${precioMasBajo.toStringAsFixed(0)}";
  }

  Widget _buildPlaceholderImage(String categoria) {
    IconData iconData;
    switch (categoria.toLowerCase()) {
      case 'tarta': iconData = Icons.pie_chart_outline; break;
      case 'pastelito': iconData = Icons.cookie_outlined; break;
      default: iconData = Icons.cake_outlined;
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [azulPastelPrincipal.withOpacity(0.4), azulPastelOscuro.withOpacity(0.2)],
        ),
      ),
      child: Center(child: Icon(iconData, size: 40, color: azulPastelOscuro.withOpacity(0.8))),
    );
  }

  Widget _buildListaFiltrada(String categoria) {
    final listaFiltrada = filtrarDatos(categoria);
    if (listaFiltrada.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_outlined, size: 80, color: azulPastelPrincipal),
              const SizedBox(height: 15),
              Text("No hay ${categoria}s aún", 
                style: TextStyle(color: Colors.blueGrey[300], fontSize: 18, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: listaFiltrada.length,
      itemBuilder: (context, i) {
        final torta = listaFiltrada[i];
        return Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              onTap: () async {
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetalleTortaScreen(torta: torta)),
                );
                if (resultado == true) cargarTortas();
              },
              child: Row(
                children: [
                  SizedBox(
                    width: 110, height: 110,
                    child: (torta['imagenUrl'] != null && torta['imagenUrl'].isNotEmpty)
                        ? Image.network(torta['imagenUrl'], fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildPlaceholderImage(categoria))
                        : _buildPlaceholderImage(categoria),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(torta['nombre'] ?? "Sin nombre", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(torta['descripcion'] ?? "Sin descripción", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const Spacer(),
                          Text(_obtenerPrecioTexto(torta), style: const TextStyle(fontWeight: FontWeight.bold, color: azulPastelOscuro)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}