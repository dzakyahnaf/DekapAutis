import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/jawaban_asisten.dart';
import '../../data/providers.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/calm_mode_switch.dart';
import '../../shared/widgets/safety_banner.dart';
import '../../shared/widgets/source_chip.dart';
import '../../shared/widgets/states.dart';

/// Calls the `ask` Edge Function. All three boundary layers live server-side;
/// this only renders what came back.
class AsistenRepository {
  AsistenRepository(this._client);

  final SupabaseClient _client;

  Future<JawabanAsisten> tanya(String pertanyaan) async {
    final res = await _client.functions.invoke(
      'ask',
      body: {'pertanyaan': pertanyaan},
    );
    return JawabanAsisten.fromMap(Map<String, dynamic>.from(res.data as Map));
  }
}

final asistenRepositoryProvider = Provider<AsistenRepository>(
  (ref) => AsistenRepository(ref.watch(supabaseClientProvider)),
);

/// L.3 - Tanya Dekap.
///
/// The medical boundary is not an error state here. When it fires, the screen
/// shows the notice as the answer, because refusing and pointing somewhere
/// useful *is* the product working. It is also the most valuable thirty seconds
/// of the demo: a health assistant that declines to diagnose and hands you a
/// directory instead is a maturity most student projects never reach.
class TanyaScreen extends ConsumerStatefulWidget {
  const TanyaScreen({super.key});

  @override
  ConsumerState<TanyaScreen> createState() => _TanyaScreenState();
}

class _TanyaScreenState extends ConsumerState<TanyaScreen> {
  final _input = TextEditingController();
  final _gulir = ScrollController();
  final _percakapan = <PesanPercakapan>[];
  bool _menyusun = false;
  String? _kesalahan;

  @override
  void dispose() {
    _input.dispose();
    _gulir.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.titleTanya),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: DekapSpace.screenPadding),
            child: Center(child: CalmModePill()),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _percakapan.isEmpty && !_menyusun
                  ? const EmptyState(
                      message:
                          'Tanyakan apa saja tentang rutinitas, komunikasi, '
                          'atau kenyamanan anak Anda. Setiap jawaban disertai '
                          'sumber yang bisa Anda buka sendiri.',
                    )
                  : ListView.separated(
                      controller: _gulir,
                      padding: const EdgeInsets.all(DekapSpace.screenPadding),
                      itemCount: _percakapan.length + (_menyusun ? 1 : 0),
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: DekapSpace.cardPadding),
                      itemBuilder: (context, i) {
                        if (i >= _percakapan.length) {
                          // Static text, never a spinner or a shimmer.
                          return const LoadingText(message: S.memuatJawaban);
                        }
                        final pesan = _percakapan[i];
                        return pesan.dariPengguna
                            ? _GelembungPengguna(teks: pesan.teks)
                            : _Jawaban(jawaban: pesan.jawaban!);
                      },
                    ),
            ),
            if (_kesalahan != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DekapSpace.screenPadding,
                ),
                child: Text(
                  _kesalahan!,
                  style: text.bodyMedium?.copyWith(color: DekapColors.boundary),
                ),
              ),
            _Input(pengendali: _input, aktif: !_menyusun, onKirim: _kirim),
          ],
        ),
      ),
    );
  }

  Future<void> _kirim() async {
    final pertanyaan = _input.text.trim();
    if (pertanyaan.isEmpty || _menyusun) return;

    setState(() {
      _percakapan.add(PesanPercakapan.pengguna(pertanyaan));
      _menyusun = true;
      _kesalahan = null;
      _input.clear();
    });
    _keBawah();

    try {
      final jawaban = await ref
          .read(asistenRepositoryProvider)
          .tanya(pertanyaan);
      if (!mounted) return;
      setState(() {
        _percakapan.add(PesanPercakapan.asisten(jawaban));
        _menyusun = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _menyusun = false;
        _kesalahan =
            'Jawaban belum dapat disusun. Periksa koneksi Anda, lalu kirim '
            'pertanyaannya lagi. Pertanyaan Anda tidak hilang.';
      });
    }
    _keBawah();
  }

  void _keBawah() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_gulir.hasClients) return;
      _gulir.jumpTo(_gulir.position.maxScrollExtent);
    });
  }
}

class _GelembungPengguna extends StatelessWidget {
  const _GelembungPengguna({required this.teks});

  final String teks;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.82,
      ),
      padding: const EdgeInsets.all(DekapSpace.cardPadding),
      decoration: BoxDecoration(
        color: DekapColors.purple100,
        borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
      ),
      // textPrimary on purple100 is 8.4:1. textSecondary would be 4.09 and is
      // banned on this field for exactly that reason.
      child: Text(teks, style: Theme.of(context).textTheme.bodyLarge),
    ),
  );
}

class _Jawaban extends StatelessWidget {
  const _Jawaban({required this.jawaban});

