import 'package:dekapautis/core/router/app_router.dart';
import 'package:dekapautis/data/models/profesional_admin.dart';
import 'package:dekapautis/data/models/profil_anak.dart';
import 'package:dekapautis/data/providers.dart';
import 'package:dekapautis/domain/laporan/metrik_laporan.dart';
import 'package:dekapautis/features/professional/detail_laporan_screen.dart';
import 'package:dekapautis/features/report/kartu_tanggapan.dart';
import 'package:dekapautis/features/report/laporan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';
import 'support/peladen_lingkaran.dart';

/// Gambar 7.1, end to end through the real screens.
///
/// A report leaves the caregiver, a professional answers it, and the answer
/// comes back and changes the plan. Both roles talk to one shared store, so
/// this fails if the two halves stop lining up - not just if a screen fails to
/// render.
///
/// What it covers and what it does not, stated plainly:
///
///   * Covered: the real widgets, the real router, the real
///     `terapkanSaranProfesional` arithmetic, and the handover between roles.
///   * Not covered: RLS. A fake store cannot prove the caregiver's data reaches
///     the one professional they chose and nobody else - that is what
///     `scripts/test_lingkaran_penuh.sql` is for, and it runs the same circle
///     against a real Postgres with four separate JWTs.
///
/// It lives in `test/` rather than `integration_test/` deliberately. Flutter
/// treats anything under `integration_test/` as needing a connected device, and
/// the only devices on this machine are Chrome and Edge - which would mean this
/// silently stopped running in CI. A loop test that does not run is worth less
/// than no loop test at all, because it looks like coverage.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PeladenLingkaran peladen;
  late ProfesionalPalsu profesional;
  late PenerapanPalsu penerapan;

  setUp(() {
    peladen = PeladenLingkaran(laporanId: 'lap-1', profilAnakId: 'anak-1');
    profesional = ProfesionalPalsu(peladen);
    penerapan = PenerapanPalsu(peladen);
  });

  /// The app wired to fakes, with the loop's two repositories sharing a store.
  Widget aplikasi() => aplikasiUji(
    profil: FakeProfilAnakRepository(
      awal: [
        const ProfilAnak(
          id: 'anak-1',
          penggunaId: 'pengasuh-1',
          namaPanggilan: 'Bima',
          usia: 6,
          kemampuanKomunikasi: KemampuanKomunikasi.beberapaKata,
        ),
      ],
    ),
    tambahan: [
      // The report screen computes its metrics from the server. Faked here so
      // the screen renders its content rather than its error state - the loop
      // is what is under test, not the metric arithmetic, which
      // report_metrics_test.dart already covers.
      metrikLaporanProvider.overrideWith(
        (ref) async => MetrikLaporan(
          periodeMulai: DateTime(2026, 7, 25),
          periodeSelesai: DateTime(2026, 8, 22),
          aktivitasTerjadwal: 24,
          aktivitasTercatat: 18,
          trenMingguan: const [],
          perKategori: const [],
          penandaPerhatian: const {Kategori.komunikasi},
        ),
      ),
      profesionalRepositoryProvider.overrideWithValue(profesional),
      penerapanSaranRepositoryProvider.overrideWithValue(penerapan),
      laporanTerakhirProvider.overrideWith(
        (ref, anakId) async => peladen.laporanId,
      ),
      tanggapanUntukPengasuhProvider.overrideWith(
        (ref, laporanId) => profesional.tanggapan(laporanId),
      ),
    ],
  );

  /// Brings [target] on screen, building it first if the list has not.
  ///
  /// `ListView` builds lazily, so a card below the fold does not exist yet and
  /// no finder can see it - which is why scrolling has to come before looking.
  /// The scrollable is chosen by axis rather than by index: these screens also
  /// carry horizontal strips (the period picker, the topic chips), and
  /// `.first` picked one of those.
  Future<void> gulirKe(WidgetTester tester, Finder target) async {
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      return;
    }
    final tegak = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    await tester.scrollUntilVisible(target, 300, scrollable: tegak.first);
    await tester.pumpAndSettle();
  }

  Future<void> buka(WidgetTester tester, String path) async {
    tester.view
      ..devicePixelRatio = 1.0
      ..physicalSize = const Size(390, 1200);
    addTearDown(tester.view.reset);

    appRouter.go(path);
    await tester.pumpWidget(aplikasi());
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
  }

  testWidgets('sebuah laporan mengalir penuh dan kembali mengubah rencana', (
    tester,
  ) async {
    // ---------------------------------------------------------- 1. inbox --
    await buka(tester, '/profesional/masuk-kotak');

    expect(
      find.textContaining('Bima'),
      findsWidgets,
      reason: 'laporan yang dibagikan tidak muncul di kotak masuk',
    );
    expect(
      find.textContaining('Perlu diperhatikan'),
      findsOneWidget,
      reason: 'penanda dari aturan D tidak terlihat oleh profesional',
    );

    // ------------------------------------------- 2. buka dan tulis tanggapan --
    await tester.tap(find.textContaining('Bima').first);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(find.byType(FormTanggapan), findsOneWidget);
    // The report says what it is before a professional reads a number off it.
    expect(
      find.textContaining('bukan hasil pemeriksaan klinis'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(TextField).first,
      'Pola menutup telinga di sore hari sebaiknya diamati bersama guru '
      'pendamping.',
    );

    // The structured half: one category, which is the only part that can move
    // a number.
    await tester.tap(find.text('Tambah komunikasi'));
    await tester.pumpAndSettle();

    await gulirKe(tester, find.text('Kirim tanggapan'));
    await tester.tap(find.text('Kirim tanggapan'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(peladen.tanggapan, hasLength(1));
    expect(peladen.tanggapan.single.saranKategori, [Kategori.komunikasi]);
    expect(
      peladen.notifikasi,
      contains('Tanggapan baru dari tenaga profesional'),
      reason: 'pengasuh tidak diberi tahu',
    );

    // ------------------------------------ 3. pengasuh melihat tanggapan itu --
    final sebelum = peladen.porsi[Kategori.komunikasi];
    expect(sebelum, 3);

    await buka(tester, '/profil/laporan');
    // Scroll first: the card is below the fold and a lazy ListView has not
    // built it yet, so nothing can be asserted about it until it exists.
    await gulirKe(tester, find.text('Terapkan saran ke rencana'));

    expect(
      find.byType(KartuTanggapan),
      findsOneWidget,
      reason: 'tanggapan tidak sampai ke layar pengasuh',
    );
    expect(find.textContaining('guru pendamping'), findsOneWidget);
    expect(
      find.textContaining('Tambah satu sesi komunikasi'),
      findsOneWidget,
      reason: 'saran terstruktur tidak dijelaskan ke pengasuh',
    );

    // Nothing has moved yet. The button is the point.
    expect(peladen.porsi[Kategori.komunikasi], sebelum);
    expect(peladen.log, isEmpty);

    // ------------------------------------------------ 4. pengasuh menerapkan --
    await tester.tap(find.text('Terapkan saran ke rencana'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // ------------------------------------------------ 5. lingkaran tertutup --
    expect(
      peladen.porsi[Kategori.komunikasi],
      4,
      reason: 'rencana tidak berubah setelah saran diterapkan',
    );
    expect(peladen.log, hasLength(1));

    final baris = peladen.log.single;
    expect(baris.aturanId, 'F_profesional');
    expect(baris.nilaiSebelum['porsi'], 3);
    expect(baris.nilaiSesudah['porsi'], 4);
    // The reason cites the real numbers and says a person asked - the same
    // contract the five automatic rules are held to.
    expect(baris.alasan, contains('3'));
    expect(baris.alasan, contains('4'));
    expect(baris.alasan, contains('profesional'));

    expect(peladen.tanggapan.single.status, StatusTanggapan.diterapkan);
  });

  testWidgets('menerapkan dua kali tidak menaikkan rencana dua kali', (
    tester,
  ) async {
    // A caregiver who taps twice, or comes back to a response already applied,
    // must not push the plan up again.
    peladen.tambahTanggapan(
      isi: 'Coba tambah porsi komunikasi.',
      saranKategori: [Kategori.komunikasi],
    );

    await buka(tester, '/profil/laporan');
    await gulirKe(tester, find.text('Terapkan saran ke rencana'));
    await tester.tap(find.text('Terapkan saran ke rencana'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(peladen.porsi[Kategori.komunikasi], 4);

    // The button is gone: the card now reports what happened instead.
    expect(find.text('Terapkan saran ke rencana'), findsNothing);
    expect(find.textContaining('diterapkan'), findsWidgets);
    expect(peladen.porsi[Kategori.komunikasi], 4);
    expect(peladen.log, hasLength(1));
  });

  testWidgets('pengasuh boleh menolak saran, dan rencana tidak bergerak', (
    tester,
  ) async {
    peladen.tambahTanggapan(
      isi: 'Sekadar catatan, tidak mendesak.',
      saranKategori: [Kategori.sosial],
    );

    await buka(tester, '/profil/laporan');
    await gulirKe(tester, find.text('Tidak sekarang'));
    await tester.tap(find.text('Tidak sekarang'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(peladen.porsi[Kategori.sosial], 1, reason: 'rencana ikut berubah');
    expect(peladen.log, isEmpty);
    expect(peladen.tanggapan.single.status, StatusTanggapan.ditolak);
  });
}
