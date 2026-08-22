import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/laporan_repository.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/states.dart';

/// Who currently has access to what, and since when (L.16, KNF-04).
///
/// The screen exists because a promise nobody can inspect is not a promise.
/// Bab 4.3 says sharing needs explicit consent and can be withdrawn; this is
/// where a caregiver sees both halves and acts on them.
///
/// Revoking cuts access off through RLS, not by hiding a row here. Check 4 in
/// scripts/test_rls.sql proves that the professional stops being able to read
/// the report the moment this button is pressed.
class IzinBerbagiScreen extends ConsumerStatefulWidget {
  const IzinBerbagiScreen({super.key});

  @override
  ConsumerState<IzinBerbagiScreen> createState() => _IzinBerbagiScreenState();
}

class _IzinBerbagiScreenState extends ConsumerState<IzinBerbagiScreen> {
  String? _kesalahan;

  @override
  Widget build(BuildContext context) {
    final izin = ref.watch(daftarIzinProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text(S.titleIzin)),
      body: izin.when(
        loading: () => const LoadingText(),
        error: (_, _) => const ErrorState(message: S.gagalLayanan),
        data: (daftar) {
          final aktif = daftar.where((i) => i.aktif).toList();
          final dicabut = daftar.where((i) => !i.aktif).toList();

          return ListView(
            padding: const EdgeInsets.all(DekapSpace.screenPadding),
            children: [
              Text(
                'Laporan hanya dapat dibaca tenaga profesional yang Anda beri '
                'izin, dan hanya selama izinnya aktif.',
                style: text.bodyMedium,
              ),
              if (_kesalahan != null) ...[
                const SizedBox(height: DekapSpace.cardGap),
                Text(
                  _kesalahan!,
                  style: text.bodyMedium?.copyWith(color: DekapColors.boundary),
                ),
              ],
              const SizedBox(height: DekapSpace.screenPadding),

              Text('Izin aktif', style: text.titleMedium),
              const SizedBox(height: DekapSpace.cardGap),
              if (aktif.isEmpty)
                const EmptyState(
                  message:
                      'Belum ada laporan yang dibagikan. Anda dapat '
                      'membagikannya dari layar Laporan saat siap.',
                )
              else
                for (final i in aktif)
                  _KartuIzin(izin: i, onCabut: () => _cabut(i)),

              if (dicabut.isNotEmpty) ...[
                const SizedBox(height: DekapSpace.screenPadding),
                Text('Izin yang sudah dicabut', style: text.titleMedium),
                const SizedBox(height: DekapSpace.cardGap / 2),
                // Kept visible on purpose: a record of who once had access is
                // part of what makes consent auditable rather than merely
                // reversible.
                Text(
                  'Riwayat ini disimpan agar Anda dapat melihat siapa yang '
                  'pernah punya akses.',
                  style: text.bodySmall,
                ),
                const SizedBox(height: DekapSpace.cardGap),
                for (final i in dicabut) _KartuIzin(izin: i, onCabut: null),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _cabut(IzinBerbagi izin) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DekapColors.surface,
        title: const Text('Cabut izin berbagi'),
        content: Text(
          '${izin.namaProfesional} tidak akan bisa lagi membuka laporan ini. '
          'Anda dapat membagikannya kembali kapan saja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cabut izin'),
          ),
        ],
      ),
    );
    if (setuju != true) return;

    try {
      await ref.read(laporanRepositoryProvider).cabut(izin.id);
      ref.invalidate(daftarIzinProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Izin ${izin.namaProfesional} dicabut.')),
      );
    } on KesalahanAuth catch (e) {
      if (!mounted) return;
      setState(() => _kesalahan = e.pesan);
    }
  }
}

class _KartuIzin extends StatelessWidget {
  const _KartuIzin({required this.izin, required this.onCabut});

  final IzinBerbagi izin;
  final VoidCallback? onCabut;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tanggal = DateFormat('d MMMM y', 'id_ID');

    return Container(
      margin: const EdgeInsets.only(bottom: DekapSpace.cardGap),
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
            children: [
              Icon(
                izin.aktif ? Symbols.handshake_rounded : Symbols.lock_rounded,
                size: DekapSpace.iconSize,
                color: izin.aktif
                    ? DekapColors.purple700
                    : DekapColors.textSecondary,
              ),
              const SizedBox(width: DekapSpace.cardGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(izin.namaProfesional, style: text.bodyLarge),
                    if (izin.spesialisasi.isNotEmpty)
                      Text(izin.spesialisasi, style: text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DekapSpace.cardGap),
          Text(
            'Diberikan ${tanggal.format(izin.diberikanPada)}',
            style: text.bodySmall,
          ),
          if (izin.dicabutPada != null)
            Text(
              'Dicabut ${tanggal.format(izin.dicabutPada!)}',
              style: text.bodySmall,
            ),
          if (onCabut != null) ...[
            const SizedBox(height: DekapSpace.cardGap),
            SecondaryButton(
              label: 'Cabut izin',
              onPressed: onCabut,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}
