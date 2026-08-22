import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/direktori.dart';
import '../../data/models/profesional_admin.dart';
import '../../data/providers.dart';
import '../../domain/direktori/kota.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/states.dart';

/// Professional onboarding and practice profile.
///
/// Submitting always returns the practice to `menunggu`. A listing that changed
/// its specialisation or address after approval has not been checked in that
/// form, and the verified badge must not carry over - KF-12 only means
/// something if it refers to what is currently on screen.
class ProfilPraktikScreen extends ConsumerWidget {
  const ProfilPraktikScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(profilPraktikProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(S.titleProfilPraktik)),
      body: SafeArea(
        top: false,
        child: profil.when(
          loading: () => const LoadingText(),
          error: (e, _) => ErrorState(
            message: pesanKesalahan(e),
            onRetry: () => ref.invalidate(profilPraktikProvider),
          ),
          data: (p) => FormProfilPraktik(awal: p),
        ),
      ),
    );
  }
}

/// Public so the end-to-end test can drive it.
class FormProfilPraktik extends ConsumerStatefulWidget {
  const FormProfilPraktik({this.awal, super.key});

  final Profesional? awal;

  @override
  ConsumerState<FormProfilPraktik> createState() => _FormProfilPraktikState();
}

class _FormProfilPraktikState extends ConsumerState<FormProfilPraktik> {
  late final TextEditingController _nama;
  late final TextEditingController _gelar;
  late final TextEditingController _spesialisasi;
  late final TextEditingController _tentang;
  late final TextEditingController _kota;
  late final TextEditingController _layanan;
  late final TextEditingController _bukti;
  late final List<JamPraktik> _jadwal;

  bool _sibuk = false;
  String? _kabar;

  @override
  void initState() {
    super.initState();
    final a = widget.awal;
    _nama = TextEditingController(text: a?.namaLengkap ?? '');
    _gelar = TextEditingController(text: a?.gelar ?? '');
    _spesialisasi = TextEditingController(text: a?.spesialisasi ?? '');
    _tentang = TextEditingController(text: a?.tentang ?? '');
    _kota = TextEditingController(text: a?.kota ?? '');
    _layanan = TextEditingController(text: a?.layanan.join(', ') ?? '');
    _bukti = TextEditingController(text: a?.buktiKredensial ?? '');
    _jadwal = [...?a?.jadwalPraktik];
  }

