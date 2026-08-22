import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/pustaka.dart';
import '../../data/providers.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/states.dart';
import 'admin_shell.dart';

/// Admin: the knowledge base.
///
/// Add a document, set its review status, ask for it to be reindexed.
///
/// The reindex button does not reindex. It flags the row and says so - the
/// embedding call needs an API key and CLAUDE.md rule 4 keeps those off the
/// client entirely, so `scripts/index_corpus.py` does the work on its next run.
/// A spinner here would be a lie about where the work happens.
class PengetahuanScreen extends ConsumerWidget {
  const PengetahuanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dokumen = ref.watch(dokumenAdminProvider);
    final antrean = ref.watch(antreanIndeksProvider);

    return AdminShell(
      current: AdminTab.pengetahuan,
      title: S.titlePengetahuan,
      child: dokumen.when(
        loading: () => const LoadingText(),
        error: (e, _) => ErrorState(
          message: pesanKesalahan(e),
          onRetry: () => ref.invalidate(dokumenAdminProvider),
        ),
        data: (daftar) => ListView(
          padding: const EdgeInsets.all(DekapSpace.screenPadding),
          children: [
            antrean.maybeWhen(
              data: (n) => Text(
                n == 0
                    ? '${daftar.length} dokumen. Tidak ada yang menunggu '
                          'indexing ulang.'
                    : '${daftar.length} dokumen. $n menunggu indexing ulang '
                          'oleh scripts/index_corpus.py.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: DekapSpace.cardGap),

            const FormDokumen(),
            const SizedBox(height: DekapSpace.screenPadding),

            if (daftar.isEmpty)
              const EmptyState(
                message:
                    'Basis pengetahuan masih kosong. Tambahkan dokumen '
                    'bersumber nyata di atas.',
              )
            else
              for (final d in daftar) ...[
                _BarisDokumen(dokumen: d),
                const SizedBox(height: DekapSpace.cardGap),
              ],
          ],
        ),
      ),
    );
  }
}

/// Public so the end-to-end test can drive it without hunting for a private
/// widget.
class FormDokumen extends ConsumerStatefulWidget {
  const FormDokumen({super.key});

  @override
  ConsumerState<FormDokumen> createState() => _FormDokumenState();
}

class _FormDokumenState extends ConsumerState<FormDokumen> {
  final _judul = TextEditingController();
  final _penerbit = TextEditingController();
  final _tahun = TextEditingController();
  final _url = TextEditingController();
  bool _sibuk = false;
  String? _kabar;

  @override
  void dispose() {
    _judul.dispose();
    _penerbit.dispose();
    _tahun.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
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
          Text('Tambah dokumen', style: text.titleMedium),
          const SizedBox(height: DekapSpace.cardGap / 2),
          Text(
            'Setiap dokumen wajib punya sumber nyata yang bisa dibuka. Tidak '
            'ada dokumen fiktif di korpus ini.',
            style: text.bodySmall,
          ),
          const SizedBox(height: DekapSpace.cardGap),

          TextField(
            controller: _judul,
            decoration: const InputDecoration(hintText: 'Judul'),
          ),
          const SizedBox(height: DekapSpace.cardGap),
          TextField(
            controller: _penerbit,
            decoration: const InputDecoration(hintText: 'Penerbit'),
          ),
          const SizedBox(height: DekapSpace.cardGap),
          TextField(
            controller: _tahun,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Tahun'),
          ),
          const SizedBox(height: DekapSpace.cardGap),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(hintText: 'URL sumber'),
          ),

          if (_kabar != null) ...[
            const SizedBox(height: DekapSpace.cardGap),
            Text(_kabar!, style: text.bodyMedium),
          ],

          const SizedBox(height: DekapSpace.cardPadding),
          PrimaryButton(
            label: _sibuk ? 'Menyimpan…' : 'Simpan dokumen',
            onPressed: _sibuk ? null : _simpan,
          ),
        ],
      ),
    );
  }

  Future<void> _simpan() async {
    final tahun = int.tryParse(_tahun.text.trim());
    final url = _url.text.trim();

    if (_judul.text.trim().isEmpty ||
        _penerbit.text.trim().isEmpty ||
        tahun == null) {
      setState(() => _kabar = 'Judul, penerbit, dan tahun belum lengkap.');
      return;
    }
    // A source that is not a real address is a fictional document with extra
    // steps, and rule 2 in CLAUDE.md rules those out.
    if (!url.startsWith('http')) {
      setState(
        () => _kabar = 'URL sumber harus alamat lengkap yang bisa dibuka.',
      );
      return;
    }

    setState(() {
      _sibuk = true;
      _kabar = null;
    });

    try {
      await ref
          .read(adminRepositoryProvider)
          .tambahDokumen(
            judul: _judul.text.trim(),
            penerbit: _penerbit.text.trim(),
            tahun: tahun,
            url: url,
          );
      if (!mounted) return;
      _judul.clear();
      _penerbit.clear();
      _tahun.clear();
      _url.clear();
      setState(() {
        _sibuk = false;
        _kabar = 'Dokumen tersimpan.';
      });
      ref
        ..invalidate(dokumenAdminProvider)
        ..invalidate(jumlahDokumenProvider);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _sibuk = false;
        _kabar = pesanKesalahan(e);
      });
    }
  }
}

class _BarisDokumen extends ConsumerWidget {
  const _BarisDokumen({required this.dokumen});

  final DokumenPustaka dokumen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DekapSpace.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dokumen.judul, style: text.titleMedium),
            Text(dokumen.sumberRingkas, style: text.bodySmall),
            const SizedBox(height: DekapSpace.cardGap),

            DropdownButtonFormField<StatusTinjauan>(
              initialValue: dokumen.status,
              // Without this the selected label lays out at its natural
              // width and overflows the field instead of ellipsizing.
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Status tinjauan'),
              items: [
                for (final s in StatusTinjauan.values)
                  DropdownMenuItem(value: s, child: Text(s.label)),
              ],
              onChanged: (s) async {
                if (s == null) return;
                await ref
                    .read(adminRepositoryProvider)
                    .ubahStatusTinjauan(dokumen.id, s);
                ref.invalidate(dokumenAdminProvider);
              },
            ),

            const SizedBox(height: DekapSpace.cardGap),
            SecondaryButton(
              label: 'Minta indexing ulang',
              icon: Symbols.refresh_rounded,
              expand: false,
              onPressed: () async {
                await ref
                    .read(adminRepositoryProvider)
                    .mintaIndeksUlang(dokumen.id);
                ref.invalidate(antreanIndeksProvider);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Dokumen masuk antrean. Indexing dijalankan oleh '
                      'scripts/index_corpus.py, bukan oleh aplikasi ini.',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
