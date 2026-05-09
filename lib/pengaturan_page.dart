import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mayomo/database_helper.dart';
import 'package:mayomo/login_page.dart';

class PengaturanPage extends StatefulWidget {
  final int userId;
  const PengaturanPage({super.key, required this.userId});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _kategori = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user =
        await DatabaseHelper.instance.getUserById(widget.userId);
    final kategori =
        await DatabaseHelper.instance.getKategori(widget.userId);
    setState(() {
      _user = user;
      _kategori = kategori;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            child: const Text('Keluar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  void _showEditProfil() {
    final namaCtrl =
        TextEditingController(text: _user?['nama'] as String? ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Edit Profil',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: namaCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (namaCtrl.text.isNotEmpty) {
                      await DatabaseHelper.instance.updateUser(
                        widget.userId,
                        {'nama': namaCtrl.text.trim()},
                      );
                      final prefs =
                          await SharedPreferences.getInstance();
                      await prefs.setString(
                          'user_nama', namaCtrl.text.trim());
                      _loadData();
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3460),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Simpan',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showKelolaKategori() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KategoriManager(
        userId: widget.userId,
        onChanged: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    children: [
                      const Text(
                        'Pengaturan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!_loading) ...[
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              (_user?['nama'] as String? ?? 'U')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _user?['nama'] as String? ?? '',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user?['email'] as String? ?? '',
                          style: TextStyle(
                              color:
                                  Colors.white.withValues(alpha: 0.6),
                              fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Akun',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  _buildMenuCard([
                    _buildMenuItem(
                      Icons.person_outline,
                      'Edit Profil',
                      'Ubah nama dan informasi akun',
                      onTap: _showEditProfil,
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      Icons.category_outlined,
                      'Kelola Kategori',
                      '${_kategori.length} kategori tersedia',
                      onTap: _showKelolaKategori,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  const Text(
                    'Lainnya',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  _buildMenuCard([
                    _buildMenuItem(
                      Icons.info_outline,
                      'Tentang Aplikasi',
                      'DompetKu v1.0.0',
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'DompetKu',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Text('💰',
                            style: TextStyle(fontSize: 32)),
                        children: const [
                          Text(
                              'Aplikasi pencatatan keuangan offline yang mudah dan praktis.')
                        ],
                      ),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      Icons.logout_rounded,
                      'Keluar',
                      'Logout dari akun ini',
                      color: Colors.redAccent,
                      onTap: _logout,
                    ),
                  ]),
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'DompetKu • Made with ❤️',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
    Color? color,
  }) {
    final c = color ?? const Color(0xFF1A1A2E);
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: c, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14, color: c)),
      subtitle: Text(subtitle,
          style:
              TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      trailing: Icon(Icons.chevron_right,
          color: Colors.grey.shade400, size: 20),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildDivider() => Divider(
      height: 1,
      indent: 68,
      endIndent: 16,
      color: Colors.grey.shade100);
}

// ===== KELOLA KATEGORI =====
class _KategoriManager extends StatefulWidget {
  final int userId;
  final VoidCallback onChanged;
  const _KategoriManager(
      {required this.userId, required this.onChanged});

  @override
  State<_KategoriManager> createState() => _KategoriManagerState();
}

class _KategoriManagerState extends State<_KategoriManager>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pemasukan = [];
  List<Map<String, dynamic>> _pengeluaran = [];

  final _ikonList = [
    '💰','💻','📈','🎁','🍜','🚗','🛒','🎬','🏥','📄',
    '📚','📦','✈️','🏠','🎮','💊','👕','🍕','☕','🎵',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final masuk = await DatabaseHelper.instance
        .getKategori(widget.userId, jenis: 'pemasukan');
    final keluar = await DatabaseHelper.instance
        .getKategori(widget.userId, jenis: 'pengeluaran');
    setState(() {
      _pemasukan = masuk;
      _pengeluaran = keluar;
    });
    widget.onChanged();
  }

  void _showTambahKategori(String jenis) {
    String selectedIkon = _ikonList.first;
    final namaCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(
              'Tambah Kategori ${jenis == 'pemasukan' ? 'Pemasukan' : 'Pengeluaran'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Kategori',
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Pilih Ikon:',
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _ikonList.map((ikon) {
                  final isSelected = ikon == selectedIkon;
                  return GestureDetector(
                    onTap: () => setDialogState(
                        () => selectedIkon = ikon),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0F3460)
                                .withValues(alpha: 0.15)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(
                                color: const Color(0xFF0F3460),
                                width: 2)
                            : null,
                      ),
                      child: Center(
                          child: Text(ikon,
                              style:
                                  const TextStyle(fontSize: 20))),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (namaCtrl.text.isNotEmpty) {
                  await DatabaseHelper.instance.insertKategori({
                    'user_id': widget.userId,
                    'nama': namaCtrl.text.trim(),
                    'jenis': jenis,
                    'ikon': selectedIkon,
                    'warna': '0xFF607D8B',
                  });
                  _loadData();
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F3460),
              ),
              child: const Text('Simpan',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteKategori(int id) async {
    await DatabaseHelper.instance.deleteKategori(id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Kelola Kategori',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF0F3460),
                  labelColor: const Color(0xFF0F3460),
                  unselectedLabelColor: Colors.grey,
                  labelStyle:
                      const TextStyle(fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Pemasukan'),
                    Tab(text: 'Pengeluaran'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildKategoriList(_pemasukan, 'pemasukan'),
                _buildKategoriList(_pengeluaran, 'pengeluaran'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKategoriList(
      List<Map<String, dynamic>> data, String jenis) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, i) {
              final k = data[i];
              final color =
                  int.tryParse(k['warna'] as String? ?? '0xFF9E9E9E') ??
                      0xFF9E9E9E;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            Color(color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Center(
                          child: Text(k['ikon'] as String,
                              style:
                                  const TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        k['nama'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          _deleteKategori(k['id'] as int),
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 20),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _showTambahKategori(jenis),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Kategori'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F3460),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}