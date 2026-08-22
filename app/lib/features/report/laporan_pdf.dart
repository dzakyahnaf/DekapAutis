import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/laporan/metrik_laporan.dart';

/// The disclaimer, in full.
///
/// It is not fine print and it is not optional. This document travels to a
/// therapist who did not watch any of it happen, and the single most important
/// thing it can tell them is what kind of evidence they are holding: a parent's
/// notes about their week, not a measurement of a child.
const catatanPenyangkalan =
    'Dokumen ini disusun otomatis dari catatan harian yang diisi pengasuh di '
    'aplikasi DekapAutis. Isinya bukan hasil pemeriksaan klinis, bukan '
    'diagnosis, dan tidak menilai tingkat kemampuan anak. Angka di dalamnya '
    'menggambarkan pelaksanaan rencana harian di rumah, bukan capaian anak. '
    'Gunakan sebagai bahan diskusi bersama tenaga profesional, bukan sebagai '
    'dasar keputusan medis.';

/// Builds the A4 report (KF-11).
Future<List<int>> susunPdfLaporan({
  required MetrikLaporan metrik,
  required String namaAnak,
  required String namaPengasuh,
  required String ringkasan,
}) async {
  // The bundled family, so the PDF reads the same as the app and needs no
  // network to render.
  final biasa = pw.Font.ttf(
    await rootBundle.load('assets/fonts/LexendDeca-Regular.ttf'),
  );
  final tebal = pw.Font.ttf(
    await rootBundle.load('assets/fonts/LexendDeca-SemiBold.ttf'),
  );
  final mono = pw.Font.ttf(
    await rootBundle.load('assets/fonts/IBMPlexMono-SemiBold.ttf'),
  );

  const ungu = PdfColor.fromInt(0xFF7B4490);
  const teksUtama = PdfColor.fromInt(0xFF4A2657);
  const teksSekunder = PdfColor.fromInt(0xFF6B5F73);
  const garis = PdfColor.fromInt(0xFFD8C6E0);

  final tanggal = DateFormat('d MMMM y', 'id_ID');
  final dokumen = pw.Document();

  pw.Widget kartuMetrik(
    String label,
    String nilai,
    String satuan,
  ) => pw.Expanded(
    child: pw.Container(
      margin: const pw.EdgeInsets.only(right: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: garis),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: biasa, fontSize: 8, color: teksSekunder),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                nilai,
                style: pw.TextStyle(font: mono, fontSize: 18, color: teksUtama),
              ),
              pw.SizedBox(width: 3),
              pw.Text(
                satuan,
                style: pw.TextStyle(
                  font: biasa,
                  fontSize: 8,
                  color: teksSekunder,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  dokumen.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: (context) => pw.Column(
        children: [
          pw.Divider(color: garis, height: 12),
          pw.Text(
            catatanPenyangkalan,
            style: pw.TextStyle(font: biasa, fontSize: 7, color: teksSekunder),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: pw.TextStyle(font: biasa, fontSize: 7, color: teksSekunder),
          ),
        ],
      ),
      build: (context) => [
        // Kop.
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Laporan Perkembangan Harian',
                    style: pw.TextStyle(
                      font: tebal,
                      fontSize: 16,
                      color: teksUtama,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'DekapAutis - pendamping keluarga anak dengan spektrum autisme',
                    style: pw.TextStyle(
                      font: biasa,
                      fontSize: 9,
                      color: teksSekunder,
                    ),
                  ),
                ],
              ),
            ),
            pw.Text(
              'Dibuat ${tanggal.format(DateTime.now())}',
              style: pw.TextStyle(
                font: biasa,
                fontSize: 8,
                color: teksSekunder,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(height: 2, color: ungu),
        pw.SizedBox(height: 14),

        _baris(biasa, tebal, 'Anak', namaAnak),
        _baris(biasa, tebal, 'Diisi oleh', namaPengasuh),
        _baris(
          biasa,
          tebal,
          'Periode',
          '${tanggal.format(metrik.periodeMulai)} - '
              '${tanggal.format(metrik.periodeSelesai)} '
              '(${metrik.jumlahHari} hari)',
        ),

        pw.SizedBox(height: 16),
        pw.Text(
          'Pelaksanaan rencana',
          style: pw.TextStyle(font: tebal, fontSize: 11, color: teksUtama),
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            kartuMetrik(
              'Aktivitas terjadwal',
              '${metrik.aktivitasTerjadwal}',
              'aktivitas',
            ),
            kartuMetrik(
              'Tercatat responsnya',
              '${metrik.aktivitasTercatat}',
              '(${metrik.persenTercatat}%)',
            ),
            kartuMetrik(
              'Rata-rata harian',
              metrik.rataSesiHarian.toStringAsFixed(1).replaceAll('.', ','),
              'sesi',
            ),
          ],
        ),

        pw.SizedBox(height: 18),
        pw.Text(
          'Rincian per kategori',
          style: pw.TextStyle(font: tebal, fontSize: 11, color: teksUtama),
        ),
        pw.SizedBox(height: 6),
        if (metrik.perKategori.isEmpty)
          pw.Text(
            'Belum ada catatan pada periode ini.',
            style: pw.TextStyle(font: biasa, fontSize: 9, color: teksSekunder),
          )
        else
          pw.TableHelper.fromTextArray(
            headers: const ['Kategori', 'Catatan', 'Respons Mudah', 'Arah'],
            data: [
              for (final k in metrik.perKategori)
                [
                  k.kategori.label +
                      (metrik.penandaPerhatian.contains(k.kategori)
                          ? '  (ditandai)'
                          : ''),
                  '${k.jumlahTercatat}',
                  '${k.persenMudah}%',
                  k.tren.label,
                ],
            ],
            headerStyle: pw.TextStyle(
              font: tebal,
              fontSize: 9,
              color: teksUtama,
            ),
            cellStyle: pw.TextStyle(font: biasa, fontSize: 9, color: teksUtama),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE4CEEC),
            ),
            cellAlignments: {
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
            },
            border: pw.TableBorder.all(color: garis),
          ),

        if (metrik.trenMingguan.isNotEmpty) ...[
          pw.SizedBox(height: 18),
          pw.Text(
            'Respons Mudah per minggu',
            style: pw.TextStyle(font: tebal, fontSize: 11, color: teksUtama),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: const ['Minggu mulai', 'Catatan', 'Respons Mudah'],
            data: [
              for (final t in metrik.trenMingguan)
                [
                  DateFormat('d MMM y', 'id_ID').format(t.mingguMulai),
                  '${t.jumlahTercatat}',
                  '${t.persenMudah}%',
                ],
            ],
            headerStyle: pw.TextStyle(
              font: tebal,
              fontSize: 9,
              color: teksUtama,
            ),
            cellStyle: pw.TextStyle(font: biasa, fontSize: 9, color: teksUtama),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE4CEEC),
            ),
            cellAlignments: {
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
            },
            border: pw.TableBorder.all(color: garis),
          ),
        ],

        pw.SizedBox(height: 18),
        pw.Text(
          'Ringkasan',
          style: pw.TextStyle(font: tebal, fontSize: 11, color: teksUtama),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: garis),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            ringkasan,
            style: pw.TextStyle(font: biasa, fontSize: 10, color: teksUtama),
            textAlign: pw.TextAlign.justify,
          ),
        ),

        // Repeated in the body as well as the footer. A reader who prints only
        // the first page must still be holding the caveat.
        pw.SizedBox(height: 16),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: teksUtama, width: 1.4),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Tentang dokumen ini',
                style: pw.TextStyle(
                  font: tebal,
                  fontSize: 10,
                  color: teksUtama,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                catatanPenyangkalan,
                style: pw.TextStyle(font: biasa, fontSize: 9, color: teksUtama),
                textAlign: pw.TextAlign.justify,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  return dokumen.save();
}

pw.Widget _baris(pw.Font biasa, pw.Font tebal, String label, String nilai) =>
    pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: biasa,
                fontSize: 9,
                color: const PdfColor.fromInt(0xFF6B5F73),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              nilai,
              style: pw.TextStyle(
                font: tebal,
                fontSize: 9,
                color: const PdfColor.fromInt(0xFF4A2657),
              ),
            ),
          ),
        ],
      ),
    );
