import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/profesional_admin.dart';
import '../../data/providers.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/states.dart';
import 'admin_shell.dart';

/// Admin: the community moderation queue.
///
/// Two outcomes, and both are real decisions. "Turunkan" takes the post down;
/// "Biarkan tampil" closes the report and leaves the post published. The second
/// one is the whole reason a person looks at all - the word filter in
/// `penapis_kata.dart` catches phrases, and a phrase is not a verdict.
class ModerasiScreen extends ConsumerWidget {
  const ModerasiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final antrean = ref.watch(antreanModerasiProvider);

    return AdminShell(
      current: AdminTab.moderasi,
      title: S.titleModerasi,
      child: antrean.when(
        loading: () => const LoadingText(),
        error: (e, _) => ErrorState(
          message: pesanKesalahan(e),
          onRetry: () => ref.invalidate(antreanModerasiProvider),
        ),
        data: (daftar) => daftar.isEmpty
            ? const EmptyState(
                message:
                    'Tidak ada laporan yang menunggu. Laporan dari pengguna '
                    'dan tulisan yang tertahan penapis muncul di sini.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(DekapSpace.screenPadding),
                itemCount: daftar.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: DekapSpace.cardGap),
                itemBuilder: (_, i) => _KartuLaporan(laporan: daftar[i]),
              ),
      ),
    );
  }
}

class _KartuLaporan extends ConsumerStatefulWidget {
  const _KartuLaporan({required this.laporan});

  final LaporanPenyalahgunaan laporan;

  @override
  ConsumerState<_KartuLaporan> createState() => _KartuLaporanState();
}

class _KartuLaporanState extends ConsumerState<_KartuLaporan> {
  bool _sibuk = false;
  String? _kabar;

  @override
  Widget build(BuildContext context) {
    final l = widget.laporan;
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DekapSpace.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.kategoriLabel, style: text.titleMedium),
            Text(
              l.postinganId != null
                  ? 'Pada sebuah postingan'
                  : 'Pada sebuah balasan',
              style: text.bodySmall,
            ),
            if (l.dibuatPada != null)
              Text(
                DateFormat('d MMM y, HH.mm', 'id_ID').format(l.dibuatPada!),
                style: text.bodySmall,
              ),

            if (l.frasa != null && l.frasa!.isNotEmpty) ...[
              const SizedBox(height: DekapSpace.cardGap),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(DekapSpace.cardGap),
                decoration: BoxDecoration(
                  color: DekapColors.background,
                  borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
                ),
                child: Text(
                  // The matched phrase, so a false positive can be traced back
                  // to the rule that raised it rather than argued about.
                  'Frasa yang tertangkap penapis: "${l.frasa}"',
                  style: text.bodySmall,
                ),
              ),
            ],

            if (l.catatan != null && l.catatan!.isNotEmpty) ...[
              const SizedBox(height: DekapSpace.cardGap),
              Text(l.catatan!, style: text.bodySmall),
            ],

            if (_kabar != null) ...[
              const SizedBox(height: DekapSpace.cardGap),
              Text(_kabar!, style: text.bodyMedium),
            ],

            const SizedBox(height: DekapSpace.cardPadding),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Turunkan',
                    onPressed: _sibuk
                        ? null
                        : () => _jalankan(
                            () => ref
                                .read(adminRepositoryProvider)
                                .tindakLaporan(l),
                          ),
                  ),
                ),
                const SizedBox(width: DekapSpace.cardGap),
                Expanded(
                  child: SecondaryButton(
                    label: 'Biarkan tampil',
                    onPressed: _sibuk
                        ? null
                        : () => _jalankan(
                            () => ref
                                .read(adminRepositoryProvider)
                                .tolakLaporan(l.id),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _jalankan(Future<void> Function() aksi) async {
    setState(() {
      _sibuk = true;
      _kabar = null;
    });
    try {
      await aksi();
      if (!mounted) return;
      ref.invalidate(antreanModerasiProvider);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _sibuk = false;
        _kabar = pesanKesalahan(e);
      });
    }
  }
}
