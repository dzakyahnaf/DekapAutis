import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/models/profil_anak.dart';
import '../../data/providers.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/privacy_strip.dart';
import '../../shared/widgets/states.dart';

/// Editing a child profile (KF-02, reachable from L.16).
///
/// The same questions as onboarding, in one screen rather than four: someone
/// correcting an age does not need to be walked through a wizard again.
class SuntingAnakScreen extends ConsumerStatefulWidget {
  const SuntingAnakScreen({required this.id, super.key});

  final String id;

  @override
  ConsumerState<SuntingAnakScreen> createState() => _SuntingAnakScreenState();
}

class _SuntingAnakScreenState extends ConsumerState<SuntingAnakScreen> {
  ProfilAnak? _asli;
  late String _nama;
  late int? _usia;
  late KemampuanKomunikasi _komunikasi;
  late Set<SensitivitasSensorik> _sensorik;
  late Set<FokusPerkembangan> _fokus;
  bool _sibuk = false;
  String? _kesalahan;

  void _muat(ProfilAnak p) {
    _asli = p;
    _nama = p.namaPanggilan;
    _usia = p.usia;
    _komunikasi = p.kemampuanKomunikasi;
    _sensorik = {...p.sensitivitasSensorik};
    _fokus = {...p.fokusPerkembangan};
  }

  @override
  Widget build(BuildContext context) {
    final daftar = ref.watch(daftarAnakProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sunting profil anak')),
      body: daftar.when(
        loading: () => const LoadingText(),
        error: (_, _) => const ErrorState(
          message:
              'Profil anak belum dapat dimuat. Periksa koneksi Anda, '
              'lalu coba lagi.',
        ),
        data: (list) {
          final profil = list.where((p) => p.id == widget.id).firstOrNull;
          if (profil == null) {
            return const EmptyState(
              message: 'Profil anak ini sudah tidak ada.',
            );
          }
          if (_asli?.id != profil.id) _muat(profil);
          return _form(context);
        },
      ),
    );
  }

  Widget _form(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final valid =
        _nama.trim().isNotEmpty && _usia != null && _usia! >= 1 && _usia! <= 18;

    return ListView(
      padding: const EdgeInsets.all(DekapSpace.screenPadding),
      children: [
        Text('Nama panggilan', style: text.bodyLarge),
        const SizedBox(height: DekapSpace.cardGap / 2),
        TextFormField(
          initialValue: _nama,
          onChanged: (v) => setState(() => _nama = v),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: DekapSpace.cardPadding),

        Text('Usia', style: text.bodyLarge),
        const SizedBox(height: DekapSpace.cardGap / 2),
        TextFormField(
          initialValue: _usia?.toString() ?? '',
          keyboardType: TextInputType.number,
          onChanged: (v) => setState(() => _usia = int.tryParse(v.trim())),
        ),
        const SizedBox(height: DekapSpace.cardPadding),

        Text('Cara anak berkomunikasi', style: text.titleMedium),
        const SizedBox(height: DekapSpace.cardGap),
        for (final k in KemampuanKomunikasi.values) ...[
          OptionTile(
            label: k.label,
            terpilih: _komunikasi == k,
            onTap: () => setState(() => _komunikasi = k),
          ),
          const SizedBox(height: DekapSpace.cardGap / 1.5),
        ],

        const SizedBox(height: DekapSpace.cardPadding),
        Text('Sensitivitas sensorik', style: text.titleMedium),
        const SizedBox(height: DekapSpace.cardGap),
        Wrap(
          spacing: DekapSpace.cardGap / 1.5,
          runSpacing: DekapSpace.cardGap / 1.5,
          children: [
            for (final s in SensitivitasSensorik.values)
              MultiOptionChip(
                label: s.label,
                terpilih: _sensorik.contains(s),
                onTap: () => setState(
                  () => _sensorik.contains(s)
                      ? _sensorik.remove(s)
                      : _sensorik.add(s),
                ),
              ),
          ],
        ),

        const SizedBox(height: DekapSpace.cardPadding),
        Text('Fokus tiga bulan ke depan', style: text.titleMedium),
        const SizedBox(height: DekapSpace.cardGap),
        Wrap(
          spacing: DekapSpace.cardGap / 1.5,
          runSpacing: DekapSpace.cardGap / 1.5,
          children: [
            for (final f in FokusPerkembangan.values)
              MultiOptionChip(
                label: f.label,
                terpilih: _fokus.contains(f),
                onTap: () => setState(
                  () => _fokus.contains(f) ? _fokus.remove(f) : _fokus.add(f),
                ),
              ),
          ],
        ),

        if (_kesalahan != null) ...[
          const SizedBox(height: DekapSpace.cardPadding),
          Text(
            _kesalahan!,
            style: text.bodyMedium?.copyWith(color: DekapColors.boundary),
          ),
        ],

        const SizedBox(height: DekapSpace.screenPadding),
        const PrivacyStrip(),
        const SizedBox(height: DekapSpace.cardGap),
        PrimaryButton(
          label: _sibuk ? 'Menyimpan…' : 'Simpan perubahan',
          onPressed: _sibuk || !valid ? null : _simpan,
        ),
      ],
    );
  }

  Future<void> _simpan() async {
    setState(() {
      _sibuk = true;
      _kesalahan = null;
    });
    try {
      await ref
          .read(profilAnakRepositoryProvider)
          .perbarui(
            ProfilAnak(
              id: _asli!.id,
              penggunaId: _asli!.penggunaId,
              namaPanggilan: _nama.trim(),
              usia: _usia!,
              kemampuanKomunikasi: _komunikasi,
              sensitivitasSensorik: _sensorik,
              fokusPerkembangan: _fokus,
            ),
          );
      ref.invalidate(daftarAnakProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil anak diperbarui.')));
      context.go('/profil');
    } on KesalahanAuth catch (e) {
      if (!mounted) return;
      setState(() {
        _sibuk = false;
        _kesalahan = e.pesan;
      });
    }
  }
}