  @override
  void dispose() {
    for (final c in [
      _nama,
      _gelar,
      _spesialisasi,
      _tentang,
      _kota,
      _layanan,
      _bukti,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final status = ref.watch(statusVerifikasiProvider);

    return ListView(
      padding: const EdgeInsets.all(DekapSpace.screenPadding),
      children: [
        status.maybeWhen(
          data: (s) =>
              _PitaStatus(status: s, alasan: widget.awal?.alasanPenolakan),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: DekapSpace.cardGap),

        TextField(
          controller: _nama,
          decoration: const InputDecoration(
            hintText: 'Nama praktik atau nama lengkap',
          ),
        ),
        const SizedBox(height: DekapSpace.cardGap),
        TextField(
          controller: _gelar,
          decoration: const InputDecoration(hintText: 'Gelar, misalnya M.Psi.'),
        ),
        const SizedBox(height: DekapSpace.cardGap),
        TextField(
          controller: _spesialisasi,
          decoration: const InputDecoration(
            hintText: 'Spesialisasi, misalnya Terapis wicara',
          ),
        ),
        const SizedBox(height: DekapSpace.cardGap),
        TextField(
          controller: _kota,
          decoration: const InputDecoration(hintText: 'Kota'),
        ),
        const SizedBox(height: DekapSpace.cardGap),
        TextField(
          controller: _tentang,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Tentang praktik Anda'),
        ),
        const SizedBox(height: DekapSpace.cardGap),
        TextField(
          controller: _layanan,
          decoration: const InputDecoration(hintText: 'Layanan, dipisah koma'),
        ),

        const SizedBox(height: DekapSpace.screenPadding),
        Text('Jadwal praktik', style: text.titleMedium),
        const SizedBox(height: DekapSpace.cardGap / 2),
        Text(
          'Hari dan jam yang dapat dipilih pengasuh saat mengajukan jadwal.',
          style: text.bodySmall,
        ),
        const SizedBox(height: DekapSpace.cardGap),
        for (var i = 0; i < _jadwal.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: DekapSpace.cardGap),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_jadwal[i].hari}, ${_jadwal[i].jam}',
                    style: text.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _jadwal.removeAt(i)),
                  child: const Text('Hapus'),
                ),
              ],
            ),
          ),
        SecondaryButton(
          label: 'Tambah hari praktik',
          expand: false,
          onPressed: _tambahJadwal,
        ),

        const SizedBox(height: DekapSpace.screenPadding),
        Text('Bukti kredensial', style: text.titleMedium),
        const SizedBox(height: DekapSpace.cardGap / 2),
        Text(
          'Nomor Surat Tanda Registrasi atau tautan ke profil resmi lembaga. '
          'Administrator memeriksanya sebelum lencana Terverifikasi menyala.',
          style: text.bodySmall,
        ),
        const SizedBox(height: DekapSpace.cardGap),
        TextField(
          controller: _bukti,
          decoration: const InputDecoration(hintText: 'Nomor STR atau tautan'),
        ),

        if (_kabar != null) ...[
          const SizedBox(height: DekapSpace.cardGap),
          Text(_kabar!, style: text.bodyMedium),
        ],

        const SizedBox(height: DekapSpace.cardPadding),
        PrimaryButton(
          label: _sibuk ? 'Mengirim…' : 'Kirim untuk ditinjau',
          onPressed: _sibuk ? null : _simpan,
        ),
        const SizedBox(height: DekapSpace.cardGap),
        SecondaryButton(
          label: 'Kembali ke kotak masuk',
          onPressed: () => context.go('/profesional/masuk-kotak'),
        ),
      ],
    );
  }

  Future<void> _tambahJadwal() async {
    final hari = <String>['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final dipilih = await showModalBottomSheet<JamPraktik>(
      context: context,
      backgroundColor: DekapColors.surface,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(DekapSpace.screenPadding),
          children: [
            for (final h in hari)
              for (final j in ['09.00-11.00', '13.00-15.00', '15.00-17.00'])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  minTileHeight: DekapSpace.minTouch,
                  title: Text('$h, $j'),
                  onTap: () =>
                      Navigator.of(sheet).pop(JamPraktik(hari: h, jam: j)),
                ),
          ],
        ),
      ),
    );
    if (dipilih != null) setState(() => _jadwal.add(dipilih));
  }

  Future<void> _simpan() async {
    if (_nama.text.trim().isEmpty || _spesialisasi.text.trim().isEmpty) {
      setState(() => _kabar = 'Nama dan spesialisasi belum diisi.');
      return;
    }
    if (_bukti.text.trim().isEmpty) {
      setState(
        () => _kabar =
            'Bukti kredensial belum diisi. Tanpa itu administrator tidak '
            'punya dasar untuk menyalakan lencana Terverifikasi.',
      );
      return;
    }

    setState(() {
      _sibuk = true;
      _kabar = null;
    });

    // Coordinates come from the same city table L.9 measures distances with,
    // so a practice does not have to know its own latitude.
    final titik = koordinatKota(_kota.text);

    try {
      await ref
          .read(profesionalRepositoryProvider)
          .simpanProfil(
            namaLengkap: _nama.text.trim(),
            spesialisasi: _spesialisasi.text.trim(),
            gelar: _gelar.text.trim().isEmpty ? null : _gelar.text.trim(),
            tentang: _tentang.text.trim().isEmpty ? null : _tentang.text.trim(),
            layanan: [
              for (final l in _layanan.text.split(','))
                if (l.trim().isNotEmpty) l.trim(),
            ],
            jadwalPraktik: _jadwal,
            kota: _kota.text.trim().isEmpty ? null : _kota.text.trim(),
            lat: titik?.lintang,
            lng: titik?.bujur,
            buktiKredensial: _bukti.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _sibuk = false;
        _kabar =
            'Profil terkirim dan menunggu peninjauan administrator. Anda '
            'tampil di direktori setelah disetujui.';
      });
      ref
        ..invalidate(profilPraktikProvider)
        ..invalidate(statusVerifikasiProvider);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _sibuk = false;
        _kabar = pesanKesalahan(e);
      });
    }
  }
}

class _PitaStatus extends StatelessWidget {
  const _PitaStatus({required this.status, this.alasan});

  final StatusVerifikasi status;
  final String? alasan;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(DekapSpace.cardPadding),
    decoration: BoxDecoration(
      color: status == StatusVerifikasi.disetujui
          ? DekapColors.purple100
          : DekapColors.cream200,
      borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
    ),
    child: Text(switch (status) {
      StatusVerifikasi.disetujui =>
        'Profil Anda sudah disetujui dan tampil di direktori. Mengubah dan '
            'mengirim ulang akan mengembalikannya ke antrean peninjauan.',
      StatusVerifikasi.menunggu =>
        'Profil Anda sedang menunggu peninjauan administrator.',
      StatusVerifikasi.ditolak =>
        'Profil Anda belum lolos peninjauan. '
            '${alasan ?? 'Alasan tidak tercatat.'}',
    }, style: Theme.of(context).textTheme.bodySmall),
  );
}
