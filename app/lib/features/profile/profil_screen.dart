import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/profil_anak.dart';
import '../../data/providers.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/calm_mode_switch.dart';
import '../../shared/widgets/states.dart';

/// L.16 - Profil dan Privasi.
///
/// The privacy section is not a footnote here. Downloading a copy of everything
/// and deleting the account outright are promises made in Bab 4.3, so they sit
/// as plain, reachable rows rather than behind a submenu.
class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authRepositoryProvider);
    final anak = ref.watch(daftarAnakProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.titleProfil),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: DekapSpace.screenPadding),
            child: Center(child: CalmModePill()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(DekapSpace.screenPadding),
        children: [
          Text(auth.pengguna?.email ?? 'Belum masuk', style: text.titleMedium),
          if (ref.watch(adalahDemoProvider).value ?? false) ...[
            const SizedBox(height: DekapSpace.cardGap),
            const KepingAkunDemo(),
          ],
          const SizedBox(height: DekapSpace.screenPadding),

          _Judul('Profil anak'),
          anak.when(
            loading: () => const LoadingText(),
            error: (_, _) => const ErrorState(message: S.gagalLayanan),
            data: (daftar) => Column(
              children: [
                if (daftar.isEmpty)
                  const EmptyState(
                    message:
                        'Belum ada profil anak. Tambahkan satu untuk mulai '
                        'menyusun rencana harian.',
                  ),
                for (final a in daftar) _BarisAnak(profil: a),
                const SizedBox(height: DekapSpace.cardGap),
                SecondaryButton(
                  label: 'Tambah profil anak',
                  icon: Symbols.add_rounded,
                  onPressed: () => context.go('/onboarding/1'),
                ),
              ],
            ),
          ),

          const SizedBox(height: DekapSpace.screenPadding),
          _Judul('Laporan'),
          _Baris(
            ikon: Symbols.description_rounded,
            label: 'Laporan perkembangan',
            onTap: () => context.go('/profil/laporan'),
          ),

          const SizedBox(height: DekapSpace.screenPadding),
          _Judul('Privasi data'),
          _Baris(
            ikon: Symbols.handshake_rounded,
            label: 'Kelola izin berbagi data',
            onTap: () => context.go('/profil/izin'),
          ),
          _Baris(
            ikon: Symbols.download_rounded,
            label: 'Unduh salinan data saya',
            onTap: () => _unduhSalinan(context, ref),
          ),
          _Baris(
            ikon: Symbols.delete_rounded,
            label: 'Hapus akun dan seluruh data',
            berbahaya: true,
            onTap: () => _konfirmasiHapus(context, ref),
          ),

          const SizedBox(height: DekapSpace.screenPadding),
          _Judul('Aplikasi'),
          _Baris(
            ikon: Symbols.accessibility_new_rounded,
            label: S.titleAksesibilitas,
            onTap: () => context.go('/profil/aksesibilitas'),
          ),
          _Baris(
            ikon: Symbols.notifications_rounded,
            label: 'Notifikasi',
            onTap: () => context.go('/notifikasi'),
          ),
          _Baris(
            ikon: Symbols.menu_book_rounded,
            label: 'Cara pakai',
            onTap: () => context.go('/profil/cara-pakai'),
          ),

          const SizedBox(height: DekapSpace.screenPadding),
          SecondaryButton(
            label: 'Keluar',
            onPressed: () async {
              await ref.read(authRepositoryProvider).keluar();
              if (context.mounted) context.go('/masuk');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _unduhSalinan(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final json = await ref.read(akunRepositoryProvider).unduhSalinanData();
      final dir = await getTemporaryDirectory();
      final berkas = File(
        '${dir.path}/dekapautis-salinan-data-'
        '${DateTime.now().toIso8601String().split('T').first}.json',
      );
      await berkas.writeAsString(json);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(berkas.path)],
          text: 'Salinan data DekapAutis',
        ),
      );
    } on KesalahanAuth catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.pesan)));
    }
  }

  Future<void> _konfirmasiHapus(BuildContext context, WidgetRef ref) async {
    final terhapus = await showDialog<bool>(
      context: context,
      builder: (_) => const _DialogHapusAkun(),
    );
    if (terhapus ?? false) {
      if (!context.mounted) return;
      context.go('/masuk');
    }
  }
}