  final JawabanAsisten jawaban;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    // L.5. Shown inline as the answer, not as a dialog to dismiss.
    if (jawaban.jenis == JenisJawaban.batasAman && jawaban.batas != null) {
      final batas = jawaban.batas!;
      return SafetyBanner(
        title: batas.judul,
        body: batas.isi,
        canHelpWith: batas.yangBisaDibantu,
        actions: [
          PrimaryButton(
            label: S.aksiLihatProfesional,
            icon: Symbols.stethoscope_rounded,
            onPressed: () => context.go('/direktori'),
          ),
          SecondaryButton(
            label: 'Buat laporan untuk dokter',
            icon: Symbols.description_rounded,
            onPressed: () => context.go('/profil/laporan'),
          ),
        ],
      );
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: DekapColors.purple700, width: 4),
        ),
      ),
      padding: const EdgeInsets.only(left: DekapSpace.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (jawaban.modeTerbatas) ...[
            const _PitaModeTerbatas(),
            const SizedBox(height: DekapSpace.cardGap),
          ],
          if (jawaban.teks.isNotEmpty)
            Text(jawaban.teks, style: text.bodyLarge),
          if (jawaban.sumber.isNotEmpty) ...[
            const SizedBox(height: DekapSpace.cardGap),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Sumber', style: text.bodySmall),
                for (final s in jawaban.sumber)
                  SourceChip(
                    number: s.nomor,
                    onOpen: () => _bukaPanel(context, jawaban),
                  ),
              ],
            ),
          ],
          const SizedBox(height: DekapSpace.cardGap / 2),
          Text(S.batasCatatanKaki, style: text.bodySmall),
        ],
      ),
    );
  }

  void _bukaPanel(BuildContext context, JawabanAsisten jawaban) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DekapColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DekapSpace.radiusCard),
        ),
      ),
      builder: (_) => PanelSumber(jawaban: jawaban),
    );
  }
}

class _PitaModeTerbatas extends StatelessWidget {
  const _PitaModeTerbatas();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DekapSpace.cardGap),
    decoration: BoxDecoration(
      color: DekapColors.cream200,
      borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Symbols.cloud_off_rounded,
          size: DekapSpace.iconSize - 4,
          color: DekapColors.cream700,
        ),
        const SizedBox(width: DekapSpace.cardGap),
        Expanded(
          child: Text(
            'Sumber ditampilkan tanpa rangkuman. Layanan sedang terbatas.',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    ),
  );
}

/// L.4 - Panel Sumber.
class PanelSumber extends StatelessWidget {
  const PanelSumber({required this.jawaban, super.key});

  final JawabanAsisten jawaban;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, gulir) => ListView(
        controller: gulir,
        padding: const EdgeInsets.all(DekapSpace.screenPadding),
        children: [
          Row(
            children: [
              Expanded(child: Text(S.titleSumber, style: text.titleLarge)),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Symbols.close_rounded),
                tooltip: S.aksiTutup,
              ),
            ],
          ),
          const SizedBox(height: DekapSpace.cardPadding),
          for (final s in jawaban.sumber) ...[
            _KartuSumber(sumber: s),
            const SizedBox(height: DekapSpace.cardPadding),
          ],
          const Divider(),
          const SizedBox(height: DekapSpace.cardGap),
          // The number comes from COUNT(*) in the database. The mockup said 148,
          // which is not a figure we can stand behind, and the wording says what
          // is actually true: these are official sources the reader can open, not
          // documents a professional reviewed for us.
          Text(
            'DekapAutis menjawab dari ${jawaban.jumlahDokumen} dokumen sumber '
            'resmi yang dapat Anda buka sendiri.',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _KartuSumber extends StatelessWidget {
  const _KartuSumber({required this.sumber});

  final SumberJawaban sumber;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: DekapColors.purple100,
                  borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
                ),
                child: Text(
                  '${sumber.nomor}',
                  style: text.labelSmall?.copyWith(
                    fontFamily: DekapType.familyMono,
                  ),
                ),
              ),
              const SizedBox(width: DekapSpace.cardGap),
              Expanded(child: Text(sumber.judul, style: text.titleMedium)),
            ],
          ),
          const SizedBox(height: DekapSpace.cardGap / 2),
          Text(sumber.meta, style: text.bodySmall),
          const SizedBox(height: DekapSpace.cardGap),
          Container(
            padding: const EdgeInsets.only(left: DekapSpace.cardPadding),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: DekapColors.border,
                  width: DekapSpace.focusWidth,
                ),
              ),
            ),
            child: Text(
              sumber.kutipan,
              style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: DekapSpace.cardGap),
          SecondaryButton(
            label: S.aksiBukaSumber,
            icon: Symbols.open_in_new_rounded,
            expand: false,
            onPressed: () => launchUrl(
              Uri.parse(sumber.url),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.pengendali,
    required this.aktif,
    required this.onKirim,
  });

  final TextEditingController pengendali;
  final bool aktif;
  final VoidCallback onKirim;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      DekapSpace.screenPadding,
      DekapSpace.cardGap,
      DekapSpace.screenPadding,
      DekapSpace.cardGap + MediaQuery.of(context).padding.bottom,
    ),
    decoration: const BoxDecoration(
      color: DekapColors.surface,
      border: Border(
        top: BorderSide(
          color: DekapColors.border,
          width: DekapSpace.borderWidth,
        ),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: pengendali,
            enabled: aktif,
            maxLines: 3,
            minLines: 1,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onKirim(),
            decoration: const InputDecoration(
              hintText: 'Tulis pertanyaan Anda',
            ),
          ),
        ),
        const SizedBox(width: DekapSpace.cardGap),
        SizedBox(
          width: DekapSpace.buttonHeight,
          height: DekapSpace.buttonHeight,
          child: Semantics(
            button: true,
            label: 'Kirim pertanyaan',
            excludeSemantics: true,
            child: Material(
              color: aktif ? DekapColors.purple700 : DekapColors.border,
              borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
              child: InkWell(
                onTap: aktif ? onKirim : null,
                borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
                child: Icon(
                  Symbols.arrow_upward_rounded,
                  color: aktif
                      ? DekapColors.surface
                      : DekapColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
