import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/tokens.dart';
import '../../data/models/profesional_admin.dart';
import '../../data/providers.dart';
import '../../domain/adaptasi/kategori.dart';
import '../../domain/adaptasi/saran_profesional.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/states.dart';

/// One shared report, read-only, plus the response form.
///
/// The response has two halves and the screen keeps them visibly separate: what
/// the professional wants to say, and what they want the plan to do. Only the
/// second half can move a number, and the caregiver still has to apply it.
class DetailLaporanProfesionalScreen extends ConsumerWidget {
  const DetailLaporanProfesionalScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laporan = ref.watch(laporanMasukProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan yang dibagikan')),
      body: SafeArea(
        top: false,
        child: laporan.when(
          loading: () => const LoadingText(),
          error: (e, _) => ErrorState(
            message: pesanKesalahan(e),
            onRetry: () => ref.invalidate(laporanMasukProvider(id)),
          ),
          data: (l) => l == null
              ? EmptyState(
                  message:
                      'Laporan ini tidak lagi dapat Anda buka. Pengasuh '
                      'mungkin sudah mencabut izin berbaginya.',
                  actionLabel: 'Kembali ke kotak masuk',
                  onAction: () => context.go('/profesional/masuk-kotak'),
                )
              : _Isi(laporan: l),
        ),
      ),
    );
  }
}

class _Isi extends ConsumerWidget {
  const _Isi({required this.laporan});

  final LaporanMasuk laporan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final format = DateFormat('d MMM y', 'id_ID');
    final tanggapan = ref.watch(tanggapanProvider(laporan.id));

    return ListView(
      padding: const EdgeInsets.all(DekapSpace.screenPadding),
      children: [
        Text(
          laporan.namaAnak == null
              ? 'Laporan perkembangan'
              : '${laporan.namaAnak}'
                    '${laporan.usiaAnak == null ? '' : ', ${laporan.usiaAnak} tahun'}',
          style: text.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          '${format.format(laporan.periodeMulai)} - '
          '${format.format(laporan.periodeSelesai)}',
          style: text.bodySmall,
        ),

        const SizedBox(height: DekapSpace.cardGap),
        Container(
          padding: const EdgeInsets.all(DekapSpace.cardPadding),
          decoration: BoxDecoration(
            color: DekapColors.cream50,
            borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
            border: Border.all(
              color: DekapColors.border,
              width: DekapSpace.borderWidth,
            ),
          ),
          child: Text(
            'Dokumen ini disusun dari catatan pengasuh, bukan hasil '
            'pemeriksaan klinis.',
            style: text.bodySmall,
          ),
        ),

        if (laporan.perluPerhatian) ...[
          const SizedBox(height: DekapSpace.cardGap),
          Text(
            'Ditandai perlu diperhatikan: '
            '${laporan.kategoriPerhatian.map((k) => k.label).join(', ')}',
            style: text.bodyMedium,
          ),
        ],

        const SizedBox(height: DekapSpace.screenPadding),
        Text('Ringkasan', style: text.titleMedium),
        const SizedBox(height: DekapSpace.cardGap / 2),
        Text(laporan.ringkasan, style: text.bodyMedium),

        const SizedBox(height: DekapSpace.screenPadding),
        Text('Tanggapan', style: text.titleMedium),
        const SizedBox(height: DekapSpace.cardGap),

        tanggapan.when(
          loading: () => const LoadingText(),
          error: (e, _) => ErrorState(message: pesanKesalahan(e)),
          data: (daftar) => Column(
            children: [
              for (final t in daftar) ...[
                _TanggapanTerkirim(tanggapan: t),
                const SizedBox(height: DekapSpace.cardGap),
              ],
              FormTanggapan(laporanId: laporan.id),
            ],
          ),
        ),
      ],
    );
  }
}

class _TanggapanTerkirim extends StatelessWidget {
  const _TanggapanTerkirim({required this.tanggapan});

  final TanggapanProfesional tanggapan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tanggapan.isi, style: text.bodyMedium),
          if (tanggapan.punyaSaran) ...[
            const SizedBox(height: DekapSpace.cardGap),
            Text(
              'Saran untuk rencana: '
              '${[if (tanggapan.saranKategori.isNotEmpty) 'tambah porsi ${tanggapan.saranKategori.map((k) => k.label.toLowerCase()).join(', ')}', if (tanggapan.saranDurasiMenit != null) 'sesi ${tanggapan.saranDurasiMenit} menit'].join('; ')}',
              style: text.bodySmall,
            ),
          ],
          const SizedBox(height: DekapSpace.cardGap / 2),
          Text(tanggapan.status.label, style: text.labelSmall),
        ],
      ),
    );
  }
}