class _Judul extends StatelessWidget {
  const _Judul(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DekapSpace.cardGap),
    child: Text(teks, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _Baris extends StatelessWidget {
  const _Baris({
    required this.ikon,
    required this.label,
    required this.onTap,
    this.berbahaya = false,
  });

  final IconData ikon;
  final String label;
  final VoidCallback onTap;

  /// Destructive rows carry the darkest colour and a heavier weight. There is
  /// no red in this palette, so weight and darkness do that work instead.
  final bool berbahaya;

  @override
  Widget build(BuildContext context) {
    final warna = berbahaya ? DekapColors.boundary : DekapColors.textPrimary;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: DekapColors.surface,
        borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
          child: Container(
            constraints: const BoxConstraints(minHeight: DekapSpace.minTouch),
            margin: const EdgeInsets.only(bottom: DekapSpace.cardGap / 1.5),
            padding: const EdgeInsets.all(DekapSpace.cardPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
              border: Border.all(
                color: berbahaya ? DekapColors.boundary : DekapColors.border,
                width: DekapSpace.borderWidth,
              ),
            ),
            child: Row(
              children: [
                Icon(ikon, size: DekapSpace.iconSize, color: warna),
                const SizedBox(width: DekapSpace.cardGap),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: warna,
                      fontWeight: berbahaya
                          ? DekapType.weightSemiBold
                          : DekapType.weightRegular,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarisAnak extends StatelessWidget {
  const _BarisAnak({required this.profil});

  final ProfilAnak profil;

  @override
  Widget build(BuildContext context) => _Baris(
    ikon: Symbols.person_rounded,
    label: '${profil.namaPanggilan}, ${profil.usia} tahun',
    onTap: () => context.go('/profil/anak/${profil.id}'),
  );
}

/// Deletion needs a typed confirmation, because it cannot be undone and the
/// data it removes cannot be recovered from anywhere else.
class _DialogHapusAkun extends ConsumerStatefulWidget {
  const _DialogHapusAkun();

  static const frasa = 'HAPUS';

  @override
  ConsumerState<_DialogHapusAkun> createState() => _DialogHapusAkunState();
}

class _DialogHapusAkunState extends ConsumerState<_DialogHapusAkun> {
  final _ketik = TextEditingController();
  bool _sibuk = false;
  String? _kesalahan;

  @override
  void dispose() {
    _ketik.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cocok = _ketik.text.trim() == _DialogHapusAkun.frasa;

    return AlertDialog(
      backgroundColor: DekapColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
        side: const BorderSide(
          color: DekapColors.boundary,
          width: DekapSpace.boundaryBorderWidth,
        ),
      ),
      title: Text(
        'Hapus akun dan seluruh data',
        style: text.titleMedium?.copyWith(
          fontWeight: DekapType.weightBold,
          color: DekapColors.boundary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profil anak, seluruh catatan respons, laporan, dan izin berbagi '
            'akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: DekapSpace.cardPadding),
          Text(
            'Ketik ${_DialogHapusAkun.frasa} untuk melanjutkan.',
            style: text.bodySmall,
          ),
          const SizedBox(height: DekapSpace.cardGap / 2),
          TextField(
            controller: _ketik,
            autocorrect: false,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'HAPUS'),
          ),
          if (_kesalahan != null) ...[
            const SizedBox(height: DekapSpace.cardGap),
            Text(
              _kesalahan!,
              style: text.bodyMedium?.copyWith(color: DekapColors.boundary),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _sibuk ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: _sibuk || !cocok ? null : _hapus,
          child: Text(
            _sibuk ? 'Menghapus…' : 'Hapus permanen',
            style: TextStyle(
              color: _sibuk || !cocok
                  ? DekapColors.textSecondary
                  : DekapColors.boundary,
              fontWeight: DekapType.weightSemiBold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _hapus() async {
    setState(() {
      _sibuk = true;
      _kesalahan = null;
    });
    try {
      await ref.read(akunRepositoryProvider).hapusAkunPermanen();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on KesalahanAuth catch (e) {
      if (!mounted) return;
      setState(() {
        _sibuk = false;
        _kesalahan = e.pesan;
      });
    }
  }
}

/// Marks a seeded account as synthetic, on screen, where the person using it
/// can see it. Rina Kartika and Bima are personas; a judge who mistakes their
/// four weeks of records for a real family's has been misled.
class KepingAkunDemo extends StatelessWidget {
  const KepingAkunDemo({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DekapSpace.cardGap,
      vertical: DekapSpace.cardGap / 2,
    ),
    decoration: BoxDecoration(
      color: DekapColors.cream200,
      borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Symbols.science_rounded,
          size: DekapSpace.iconSize - 8,
          color: DekapColors.cream700,
        ),
        const SizedBox(width: 4),
        Text(
          'Akun demo - data sintetis',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    ),
  );
}
