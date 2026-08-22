import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/komunitas.dart';
import '../../data/providers.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/states.dart';

final topikTerpilihProvider = StateProvider<TopikKomunitas>(
  (ref) => TopikKomunitas.semua,
);

/// L.11 - the community, on the cream path.
///
/// Every author is an initial or an "Anonim" chip. There is no code here that
/// hides a name, because the server never sends one: `postingan_publik` does
/// not select the column. See migration 008.
class KomunitasScreen extends ConsumerWidget {
  const KomunitasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topik = ref.watch(topikTerpilihProvider);
    final postingan = ref.watch(postinganProvider(topik));

    return Scaffold(
      appBar: AppBar(title: const Text(S.titleKomunitas)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaPenulis(context, ref),
        backgroundColor: DekapColors.cream700,
        foregroundColor: DekapColors.surface,
        icon: const Icon(Symbols.edit_rounded),
        label: const Text('Tulis'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Only the tab switcher is pinned. The moderation strip and the
            // topic chips scroll with the list: as fixed rows they stopped
            // fitting at 200% text and squeezed the list down to nothing.
            const JelajahTabs(current: JelajahTab.komunitas),
            Expanded(
              child: postingan.when(
                loading: () => const LoadingText(),
                error: (e, _) => ErrorState(
                  message: pesanKesalahan(e),
                  onRetry: () => ref.invalidate(postinganProvider(topik)),
                ),
                data: (daftar) => ListView(
                  // Room for the floating button at the bottom.
                  padding: const EdgeInsets.only(
                    bottom: DekapSpace.screenPadding * 4,
                  ),
                  children: [
                    const _PitaModerasi(),
                    _FilterTopik(terpilih: topik),
                    if (daftar.isEmpty)
                      const EmptyState(
                        message:
                            'Belum ada diskusi di topik ini. Tulis yang '
                            'pertama - pertanyaan sederhana pun membantu '
                            'orang lain yang sedang mencari hal sama.',
                      )
                    else
                      for (final p in daftar)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            DekapSpace.screenPadding,
                            0,
                            DekapSpace.screenPadding,
                            DekapSpace.cardGap,
                          ),
                          child: KartuDiskusi(postingan: p),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bukaPenulis(BuildContext context, WidgetRef ref) async {
    final ditulis = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DekapColors.surface,
      builder: (_) => const PenulisPostingan(),
    );
    if (ditulis ?? false) {
      ref.invalidate(postinganProvider(ref.read(topikTerpilihProvider)));
    }
  }
}

/// KF-14. States who moderates, because a claim that a space is safe should
/// say who is doing the work.
class _PitaModerasi extends StatelessWidget {
  const _PitaModerasi();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: DekapSpace.screenPadding),
    padding: const EdgeInsets.all(DekapSpace.cardGap),
    decoration: BoxDecoration(
      color: DekapColors.cream50,
      borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
      border: Border.all(
        color: DekapColors.border,
        width: DekapSpace.borderWidth,
      ),
    ),
    child: Row(
      children: [
        const Icon(
          Symbols.shield_rounded,
          size: DekapSpace.iconSize - 6,
          color: DekapColors.cream700,
        ),
        const SizedBox(width: DekapSpace.cardGap / 1.5),
        Expanded(
          child: Text(
            'Dimoderasi relawan dan tenaga profesional',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    ),
  );
}

class _FilterTopik extends ConsumerWidget {
  const _FilterTopik({required this.terpilih});

  final TopikKomunitas terpilih;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(
      horizontal: DekapSpace.screenPadding,
      vertical: DekapSpace.cardGap,
    ),
    child: Row(
      children: [
        for (final t in TopikKomunitas.values) ...[
          ChoiceChip(
            label: Text(t.label),
            selected: t == terpilih,
            showCheckmark: false,
            backgroundColor: DekapColors.surface,
            selectedColor: DekapColors.cream200,
            side: BorderSide(
              color: t == terpilih ? DekapColors.cream700 : DekapColors.border,
              width: DekapSpace.borderWidth,
            ),
            labelStyle: Theme.of(context).textTheme.labelSmall,
            padding: const EdgeInsets.symmetric(
              horizontal: DekapSpace.cardGap,
              vertical: DekapSpace.cardGap,
            ),
            onSelected: (_) =>
                ref.read(topikTerpilihProvider.notifier).state = t,
          ),
          const SizedBox(width: DekapSpace.cardGap / 1.5),
        ],
      ],
    ),
  );
}

class KartuDiskusi extends StatelessWidget {
  const KartuDiskusi({required this.postingan, super.key});

  final Postingan postingan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: () => context.go('/komunitas/${postingan.id}'),
        borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(DekapSpace.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(postingan.judul, style: text.titleMedium),
              const SizedBox(height: 4),
              Text(
                postingan.isi,
                style: text.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: DekapSpace.cardGap),
              Wrap(
                spacing: DekapSpace.cardGap,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  KepingPenulis(postingan: postingan),
                  Text(
                    '${postingan.jumlahBalasan} balasan',
                    style: text.bodySmall,
                  ),
                  if (postingan.dibuatPada != null)
                    Text(
                      waktuRelatif(postingan.dibuatPada!),
                      style: text.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The author chip: initials, or the word "Anonim".
///
/// There is deliberately no branch here that reads a name and shortens it. The
/// model has no name to read.
class KepingPenulis extends StatelessWidget {
  const KepingPenulis({required this.postingan, super.key});

  final Postingan postingan;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DekapSpace.cardGap,
      vertical: 4,
    ),
    decoration: BoxDecoration(
      color: postingan.anonim ? DekapColors.background : DekapColors.cream200,
      borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
    ),
    child: Text(
      postingan.penulisTampil,
      style: Theme.of(context).textTheme.labelSmall,
    ),
  );
}

/// "3 jam lalu". Rough on purpose: an exact timestamp on a support forum
/// invites people to work out who was awake at 02.00.
String waktuRelatif(DateTime waktu, [DateTime? sekarang]) {
  final selisih = (sekarang ?? DateTime.now()).difference(waktu);
  if (selisih.inMinutes < 1) return 'baru saja';
  if (selisih.inMinutes < 60) return '${selisih.inMinutes} menit lalu';
  if (selisih.inHours < 24) return '${selisih.inHours} jam lalu';
  if (selisih.inDays < 7) return '${selisih.inDays} hari lalu';
  if (selisih.inDays < 30) return '${(selisih.inDays / 7).floor()} minggu lalu';
  return '${(selisih.inDays / 30).floor()} bulan lalu';
}

/// The compose sheet.
class PenulisPostingan extends ConsumerStatefulWidget {
  const PenulisPostingan({super.key});

  @override
  ConsumerState<PenulisPostingan> createState() => _PenulisPostinganState();
}

class _PenulisPostinganState extends ConsumerState<PenulisPostingan> {
  final _judul = TextEditingController();
  final _isi = TextEditingController();
  TopikKomunitas _topik = TopikKomunitas.rutinitas;
  bool _anonim = false;
  bool _sibuk = false;
  String? _tertahan;

  @override
  void dispose() {
    _judul.dispose();
    _isi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(DekapSpace.screenPadding),
          children: [
            Text('Tulis di komunitas', style: text.titleMedium),
            const SizedBox(height: DekapSpace.cardGap),

            TextField(
              controller: _judul,
              decoration: const InputDecoration(hintText: 'Judul singkat'),
            ),
            const SizedBox(height: DekapSpace.cardGap),
            TextField(
              controller: _isi,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Ceritakan pengalaman atau pertanyaan Anda',
              ),
            ),
            const SizedBox(height: DekapSpace.cardGap),

            DropdownButtonFormField<TopikKomunitas>(
              initialValue: _topik,
              // Without this the selected label lays out at its natural
              // width and overflows the field instead of ellipsizing.
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Topik'),
              items: [
                for (final t in TopikKomunitas.values)
                  if (t != TopikKomunitas.semua)
                    DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (v) => setState(() => _topik = v ?? _topik),
            ),
            const SizedBox(height: DekapSpace.cardGap),

            MergeSemantics(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kirim sebagai anonim', style: text.bodyMedium),
                        Text(
                          'Nama Anda tidak dikirim ke perangkat siapa pun.',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _anonim,
                    onChanged: (v) => setState(() => _anonim = v),
                  ),
                ],
              ),
            ),

            if (_tertahan != null) ...[
              const SizedBox(height: DekapSpace.cardGap),
              _Tertahan(pesan: _tertahan!),
            ],

            const SizedBox(height: DekapSpace.cardPadding),
            PrimaryButton(
              label: _sibuk ? 'Menyimpan…' : 'Kirim tulisan',
              onPressed: _sibuk ? null : _kirim,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _kirim() async {
    if (_judul.text.trim().isEmpty || _isi.text.trim().isEmpty) {
      setState(() => _tertahan = 'Judul dan isi belum diisi.');
      return;
    }

    setState(() {
      _sibuk = true;
      _tertahan = null;
    });

    try {
      final hasil = await ref
          .read(komunitasRepositoryProvider)
          .tulis(
            topik: _topik,
            judul: _judul.text.trim(),
            isi: _isi.text.trim(),
            anonim: _anonim,
          );
      if (!mounted) return;

      if (hasil.perluDitinjau) {
        // The post was stored, not discarded - it is waiting for a moderator.
        // Saying so is the difference between "we kept your words" and "your
        // words vanished".
        setState(() {
          _sibuk = false;
          _tertahan = hasil.pesan;
        });
        return;
      }
      Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _sibuk = false;
        _tertahan = pesanKesalahan(e);
      });
    }
  }
}

class _Tertahan extends StatelessWidget {
  const _Tertahan({required this.pesan});

  final String pesan;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DekapSpace.cardPadding),
    decoration: BoxDecoration(
      color: DekapColors.purple100,
      borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Symbols.info_rounded,
          size: DekapSpace.iconSize,
          color: DekapColors.purple700,
        ),
        const SizedBox(width: DekapSpace.cardGap),
        Expanded(
          child: Text(pesan, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}
