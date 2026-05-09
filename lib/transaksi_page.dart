import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mayomo/database_helper.dart';

const _kBg = Color(0xFF0D0D1A);
const _kSurface = Color(0xFF1A1A2E);
const _kSurfaceHigh = Color(0xFF252540);
const _kBorder = Color(0xFF252545);
const _kPurple = Color(0xFF7B6FF0);
const _kTeal = Color(0xFF00C9A7);
const _kRed = Color(0xFFFF6B6B);
const _kTextSec = Color(0xFF8888AA);
const _kTextMuted = Color(0xFF55557A);

class TransaksiPage extends StatefulWidget {
  final int userId;
  final VoidCallback? onRefresh;
  const TransaksiPage({super.key, required this.userId, this.onRefresh});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _semua = [];
  List<Map<String, dynamic>> _pemasukan = [];
  List<Map<String, dynamic>> _pengeluaran = [];
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final bulan = _selectedDate.month.toString();
    final tahun = _selectedDate.year.toString();
    final semua = await DatabaseHelper.instance.getTransaksi(widget.userId, bulan: bulan, tahun: tahun);
    final masuk = await DatabaseHelper.instance.getTransaksi(widget.userId, bulan: bulan, tahun: tahun, jenis: 'pemasukan');
    final keluar = await DatabaseHelper.instance.getTransaksi(widget.userId, bulan: bulan, tahun: tahun, jenis: 'pengeluaran');
    if (mounted) {
      setState(() {
        _semua = semua;
        _pemasukan = masuk;
        _pengeluaran = keluar;
        _loading = false;
      });
    }
  }

  String _fRp(double v) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

  void _showForm({Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransaksiForm(
        userId: widget.userId,
        existing: existing,
        onSaved: () {
          _loadData();
          widget.onRefresh?.call();
        },
      ),
    );
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text('Yakin ingin menghapus transaksi ini?', style: TextStyle(color: _kTextSec)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: _kTextSec))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _kRed),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseHelper.instance.deleteTransaksi(id);
      _loadData();
      widget.onRefresh?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF12122A), Color(0xFF1A1A35)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              border: Border(bottom: BorderSide(color: _kBorder, width: 0.5)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        const Text('Transaksi',
                            style: TextStyle(
                                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        _MonthPicker(
                          date: _selectedDate,
                          onChanged: (d) {
                            setState(() => _selectedDate = d);
                            _loadData();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(12)),
                      child: TabBar(
                        controller: _tabCtrl,
                        indicator: BoxDecoration(color: _kPurple, borderRadius: BorderRadius.circular(10)),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: _kTextSec,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        dividerColor: Colors.transparent,
                        tabs: const [Tab(text: 'Semua'), Tab(text: 'Pemasukan'), Tab(text: 'Pengeluaran')],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kPurple))
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildList(_semua),
                      _buildList(_pemasukan),
                      _buildList(_pengeluaran),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: () => _showForm(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kPurple, Color(0xFF9D94F5)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: _kPurple.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text('Tambah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.receipt_long_rounded, size: 40, color: _kTextMuted),
            ),
            const SizedBox(height: 16),
            const Text('Belum ada transaksi',
                style: TextStyle(color: _kTextSec, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    // Group by tanggal
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final t in data) {
      final tgl = t['tanggal'] as String;
      grouped.putIfAbsent(tgl, () => []).add(t);
    }
    final keys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: keys.length,
      itemBuilder: (_, i) {
        final key = keys[i];
        final items = grouped[key]!;
        final tgl = DateTime.parse(key);
        final totalHari = items
            .where((t) => t['jenis'] == 'pengeluaran')
            .fold(0.0, (s, t) => s + (t['jumlah'] as num).toDouble());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Row(
                children: [
                  Text(
                    DateFormat('dd MMM yyyy', 'id_ID').format(tgl).toUpperCase(),
                    style: const TextStyle(
                        color: _kTextSec, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                  const Spacer(),
                  if (totalHari > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: _kRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('-${_fRp(totalHari)}',
                          style: const TextStyle(
                              color: _kRed, fontWeight: FontWeight.w700, fontSize: 11)),
                    ),
                ],
              ),
            ),
            ...items.map((t) => _buildItem(t)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildItem(Map<String, dynamic> t) {
    final isPemasukan = t['jenis'] == 'pemasukan';
    final colorInt = int.tryParse(t['kategori_warna'] as String? ?? '0xFF7B6FF0') ?? 0xFF7B6FF0;
    final warna = Color(colorInt);

    return GestureDetector(
      onLongPress: () => _showItemMenu(t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
                  borderRadius: BorderRadius.circular(14)),
              child: Center(
                child: Text(t['kategori_ikon'] as String? ?? '📦',
                    style: const TextStyle(fontSize: 22)),
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
              ]),
            ),
            Text(
              '${isPemasukan ? '+' : '-'}${_fRp((t['jumlah'] as num).toDouble())}',
              style: TextStyle(
                  color: isPemasukan ? _kTeal : _kRed,
                  fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemMenu(Map<String, dynamic> t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: _kPurple),
              title: const Text('Edit Transaksi', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); _showForm(existing: t); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: _kRed),
              title: const Text('Hapus Transaksi', style: TextStyle(color: _kRed)),
              onTap: () { Navigator.pop(context); _delete(t['id'] as int); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ===== MONTH PICKER =====
class _MonthPicker extends StatelessWidget {
  final DateTime date;
  final Function(DateTime) onChanged;
  const _MonthPicker({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          initialDatePickerMode: DatePickerMode.year,
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(primary: _kPurple, surface: _kSurface),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _kPurple.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPurple.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: _kPurple, size: 16),
            const SizedBox(width: 6),
            Text(DateFormat('MMM yyyy', 'id_ID').format(date),
                style: const TextStyle(
                    color: _kPurple, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ===== FORM TRANSAKSI =====
class _TransaksiForm extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;
  const _TransaksiForm({required this.userId, this.existing, required this.onSaved});

  @override
  State<_TransaksiForm> createState() => _TransaksiFormState();
}

class _TransaksiFormState extends State<_TransaksiForm> {
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
    if (widget.existing != null) {
      final e = widget.existing!;
      _jenis = e['jenis'] as String;
      _jumlahCtrl.text = (e['jumlah'] as num).toInt().toString();
      _catatanCtrl.text = e['catatan'] as String? ?? '';
      _tanggal = DateTime.parse(e['tanggal'] as String);
      _kategoriId = e['kategori_id'] as int?;
    }
    _loadKategori();
  }

  Future<void> _loadKategori() async {
    final list = await DatabaseHelper.instance.getKategori(widget.userId, jenis: _jenis);
    if (mounted) setState(() { _kategori = list; });
  }

  Future<void> _save() async {
    final jumlah = double.tryParse(_jumlahCtrl.text.replaceAll('.', '').replaceAll(',', ''));
    if (jumlah == null || jumlah <= 0 || _kategoriId == null) return;
    setState(() => _loading = true);
    final data = {
      'user_id': widget.userId,
      'kategori_id': _kategoriId,
      'jumlah': jumlah,
      'jenis': _jenis,
      'catatan': _catatanCtrl.text,
      'tanggal': DateFormat('yyyy-MM-dd').format(_tanggal),
      'created_at': DateTime.now().toIso8601String(),
    };
    if (widget.existing != null) {
      await DatabaseHelper.instance.updateTransaksi(widget.existing!['id'] as int, data);
    } else {
      await DatabaseHelper.instance.insertTransaksi(data);
    }
    setState(() => _loading = false);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
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
          Text(isEdit ? 'Edit Transaksi' : 'Tambah Transaksi',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.all(4),
            child: Row(children: [
              _Toggle('pengeluaran', 'Pengeluaran', _jenis, () {
                setState(() { _jenis = 'pengeluaran'; _kategoriId = null; }); _loadKategori();
              }),
              _Toggle('pemasukan', 'Pemasukan', _jenis, () {
                setState(() { _jenis = 'pemasukan'; _kategoriId = null; }); _loadKategori();
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
                  data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.dark(primary: _kPurple, surface: _kSurface)),
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
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isEdit ? 'Simpan Perubahan' : 'Simpan Transaksi',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}