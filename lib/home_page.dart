import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mayomo/database_helper.dart';
import 'package:mayomo/transaksi_page.dart';
import 'package:mayomo/rekapitulasi_page.dart';
import 'package:mayomo/pengaturan_page.dart';

// Warna konstanta
const _kBg = Color(0xFF0D0D1A);
const _kSurface = Color(0xFF1A1A2E);
const _kSurfaceHigh = Color(0xFF252540);
const _kBorder = Color(0xFF252545);
const _kPurple = Color(0xFF7B6FF0);
const _kTeal = Color(0xFF00C9A7);
const _kRed = Color(0xFFFF6B6B);
const _kTextSec = Color(0xFF8888AA);
const _kTextMuted = Color(0xFF55557A);

class HomePage extends StatefulWidget {
  final int userId;
  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _idx = 0;
  String _nama = '';
  Map<String, dynamic> _ringkasan = {'pemasukan': 0.0, 'pengeluaran': 0.0};
  List<Map<String, dynamic>> _transaksiTerkini = [];
  double _hariIni = 0;
  double _7hari = 0;
  final DateTime _now = DateTime.now();
  bool _loading = true;
  bool _saldoVisible = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final nama = prefs.getString('user_nama') ?? '';
    final ringkasan = await DatabaseHelper.instance.getRingkasan(
      widget.userId,
      bulan: _now.month.toString(),
      tahun: _now.year.toString(),
    );
    final transaksi = await DatabaseHelper.instance.getTransaksi(
      widget.userId,
      bulan: _now.month.toString(),
      tahun: _now.year.toString(),
    );

    // Hitung hari ini & 7 hari (pengeluaran)
    final today = DateTime(_now.year, _now.month, _now.day);
    final week = today.subtract(const Duration(days: 6));
    double hariIni = 0, tujuhHari = 0;
    for (final t in transaksi) {
      if (t['jenis'] == 'pengeluaran') {
        final tgl = DateTime.parse(t['tanggal'] as String);
        final tglDay = DateTime(tgl.year, tgl.month, tgl.day);
        if (tglDay == today) hariIni += (t['jumlah'] as num).toDouble();
        if (!tglDay.isBefore(week)) tujuhHari += (t['jumlah'] as num).toDouble();
      }
    }

