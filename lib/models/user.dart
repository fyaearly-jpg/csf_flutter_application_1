class User {
  final int idUser;
  final String nama;
  final String role;
  final String statusAkun;
  final String? username;
  final String? email;
  final String? noWhatsapp;

  User({
    required this.idUser,
    required this.nama,
    required this.role,
    required this.statusAkun,
    this.username,
    this.email,
    this.noWhatsapp,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        idUser: j['id_user'] as int,
        nama: j['nama'] as String,
        role: j['role'] as String,
        statusAkun: j['status_akun'] as String,
        username: j['username'] as String?,
        email: j['email'] as String?,
        noWhatsapp: j['no_whatsapp'] as String?,
      );
}
