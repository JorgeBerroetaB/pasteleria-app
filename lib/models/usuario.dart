class Usuario {
  final int id;
  final String username;
  final String nombreCompleto;
  final String rol;

  Usuario({required this.id, required this.username, required this.nombreCompleto, required this.rol});

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      username: json['username'],
      nombreCompleto: json['nombreCompleto'],
      rol: json['rol'],
    );
  }
}