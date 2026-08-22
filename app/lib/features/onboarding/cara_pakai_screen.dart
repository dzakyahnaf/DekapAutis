import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../shared/widgets/buttons.dart';
import 'tur_pertama.dart';

/// The six-step flow from Bab IX, in the app.
///
/// docs/05 says plainly that this is what a judge reads when they get stuck, so
/// each step links to the screen it describes rather than only describing it.
/// A page that explains where to go, on a screen you have to leave to get
/// there, is half a page.
const _langkah = <_Langkah>[
  _Langkah(
    nomor: 1,
    judul: 'Kenali anak Anda',
    isi:
        'Isi profil singkat: usia, cara anak berkomunikasi hari ini, dan hal '
        'yang membuatnya tidak nyaman. Ini bukan penilaian, hanya titik awal '
        'agar rencananya masuk akal.',
    tujuan: '/onboarding/1',
    labelTujuan: 'Buka profil anak',
    ikon: Symbols.person_rounded,
  ),
  _Langkah(
    nomor: 2,
    judul: 'Terima rencana mingguan',
    isi:
        'DekapAutis menyusun rencana stimulasi satu minggu dari katalog '
        'aktivitas. Pemilihan aktivitasnya mengikuti aturan, bukan tebakan '
        'model bahasa.',
    tujuan: '/rencana',
    labelTujuan: 'Buka rencana',
    ikon: Symbols.calendar_month_rounded,
  ),
  _Langkah(
    nomor: 3,
    judul: 'Jalankan dan catat responsnya',
    isi:
        'Setiap aktivitas punya panduan langkah. Setelah selesai, tandai '
        'Mudah, Pas, atau Sulit. Mencatat "belum mau" juga membantu.',
    tujuan: '/beranda',
    labelTujuan: 'Buka beranda',
    ikon: Symbols.edit_note_rounded,
  ),
  _Langkah(
    nomor: 4,
    judul: 'Rencana menyesuaikan diri',
    isi:
        'Dari catatan Anda, rencana minggu berikutnya berubah sendiri. Setiap '
        'perubahan disertai alasan yang menyebut angka nyata, bukan kalimat '
        'umum.',
    tujuan: '/rencana',
    labelTujuan: 'Lihat alasan penyesuaian',
    ikon: Symbols.tune_rounded,
  ),
  _Langkah(
    nomor: 5,
    judul: 'Bertanya kapan saja',
    isi:
        'Tanya Dekap menjawab dari dokumen yang dapat Anda buka sendiri. Ia '
        'tidak mendiagnosis, tidak menilai tingkat spektrum, dan tidak '
        'menganjurkan obat.',
    tujuan: '/tanya',
    labelTujuan: 'Buka Tanya Dekap',
    ikon: Symbols.chat_bubble_rounded,
  ),
  _Langkah(
    nomor: 6,
    judul: 'Bagikan laporan ke tenaga profesional',
    isi:
        'Menjelang jadwal terapi, susun laporan perkembangan dan bagikan ke '
        'profesional pilihan Anda. Izinnya bisa dicabut kapan saja, dan '
        'pencabutan benar-benar memutus akses.',
    tujuan: '/profil/laporan',
    labelTujuan: 'Buka laporan',
    ikon: Symbols.description_rounded,
  ),
];

class CaraPakaiScreen extends ConsumerWidget {
  const CaraPakaiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text(S.titleCaraPakai)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(DekapSpace.screenPadding),
          children: [
            Text(
              'Enam langkah, dari mengenal anak sampai berbagi laporan.',
              style: text.bodyLarge,
            ),
            const SizedBox(height: DekapSpace.screenPadding),

            for (final l in _langkah) ...[
              _KartuLangkah(langkah: l),
              const SizedBox(height: DekapSpace.cardGap),
            ],

            const SizedBox(height: DekapSpace.cardPadding),
            SecondaryButton(
              label: 'Ulangi tur pertama kali',
              icon: Symbols.replay_rounded,
              onPressed: () async {
                await ulangiTur(ref.read(databaseProvider));
                ref.invalidate(turSudahDilihatProvider);
                if (!context.mounted) return;
                context.go('/beranda');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Langkah {
  const _Langkah({
    required this.nomor,
    required this.judul,
    required this.isi,
    required this.tujuan,
    required this.labelTujuan,
    required this.ikon,
  });

  final int nomor;
  final String judul;
  final String isi;
  final String tujuan;
  final String labelTujuan;
  final IconData ikon;
}

class _KartuLangkah extends StatelessWidget {
  const _KartuLangkah({required this.langkah});

  final _Langkah langkah;

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
                width: DekapSpace.minTouch,
                height: DekapSpace.minTouch,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DekapColors.purple100,
                  borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
                ),
                child: Icon(langkah.ikon, color: DekapColors.purple700),
              ),
              const SizedBox(width: DekapSpace.cardGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The number is written out, not only drawn as a chip:
                    // "Langkah 3" read aloud is clearer than a bare "3".
                    Text('Langkah ${langkah.nomor}', style: text.labelSmall),
                    Text(langkah.judul, style: text.titleMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DekapSpace.cardGap),
          Text(langkah.isi, style: text.bodyMedium),
          const SizedBox(height: DekapSpace.cardGap),
          Align(
            alignment: Alignment.centerLeft,
            child: SecondaryButton(
              label: langkah.labelTujuan,
              expand: false,
              onPressed: () => context.go(langkah.tujuan),
            ),
          ),
        ],
      ),
    );
  }
}
