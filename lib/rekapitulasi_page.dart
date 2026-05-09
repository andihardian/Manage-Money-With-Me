import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
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

class RekapitulasiPage extends StatefulWidget {
  final int userId;
  const RekapitulasiPage({super.key, required this.userId});

  @override
  State<RekapitulasiPage> createState() => _RekapitulasiPageState();
}

class _RekapitulasiPageState extends State<RekapitulasiPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic> _ringkasan = {'pemasukan': 0.0, 'pengeluaran': 0.0};
  List<Map<String, dynamic>> _perKategoriKeluar = [];
  List<Map<String, dynamic>> _perKategoriMasuk = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final ringkasan = await DatabaseHelper.instance.getRingkasan(
      widget.userId,
      bulan: _selectedDate.month.toString(),
      tahun: _selectedDate.year.toString(),
    );
    final db = await DatabaseHelper.instance.database;
    final bulan = _selectedDate.month.toString().padLeft(2, '0');
    final tahun = _selectedDate.year.toString();

    final keluar = await db.rawQuery('''
      SELECT kategori.nama, kategori.ikon, kategori.warna,
             COALESCE(SUM(transaksi.jumlah), 0) as total
      FROM transaksi
      LEFT JOIN kategori ON transaksi.kategori_id = kategori.id
      WHERE transaksi.user_id = ? AND transaksi.jenis = 'pengeluaran'
      AND strftime('%m', tanggal) = ? AND strftime('%Y', tanggal) = ?
      GROUP BY transaksi.kategori_id ORDER BY total DESC
    ''', [widget.userId, bulan, tahun]);

    final masuk = await db.rawQuery('''
      SELECT kategori.nama, kategori.ikon, kategori.warna,
             COALESCE(SUM(transaksi.jumlah), 0) as total
      FROM transaksi
      LEFT JOIN kategori ON transaksi.kategori_id = kategori.id
      WHERE transaksi.user_id = ? AND transaksi.jenis = 'pemasukan'
      AND strftime('%m', tanggal) = ? AND strftime('%Y', tanggal) = ?
      GROUP BY transaksi.kategori_id ORDER BY total DESC
    ''', [widget.userId, bulan, tahun]);

    if (mounted) {
      setState(() {
        _ringkasan = ringkasan;
        _perKategoriKeluar = List<Map<String, dynamic>>.from(keluar);
        _perKategoriMasuk = List<Map<String, dynamic>>.from(masuk);
        _loading = false;
      });
    }
  }

  String _fRp(double v) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // Header
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
                        const Text('Rekapitulasi',
                            style: TextStyle(
                                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        _MonthPicker(date: _selectedDate, onChanged: (d) {
                          setState(() => _selectedDate = d);
                          _loadData();
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_loading) _buildSummaryRow(),
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
                        tabs: const [
                          Tab(text: 'Pengeluaran'),
                          Tab(text: 'Pemasukan'),
                        ],
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
                      _buildKategoriTab(_perKategoriKeluar, 'pengeluaran'),
                      _buildKategoriTab(_perKategoriMasuk, 'pemasukan'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    final pemasukan = (_ringkasan['pemasukan'] as num).toDouble();
    final pengeluaran = (_ringkasan['pengeluaran'] as num).toDouble();
    final saldo = pemasukan - pengeluaran;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _StatChip('Pemasukan', pemasukan, _kTeal),
          const SizedBox(width: 8),
          _StatChip('Pengeluaran', pengeluaran, _kRed),
          const SizedBox(width: 8),
          _StatChip('Saldo', saldo, saldo >= 0 ? _kPurple : Colors.orange),
        ],
      ),
    );
  }

  Widget _buildKategoriTab(List<Map<String, dynamic>> data, String jenis) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.bar_chart_rounded, size: 40, color: _kTextMuted),
            ),
            const SizedBox(height: 16),
            Text('Belum ada data $jenis',
                style: const TextStyle(color: _kTextSec, fontSize: 14)),
          ],
        ),
      );
    }

    final total = data.fold<double>(0, (s, d) => s + (d['total'] as num).toDouble());

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        _buildPieChart(data, total),
        const SizedBox(height: 20),
        const Text('Per Kategori',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 12),
        ...data.map((d) => _buildKategoriBar(d, total)),
      ],
    );
  }

  Widget _buildPieChart(List<Map<String, dynamic>> data, double total) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: data.take(6).map((d) {
                  final colorInt = int.tryParse(d['warna'] as String? ?? '0xFF7B6FF0') ?? 0xFF7B6FF0;
                  final pct = total > 0 ? (d['total'] as num) / total * 100 : 0.0;
                  return PieChartSectionData(
                    value: (d['total'] as num).toDouble(),
                    color: Color(colorInt),
                    title: '${pct.toStringAsFixed(0)}%',
                    radius: 72,
                    titleStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.take(5).map((d) {
              final colorInt = int.tryParse(d['warna'] as String? ?? '0xFF7B6FF0') ?? 0xFF7B6FF0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                          color: Color(colorInt), borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${d['ikon']} ${d['nama']}',
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildKategoriBar(Map<String, dynamic> d, double total) {
    final colorInt = int.tryParse(d['warna'] as String? ?? '0xFF7B6FF0') ?? 0xFF7B6FF0;
    final warna = Color(colorInt);
    final pct = total > 0 ? (d['total'] as num) / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: warna.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text(d['ikon'] as String, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(d['nama'] as String,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              Text(_fRp((d['total'] as num).toDouble()),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.toDouble(),
              backgroundColor: _kSurfaceHigh,
              valueColor: AlwaysStoppedAnimation<Color>(warna),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${(pct * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                    fontSize: 11, color: _kTextSec, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: _kTextSec, fontSize: 10)),
            const SizedBox(height: 4),
            Text(
              NumberFormat.compact(locale: 'id_ID').format(value),
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

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
                colorScheme: const ColorScheme.dark(primary: _kPurple, surface: _kSurface)),
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