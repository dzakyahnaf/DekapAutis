import 'dart:io';
import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/laporan_repository.dart';
import '../../domain/laporan/metrik_laporan.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/calm_mode_switch.dart';
import '../../shared/widgets/states.dart';
import 'kartu_tanggapan.dart';
import 'laporan_pdf.dart';

final periodeLaporanProvider = StateProvider<PeriodeLaporan>(
  (ref) => PeriodeLaporan.satuBulan,
);

final metrikLaporanProvider = FutureProvider<MetrikLaporan?>((ref) async {
  final anak = await ref.watch(anakAktifProvider.future);
  if (anak == null) return null;
  return ref
      .watch(laporanRepositoryProvider)
      .hitung(
        profilAnakId: anak.id,
        periode: ref.watch(periodeLaporanProvider),
      );
});

/// L.8 - Laporan Perkembangan.
///
/// Every number here is computed in Dart before anything else touches it. What
/// the chart draws, what the table says and what the narrative claims are the
/// same figures, which is the only reason the narrative can be verified at all.
class LaporanScreen extends ConsumerStatefulWidget {
  const LaporanScreen({super.key});

  @override
  ConsumerState<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends ConsumerState<LaporanScreen> {
  String? _ringkasan;
  bool _sibuk = false;
  String? _kesalahan;

  @override
  Widget build(BuildContext context) {
    final metrik = ref.watch(metrikLaporanProvider);
    final anak = ref.watch(anakAktifProvider).value;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.titleLaporan),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: DekapSpace.screenPadding),
            child: Center(child: CalmModePill()),
          ),
        ],
      ),
      body: metrik.when(
        loading: () => const LoadingText(),
        error: (_, _) => const ErrorState(message: S.gagalLayanan),
        data: (m) {
          if (m == null || anak == null) {
            return const EmptyState(
              message:
                  'Belum ada profil anak. Tambahkan satu untuk mulai menyusun '
                  'laporan.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(DekapSpace.screenPadding),
            children: [
              Text(
                '${anak.namaPanggilan}, ${anak.usia} tahun',
                style: text.titleMedium,
              ),
              Text(
                '${DateFormat('d MMM', 'id_ID').format(m.periodeMulai)} - '
                '${DateFormat('d MMM y', 'id_ID').format(m.periodeSelesai)}',
                style: text.bodySmall,
              ),
              const SizedBox(height: DekapSpace.cardPadding),

              _PemilihPeriode(),
              const SizedBox(height: DekapSpace.screenPadding),

              Row(
                children: [
                  _Metrik(
                    label: 'Terjadwal',
                    nilai: '${m.aktivitasTerjadwal}',
                    satuan: 'aktivitas',
                  ),
                  _Metrik(
                    label: 'Tercatat',
                    nilai: '${m.persenTercatat}',
                    satuan: '% dari rencana',
                  ),
                  _Metrik(
                    label: 'Rata-rata',
                    nilai: m.rataSesiHarian
                        .toStringAsFixed(1)
                        .replaceAll('.', ','),
                    satuan: 'sesi per hari',
                  ),
                ],
              ),
              const SizedBox(height: DekapSpace.cardGap / 2),
              // Said plainly, because the same three numbers on a health screen
              // are otherwise read as being about the child.
              Text(
                'Angka di atas menggambarkan pelaksanaan rencana di rumah, '
                'bukan capaian anak.',
                style: text.bodySmall,
              ),

              const SizedBox(height: DekapSpace.screenPadding),
              Text('Respons Mudah per minggu', style: text.titleMedium),
              const SizedBox(height: DekapSpace.cardGap),
              if (m.trenMingguan.length < 2)
                const EmptyState(
                  message:
                      'Belum cukup minggu tercatat untuk menggambar tren. '
                      'Catat satu aktivitas untuk mulai melihat polanya.',
                )
              else
                GrafikTren(tren: m.trenMingguan),

              const SizedBox(height: DekapSpace.screenPadding),
              Text('Rincian per kategori', style: text.titleMedium),
              const SizedBox(height: DekapSpace.cardGap),
              if (m.perKategori.isEmpty)
                const EmptyState(message: S.kosongCatatan)
              else
                for (final k in m.perKategori)
                  _BarisKategori(
                    rincian: k,
                    ditandai: m.penandaPerhatian.contains(k.kategori),
                  ),

              const SizedBox(height: DekapSpace.screenPadding),
              Text('Ringkasan untuk terapis', style: text.titleMedium),
              const SizedBox(height: DekapSpace.cardGap),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(DekapSpace.cardPadding),
                decoration: BoxDecoration(
                  color: DekapColors.surface,
                  borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
                  border: Border.all(
                    color: DekapColors.border,
                    width: DekapSpace.borderWidth,
                  ),
                ),
                child: Text(
                  _ringkasan ??
                      'Ringkasan disusun saat Anda menekan tombol di bawah.',
                  style: text.bodyLarge,
                ),
              ),

              if (_kesalahan != null) ...[
                const SizedBox(height: DekapSpace.cardGap),
                Text(
                  _kesalahan!,
                  style: text.bodyMedium?.copyWith(color: DekapColors.boundary),
                ),
              ],

              // Where the loop in Gambar 7.1 closes in front of the person
              // it is about.
              DaftarTanggapan(profilAnakId: anak.id),

              const SizedBox(height: DekapSpace.screenPadding),
              PrimaryButton(
                label: _sibuk ? 'Menyusun laporan…' : S.aksiBuatLaporan,
                icon: Symbols.description_rounded,
                onPressed: _sibuk ? null : () => _buat(anak.id, m),
              ),
              const SizedBox(height: DekapSpace.cardGap),
              SecondaryButton(
                label: 'Unduh PDF',
                icon: Symbols.download_rounded,
                onPressed: _sibuk ? null : () => _unduh(m, anak.namaPanggilan),
              ),
              const SizedBox(height: DekapSpace.cardGap),
              SecondaryButton(
                label: 'Kelola izin berbagi',
                icon: Symbols.handshake_rounded,
                onPressed: () => context.go('/profil/izin'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _buat(String anakId, MetrikLaporan m) async {
    setState(() {
      _sibuk = true;
      _kesalahan = null;
    });
    try {
      final ringkasan = await ref
          .read(laporanRepositoryProvider)
          .buatLaporan(profilAnakId: anakId, metrik: m);
      if (!mounted) return;
      setState(() {
        _ringkasan = ringkasan;
        _sibuk = false;
      });
      ref.invalidate(daftarIzinProvider);
    } on KesalahanAuth catch (e) {
      if (!mounted) return;
      setState(() {
        _sibuk = false;
        _kesalahan = e.pesan;
      });
    }
  }

  Future<void> _unduh(MetrikLaporan m, String namaAnak) async {
    final messenger = ScaffoldMessenger.of(context);
    final email =
        ref.read(authRepositoryProvider).pengguna?.email ?? 'Pengasuh';
    try {
      final bytes = await susunPdfLaporan(
        metrik: m,
        namaAnak: namaAnak,
        namaPengasuh: email,
        ringkasan:
            _ringkasan ??
            'Ringkasan belum disusun. Tekan "Buat laporan" untuk menyusunnya.',
      );
      final dir = await getTemporaryDirectory();
      final berkas = File(
        '${dir.path}/laporan-dekapautis-'
        '${m.periodeSelesai.toIso8601String().split('T').first}.pdf',
      );
      await berkas.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(berkas.path)],
          text: 'Laporan perkembangan $namaAnak',
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('PDF belum dapat dibuat. Coba lagi sebentar lagi.'),
        ),
      );
    }
  }
}

class _PemilihPeriode extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terpilih = ref.watch(periodeLaporanProvider);
    return Row(
      children: [
        for (final p in PeriodeLaporan.values) ...[
          Expanded(
            child: Semantics(
              button: true,
              selected: p == terpilih,
              label: 'Periode ${p.label}',
              excludeSemantics: true,
              child: Material(
                color: p == terpilih
                    ? DekapColors.purple700
                    : DekapColors.surface,
                borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
                child: InkWell(
                  onTap: () =>
                      ref.read(periodeLaporanProvider.notifier).state = p,
                  borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: DekapSpace.minTouch,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        DekapSpace.radiusControl,
                      ),
                      border: Border.all(
                        color: p == terpilih
                            ? DekapColors.purple700
                            : DekapColors.border,
                        width: DekapSpace.borderWidth,
                      ),
                    ),
                    child: Text(
                      p.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: p == terpilih
                            ? DekapColors.surface
                            : DekapColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (p != PeriodeLaporan.values.last)
            const SizedBox(width: DekapSpace.cardGap / 1.5),
        ],
      ],
    );
  }
}

class _Metrik extends StatelessWidget {
  const _Metrik({
    required this.label,
    required this.nilai,
    required this.satuan,
  });

  final String label;
  final String nilai;
  final String satuan;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: DekapSpace.cardGap / 1.5),
      padding: const EdgeInsets.all(DekapSpace.cardGap),
      decoration: BoxDecoration(
        color: DekapColors.surface,
        borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
        border: Border.all(
          color: DekapColors.border,
          width: DekapSpace.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          // IBM Plex Mono, tabular, so columns stay aligned as values change.
          Text(nilai, style: DekapTheme.monoFigure),
          Text(satuan, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _BarisKategori extends StatelessWidget {
  const _BarisKategori({required this.rincian, required this.ditandai});

  final RincianKategori rincian;
  final bool ditandai;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final kategori = DekapCategory.fromDb(rincian.kategori.dbValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: DekapSpace.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Colour is never the only carrier: the icon and the label are
              // always there too.
              Icon(kategori.icon, size: 16, color: kategori.base),
              const SizedBox(width: DekapSpace.cardGap / 2),
              Expanded(
                child: Text(rincian.kategori.label, style: text.bodyLarge),
              ),
              if (ditandai)
                Padding(
                  padding: const EdgeInsets.only(right: DekapSpace.cardGap / 2),
                  child: Text(
                    'ditandai',
                    style: text.labelSmall?.copyWith(
                      color: DekapColors.boundary,
                      fontWeight: DekapType.weightSemiBold,
                    ),
                  ),
                ),
              Text(
                '${rincian.persenMudah}%',
                style: text.labelLarge?.copyWith(
                  fontFamily: DekapType.familyMono,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rincian.persenMudah / 100,
              minHeight: 8,
              backgroundColor: DekapColors.purple100,
              valueColor: AlwaysStoppedAnimation(kategori.base),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${rincian.jumlahTercatat} catatan, arah ${rincian.tren.label}',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Weekly trend, drawn with a CustomPainter.
///
/// No entry animation and no interpolation: the line appears at its final shape
/// on the first frame. A chart that draws itself in is a small repeating
/// movement, and this screen is often opened with the child in the room.
class GrafikTren extends StatelessWidget {
  const GrafikTren({required this.tren, super.key});

  final List<TrenMingguan> tren;

  @override
  Widget build(BuildContext context) => Semantics(
    // Spoken aloud, because a line drawn on a canvas tells a screen reader
    // nothing at all.
    label: [
      'Grafik respons Mudah per minggu.',
      for (var i = 0; i < tren.length; i++) _kalimatMinggu(i + 1, tren[i]),
    ].join(' '),
    excludeSemantics: true,
    child: Container(
      height: 190,
      padding: const EdgeInsets.all(DekapSpace.cardPadding),
      decoration: BoxDecoration(
        color: DekapColors.surface,
        borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
        border: Border.all(
          color: DekapColors.border,
          width: DekapSpace.borderWidth,
        ),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: _PelukisTren(tren: tren),
      ),
    ),
  );
}

String _kalimatMinggu(int nomor, TrenMingguan t) =>
    'Minggu $nomor: ${t.persenMudah} persen dari ${t.jumlahTercatat} catatan.';

class _PelukisTren extends CustomPainter {
  _PelukisTren({required this.tren});

  final List<TrenMingguan> tren;

  @override
  void paint(Canvas canvas, Size size) {
    const kiri = 30.0;
    const bawah = 22.0;
    final lebar = size.width - kiri;
    final tinggi = size.height - bawah;

    final garis = Paint()
      ..color = DekapColors.border
      ..strokeWidth = 1;

    // Gridlines at 0, 50 and 100 percent, each labelled. Three is enough to
    // read a value off and few enough not to clutter.
    for (final persen in [0, 50, 100]) {
      final y = tinggi - (persen / 100 * tinggi);
      canvas.drawLine(Offset(kiri, y), Offset(size.width, y), garis);
      _teks(canvas, '$persen', Offset(0, y - 6), DekapColors.textSecondary, 10);
    }

    if (tren.length < 2) return;

    final langkah = lebar / (tren.length - 1);
    final titik = [
      for (var i = 0; i < tren.length; i++)
        Offset(
          kiri + i * langkah,
          tinggi - (tren[i].persenMudah / 100 * tinggi),
        ),
    ];

    final jalur = Path()..moveTo(titik.first.dx, titik.first.dy);
    for (final t in titik.skip(1)) {
      jalur.lineTo(t.dx, t.dy);
    }
    canvas.drawPath(
      jalur,
      Paint()
        ..color = DekapColors.purple700
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < titik.length; i++) {
      canvas
        ..drawCircle(titik[i], 4, Paint()..color = DekapColors.surface)
        ..drawCircle(
          titik[i],
          4,
          Paint()
            ..color = DekapColors.purple700
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      // The value is written next to every point, so the chart never has to be
      // estimated by eye.
      _teks(
        canvas,
        '${tren[i].persenMudah}',
        titik[i] + const Offset(-8, -20),
        DekapColors.textPrimary,
        11,
      );
      _teks(
        canvas,
        'M${i + 1}',
        Offset(titik[i].dx - 8, size.height - 14),
        DekapColors.textSecondary,
        10,
      );
    }
  }

  void _teks(Canvas canvas, String s, Offset di, Color warna, double ukuran) {
    TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            color: warna,
            fontSize: ukuran,
            // Figures use IBM Plex Mono throughout the report.
            fontFamily: DekapType.familyMono,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )
      ..layout()
      ..paint(canvas, di);
  }

  @override
  bool shouldRepaint(_PelukisTren oud) => oud.tren != tren;
}
