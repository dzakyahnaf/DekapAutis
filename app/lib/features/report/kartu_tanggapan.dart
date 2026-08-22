import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/models/profesional_admin.dart';
import '../../data/providers.dart';
import '../../domain/adaptasi/saran_profesional.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/states.dart';

/// A professional's response, on the caregiver's report screen.
///
/// This is where the loop in Gambar 7.1 closes in front of the person it is
/// about. The response arrives, the caregiver reads it, and only then does
/// anything move - the button is the point, and nothing happens without it.
class KartuTanggapan extends ConsumerStatefulWidget {
  const KartuTanggapan({
    required this.tanggapan,
    required this.profilAnakId,
    super.key,
  });

  final TanggapanProfesional tanggapan;
  final String profilAnakId;

  @override
  ConsumerState<KartuTanggapan> createState() => _KartuTanggapanState();
}

class _KartuTanggapanState extends ConsumerState<KartuTanggapan> {
  bool _sibuk = false;
  String? _kabar;

  @override
  Widget build(BuildContext context) {
    final t = widget.tanggapan;
    final text = Theme.of(context).textTheme;
    final sudahDitindak =
        t.status == StatusTanggapan.diterapkan ||
        t.status == StatusTanggapan.ditolak;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DekapSpace.cardPadding),
      decoration: BoxDecoration(
        // Cream: this came from a person, not from the engine.
        color: DekapColors.cream50,
        borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
        border: Border.all(
          color: DekapColors.border,
          width: DekapSpace.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tanggapan tenaga profesional', style: text.titleMedium),
          const SizedBox(height: DekapSpace.cardGap),
          Text(t.isi, style: text.bodyMedium),

          if (t.punyaSaran) ...[
            const SizedBox(height: DekapSpace.cardPadding),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DekapSpace.cardGap),
              decoration: BoxDecoration(
                color: DekapColors.surface,
                borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saran untuk rencana', style: text.labelLarge),
                  const SizedBox(height: 4),
                  for (final k in t.saranKategori)
                    Text(
                      'Tambah satu sesi ${k.label.toLowerCase()} per minggu',
                      style: text.bodySmall,
                    ),
                  if (t.saranDurasiMenit != null)
                    Text(
                      'Panjang sesi menjadi ${t.saranDurasiMenit} menit',
                      style: text.bodySmall,
                    ),
                  const SizedBox(height: DekapSpace.cardGap / 2),
                  Text(
                    'Panjang sesi berubah pada aktivitas yang belum lewat. '
                    'Penambahan sesi berlaku saat rencana minggu depan '
                    'disusun.',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ],

          if (_kabar != null) ...[
            const SizedBox(height: DekapSpace.cardGap),
            Text(_kabar!, style: text.bodyMedium),
          ],

          const SizedBox(height: DekapSpace.cardPadding),
          if (sudahDitindak)
            Text(t.status.label, style: text.labelSmall)
          else if (!t.punyaSaran)
            SecondaryButton(
              label: 'Tandai sudah dibaca',
              onPressed: _sibuk ? null : _tolak,
            )
          else
            Column(
              children: [
                PrimaryButton(
                  label: _sibuk ? 'Menerapkan…' : 'Terapkan saran ke rencana',
                  onPressed: _sibuk ? null : _terapkan,
                ),
                const SizedBox(height: DekapSpace.cardGap),
                SecondaryButton(
                  label: 'Tidak sekarang',
                  onPressed: _sibuk ? null : _tolak,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _terapkan() async {
    setState(() {
      _sibuk = true;
      _kabar = null;
    });

    try {
      final repo = ref.read(penerapanSaranRepositoryProvider);
      final rencana = await repo.rencanaAktif(widget.profilAnakId);

      if (rencana == null) {
        if (!mounted) return;
        setState(() {
          _sibuk = false;
          _kabar =
              'Belum ada rencana aktif untuk diterapkan. Susun rencana minggu '
              'ini terlebih dahulu.';
        });
        return;
      }

      final hasil = await repo.terapkan(
        tanggapanId: widget.tanggapan.id,
        rencana: rencana,
        saran: SaranProfesional(
          tanggapanId: widget.tanggapan.id,
          kategoriDitekankan: widget.tanggapan.saranKategori.toSet(),
          durasiMenit: widget.tanggapan.saranDurasiMenit,
        ),
      );

      if (!mounted) return;
      setState(() {
        _sibuk = false;
        _kabar = hasil.adaPerubahan
            ? '${hasil.log.length} penyesuaian tercatat. Alasannya bisa Anda '
                  'baca di layar Rencana.'
            // Nothing moved because the plan already did what was suggested.
            // Saying so is better than a success message that changed nothing.
            : 'Rencana Anda sudah sesuai dengan saran ini, jadi tidak ada '
                  'yang perlu diubah.';
      });
      ref.invalidate(
        tanggapanUntukPengasuhProvider(widget.tanggapan.laporanId),
      );
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _sibuk = false;
        _kabar = pesanKesalahan(e);
      });
    }
  }

  Future<void> _tolak() async {
    setState(() => _sibuk = true);
    try {
      await ref
          .read(penerapanSaranRepositoryProvider)
          .tolak(widget.tanggapan.id);
      if (!mounted) return;
      ref.invalidate(
        tanggapanUntukPengasuhProvider(widget.tanggapan.laporanId),
      );
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _sibuk = false;
        _kabar = pesanKesalahan(e);
      });
    }
  }
}

/// Every response on the child's most recent report.
///
/// Renders nothing at all when there are none - an empty "Tanggapan" heading on
/// a report nobody has answered yet reads as something having gone missing.
class DaftarTanggapan extends ConsumerWidget {
  const DaftarTanggapan({required this.profilAnakId, super.key});

  final String profilAnakId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laporanId = ref.watch(laporanTerakhirProvider(profilAnakId)).value;
    if (laporanId == null) return const SizedBox.shrink();

    final tanggapan = ref.watch(tanggapanUntukPengasuhProvider(laporanId));

    return tanggapan.maybeWhen(
      data: (daftar) => daftar.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: DekapSpace.screenPadding),
                Text(
                  'Tanggapan tenaga profesional',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: DekapSpace.cardGap),
                for (final t in daftar) ...[
                  KartuTanggapan(tanggapan: t, profilAnakId: profilAnakId),
                  const SizedBox(height: DekapSpace.cardGap),
                ],
              ],
            ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