/// The response form. Public so the end-to-end test can drive it directly.
class FormTanggapan extends ConsumerStatefulWidget {
  const FormTanggapan({required this.laporanId, super.key});

  final String laporanId;

  @override
  ConsumerState<FormTanggapan> createState() => _FormTanggapanState();
}

class _FormTanggapanState extends ConsumerState<FormTanggapan> {
  final _isi = TextEditingController();
  final _kategori = <Kategori>{};
  int? _durasi;
  bool _sibuk = false;
  String? _kabar;

  @override
  void dispose() {
    _isi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _isi,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Tulis tanggapan Anda untuk pengasuh',
          ),
        ),
        const SizedBox(height: DekapSpace.screenPadding),

        Text('Saran untuk rencana (opsional)', style: text.titleMedium),
        const SizedBox(height: DekapSpace.cardGap / 2),
        Text(
          'Bagian ini yang dapat mengubah rencana, dan hanya setelah pengasuh '
          'menyetujuinya. Tulisan di atas tidak pernah dibaca mesin.',
          style: text.bodySmall,
        ),
        const SizedBox(height: DekapSpace.cardGap),

        Wrap(
          spacing: DekapSpace.cardGap / 1.5,
          runSpacing: DekapSpace.cardGap / 1.5,
          children: [
            for (final k in Kategori.values)
              FilterChip(
                label: Text('Tambah ${k.label.toLowerCase()}'),
                selected: _kategori.contains(k),
                showCheckmark: false,
                backgroundColor: DekapColors.surface,
                selectedColor: DekapColors.purple100,
                side: BorderSide(
                  color: _kategori.contains(k)
                      ? DekapColors.purple700
                      : DekapColors.border,
                  width: DekapSpace.borderWidth,
                ),
                labelStyle: text.labelSmall,
                padding: const EdgeInsets.symmetric(
                  horizontal: DekapSpace.cardGap,
                  vertical: DekapSpace.cardGap,
                ),
                onSelected: (pilih) => setState(
                  () => pilih ? _kategori.add(k) : _kategori.remove(k),
                ),
              ),
          ],
        ),
        const SizedBox(height: DekapSpace.cardGap),

        DropdownButtonFormField<int?>(
          initialValue: _durasi,
          decoration: const InputDecoration(labelText: 'Saran panjang sesi'),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Biarkan apa adanya'),
            ),
            for (final m in [
              minDurasiSaran,
              10,
              15,
              20,
              30,
              45,
              maksDurasiSaran,
            ])
              DropdownMenuItem(value: m, child: Text('$m menit')),
          ],
          onChanged: (v) => setState(() => _durasi = v),
        ),

        if (_kabar != null) ...[
          const SizedBox(height: DekapSpace.cardGap),
          Text(_kabar!, style: text.bodyMedium),
        ],

        const SizedBox(height: DekapSpace.cardPadding),
        PrimaryButton(
          label: _sibuk ? 'Mengirim…' : 'Kirim tanggapan',
          onPressed: _sibuk ? null : _kirim,
        ),
      ],
    );
  }

  Future<void> _kirim() async {
    if (_isi.text.trim().isEmpty) {
      setState(() => _kabar = 'Tanggapan belum diisi.');
      return;
    }

    setState(() {
      _sibuk = true;
      _kabar = null;
    });

    try {
      await ref
          .read(profesionalRepositoryProvider)
          .tanggapi(
            laporanId: widget.laporanId,
            isi: _isi.text.trim(),
            saranKategori: _kategori,
            saranDurasiMenit: _durasi,
            // Idempotent: a retry lands on the same row rather than sending
            // the caregiver a second notification about one opinion.
            klienId: const Uuid().v4(),
          );
      if (!mounted) return;

      _isi.clear();
      setState(() {
        _sibuk = false;
        _kategori.clear();
        _durasi = null;
        _kabar = 'Tanggapan terkirim. Pengasuh menerima pemberitahuan.';
      });
      ref
        ..invalidate(tanggapanProvider(widget.laporanId))
        ..invalidate(kotakMasukProvider);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _sibuk = false;
        _kabar = pesanKesalahan(e);
      });
    }
  }
}