    if (mounted) {
      setState(() {
        _nama = nama;
        _ringkasan = ringkasan;
        _transaksiTerkini = transaksi.take(10).toList();
        _hariIni = hariIni;
        _7hari = tujuhHari;
        _loading = false;
      });
    }
  }

  String _fRp(double v) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

  String _fRpCompact(double v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}Jt';
    if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}Rb';
    return _fRp(v);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboard(),
      TransaksiPage(userId: widget.userId, onRefresh: _loadData),
      RekapitulasiPage(userId: widget.userId),
      PengaturanPage(userId: widget.userId),
    ];

    return Scaffold(
      backgroundColor: _kBg,
      body: pages[_idx],
      floatingActionButton: _idx == 0
          ? GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _TransaksiFABForm(
                    userId: widget.userId,
                    onSaved: _loadData,
                  ),
                );
              },
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPurple, Color(0xFF9D94F5)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _kPurple.withValues(alpha: 0.5),
                      blurRadius: 20, spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 72 + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: Color(0xFF12122A),
        border: Border(top: BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBtn(icon: Icons.home_rounded, label: 'Home', active: _idx == 0,
                onTap: () { setState(() => _idx = 0); _loadData(); }),
            _NavBtn(icon: Icons.receipt_long_rounded, label: 'Transaksi', active: _idx == 1,
                onTap: () => setState(() => _idx = 1)),
            const SizedBox(width: 60),
            _NavBtn(icon: Icons.bar_chart_rounded, label: 'Rekap', active: _idx == 2,
                onTap: () => setState(() => _idx = 2)),
            _NavBtn(icon: Icons.person_rounded, label: 'Profil', active: _idx == 3,
                onTap: () => setState(() => _idx = 3)),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final pengeluaran = (_ringkasan['pengeluaran'] as num).toDouble();
    final pemasukan = (_ringkasan['pemasukan'] as num).toDouble();
    final bulanNama = DateFormat('MMMM yyyy', 'id_ID').format(_now);

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPurple,
      backgroundColor: _kSurface,
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 0),
              child: Column(
                children: [
                  // Top bar
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Selamat Datang Cuy,',
                              style: TextStyle(fontSize: 13, color: _kTextSec)),
                          Text('$_nama IU',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _saldoVisible = !_saldoVisible),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _kSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kBorder),
                          ),
                          child: Icon(
                            _saldoVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                            color: _kTextSec, size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Card utama — total pengeluaran (seperti gambar referensi)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B52D0), Color(0xFF7B6FF0), Color(0xFF9E5BD0)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _kPurple.withValues(alpha: 0.35),
                          blurRadius: 24, offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOTAL PENGELUARAN BULAN INI',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.65),
                                letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _loading
                              ? const SizedBox(
                                  height: 38,
                                  child: LinearProgressIndicator(
                                      color: Colors.white30,
                                      backgroundColor: Colors.white10))
                              : Text(
                                  _saldoVisible ? _fRp(pengeluaran) : 'Rp ••••••••',
                                  key: ValueKey('${_saldoVisible}_$pengeluaran'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5),
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Terakhir diperbarui: $bulanNama',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.55)),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            _HeaderChip(
                              icon: Icons.arrow_upward_rounded,
                              label: 'Pemasukan',
                              value: _saldoVisible ? _fRpCompact(pemasukan) : '••••',
                              color: _kTeal,
                            ),
                            const SizedBox(width: 20),
                            _HeaderChip(
                              icon: Icons.account_balance_wallet_rounded,
                              label: 'Saldo',
                              value: _saldoVisible
                                  ? _fRpCompact((pemasukan - pengeluaran))
                                  : '••••',
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick stats — hari ini & 7 hari (seperti gambar)
                  Row(
                    children: [
                      Expanded(
                        child: _QuickCard(
                          label: 'HARI INI',
                          value: _fRp(_hariIni),
                          gradientColors: const [Color(0xFF00A88B), Color(0xFF00C9A7)],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickCard(
                          label: '7 HARI TERAKHIR',
                          value: _fRp(_7hari),
                          gradientColors: const [Color(0xFF00695C), Color(0xFF00897B)],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section header riwayat
                  Row(
                    children: [
                      const Text('Transaksi Terkini',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _idx = 1),
                        child: const Text('Lihat Semua',
                            style: TextStyle(
                                color: _kPurple, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // List transaksi
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: _kPurple)),
              ),
            )
          else if (_transaksiTerkini.isEmpty)
            SliverToBoxAdapter(child: _buildEmpty())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _TransaksiCard(t: _transaksiTerkini[i], fRp: _fRp),
                childCount: _transaksiTerkini.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                  color: _kSurface, borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.receipt_long_rounded, size: 40, color: _kTextMuted),
            ),
            const SizedBox(height: 16),
            const Text('Belum ada transaksi',
                style: TextStyle(color: _kTextSec, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Tekan + untuk menambah transaksi',
                style: const TextStyle(color: _kTextMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ===== MINI WIDGET =====

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? _kPurple : _kTextMuted, size: 26),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    color: active ? _kPurple : _kTextMuted)),
          ],
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _HeaderChip({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 10)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String label, value;
  final List<Color> gradientColors;
  const _QuickCard({required this.label, required this.value, required this.gradientColors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
      ]),
    );
  }
}

class _TransaksiCard extends StatelessWidget {
  final Map<String, dynamic> t;
  final String Function(double) fRp;
  const _TransaksiCard({required this.t, required this.fRp});

  @override
  Widget build(BuildContext context) {
    final isPemasukan = t['jenis'] == 'pemasukan';
    final colorInt = int.tryParse(t['kategori_warna'] as String? ?? '0xFF7B6FF0') ?? 0xFF7B6FF0;
    final warna = Color(colorInt);
    final tanggal = DateTime.parse(t['tanggal'] as String);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                t['kategori_ikon'] as String? ?? '📦',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t['kategori_nama'] as String? ?? 'Kategori',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              if ((t['catatan'] as String?)?.isNotEmpty == true)
                Text(t['catatan'] as String,
                    style: const TextStyle(color: _kTextSec, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(DateFormat('dd MMM yyyy', 'id_ID').format(tanggal),
                  style: const TextStyle(color: _kTextMuted, fontSize: 11)),
            ]),
          ),
          Text(
            '${isPemasukan ? '+' : '-'}${fRp((t['jumlah'] as num).toDouble())}',
            style: TextStyle(
                color: isPemasukan ? _kTeal : _kRed,
                fontWeight: FontWeight.w800,
                fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// FAB form transaksi cepat dari home
class _TransaksiFABForm extends StatefulWidget {
  final int userId;
  final VoidCallback onSaved;
  const _TransaksiFABForm({required this.userId, required this.onSaved});

  @override
  State<_TransaksiFABForm> createState() => _TransaksiFABFormState();
}

class _TransaksiFABFormState extends State<_TransaksiFABForm> {
  final _jumlahCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  String _jenis = 'pengeluaran';
  List<Map<String, dynamic>> _kategori = [];
  int? _kategoriId;
  DateTime _tanggal = DateTime.now();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadKategori();
  }

  Future<void> _loadKategori() async {
    final list = await DatabaseHelper.instance.getKategori(widget.userId, jenis: _jenis);
    if (mounted) setState(() { _kategori = list; _kategoriId = null; });
  }

  Future<void> _save() async {
    final jumlah = double.tryParse(_jumlahCtrl.text.replaceAll('.', '').replaceAll(',', ''));
    if (jumlah == null || jumlah <= 0) return;
    if (_kategoriId == null) return;
    setState(() => _loading = true);
    await DatabaseHelper.instance.insertTransaksi({
      'user_id': widget.userId,
      'kategori_id': _kategoriId,
      'jumlah': jumlah,
      'jenis': _jenis,
      'catatan': _catatanCtrl.text,
      'tanggal': DateFormat('yyyy-MM-dd').format(_tanggal),
      'created_at': DateTime.now().toIso8601String(),
    });
    setState(() => _loading = false);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 20),
          const Text('Tambah Transaksi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 20),
          // Toggle jenis
          Container(
            decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.all(4),
            child: Row(children: [
              _Toggle('pengeluaran', 'Pengeluaran', _jenis, () {
                setState(() { _jenis = 'pengeluaran'; }); _loadKategori();
              }),
              _Toggle('pemasukan', 'Pemasukan', _jenis, () {
                setState(() { _jenis = 'pemasukan'; }); _loadKategori();
              }),
            ]),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _jumlahCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
            decoration: const InputDecoration(labelText: 'Jumlah', prefixText: 'Rp '),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _kategoriId,
            dropdownColor: _kSurface,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Kategori'),
            items: _kategori.map((k) => DropdownMenuItem<int>(
              value: k['id'] as int,
              child: Row(children: [
                Text(k['ikon'] as String, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(k['nama'] as String),
              ]),
            )).toList(),
            onChanged: (v) => setState(() => _kategoriId = v),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _tanggal,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: _kPurple)),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _tanggal = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: _kBg, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kBorder)),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 18, color: _kTextSec),
                const SizedBox(width: 10),
                Text(DateFormat('dd MMMM yyyy', 'id_ID').format(_tanggal),
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _catatanCtrl,
            maxLines: 2,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                labelText: 'Catatan (opsional)', hintText: 'Tambahkan keterangan...'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Simpan Transaksi',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String value, label, current;
  final VoidCallback onTap;
  const _Toggle(this.value, this.label, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final active = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? _kPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: active ? Colors.white : _kTextSec,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}