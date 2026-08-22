import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/local/database.dart';
import '../../data/providers.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/step_indicator.dart';

/// The four first-run highlights (docs/07 §7).
///
/// Static, in the literal sense the design system means: no animation, no
/// pulsing target ring, no auto-advance. A repeating movement is a sensory-load
/// trigger, and the first thing a caregiver sees should not be one.
///
/// "Lewati" is visible from the first card rather than appearing at the end. A
/// skip control that only shows up once you have sat through most of the tour
/// is not a skip control.
const sorotanTur = <String>[
  'Ini rencana hari ini. Setiap aktivitas punya panduan langkahnya.',
  ('Setelah selesai, tandai responsnya. Catatan ini yang menyesuaikan '
      'rencana besok.'),
  ('Punya pertanyaan? Tanya Dekap menjawab dari dokumen yang bisa Anda buka '
      'sendiri.'),
  'Menjelang jadwal terapi, buat laporan dan bagikan ke tenaga profesional.',
];

/// Whether the tour has been seen, kept on the device.
///
/// Local rather than on the server on purpose: it is a property of this
/// installation, not of the account, and a caregiver who reinstalls has good
/// reason to see it again.
final turSudahDilihatProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.bacaPreferensi(_kunciTur) == 'ya';
});

const _kunciTur = 'tur_pertama_dilihat';

Future<void> tandaiTurDilihat(DekapDatabase db) =>
    db.simpanPreferensi(_kunciTur, 'ya');

Future<void> ulangiTur(DekapDatabase db) =>
    db.simpanPreferensi(_kunciTur, 'tidak');

/// Shown over the home screen on first run.
class TurPertama extends ConsumerStatefulWidget {
  const TurPertama({required this.onSelesai, super.key});

  final VoidCallback onSelesai;

  @override
  ConsumerState<TurPertama> createState() => _TurPertamaState();
}

class _TurPertamaState extends ConsumerState<TurPertama> {
  int _langkah = 0;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final terakhir = _langkah == sorotanTur.length - 1;

    return Material(
      // A plain scrim rather than a spotlight cut-out: a hole punched around a
      // moving target needs the target to hold still, and the home screen
      // scrolls.
      color: DekapColors.textPrimary.withValues(alpha: 0.55),
      child: SafeArea(
        // Scrollable and bottom-aligned. At 200% text the fourth highlight
        // plus two buttons is taller than a small phone, and a tour that
        // overflows on the first screen a caregiver sees is worse than no tour
        // - caught by text_scale_test.dart, not by looking.
        child: SingleChildScrollView(
          reverse: true,
          child: Padding(
            padding: const EdgeInsets.all(DekapSpace.screenPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(DekapSpace.cardPadding),
                  decoration: BoxDecoration(
                    color: DekapColors.surface,
                    borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StepIndicator(
                        langkahSaatIni: _langkah + 1,
                        totalLangkah: sorotanTur.length,
                      ),
                      const SizedBox(height: DekapSpace.cardPadding),
                      Text(sorotanTur[_langkah], style: text.bodyLarge),
                      const SizedBox(height: DekapSpace.screenPadding),
                      PrimaryButton(
                        label: terakhir ? 'Mulai memakai' : 'Berikutnya',
                        onPressed: () {
                          if (terakhir) {
                            _selesai();
                          } else {
                            setState(() => _langkah++);
                          }
                        },
                      ),
                      const SizedBox(height: DekapSpace.cardGap),
                      Center(
                        child: TextButton(
                          onPressed: _selesai,
                          child: const Text('Lewati'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selesai() async {
    await tandaiTurDilihat(ref.read(databaseProvider));
    ref.invalidate(turSudahDilihatProvider);
    widget.onSelesai();
  }
}
