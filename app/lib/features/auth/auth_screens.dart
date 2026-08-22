import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/profil_anak.dart';
import '../../data/providers.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/privacy_strip.dart';
import '../../shared/widgets/step_indicator.dart';

/// L.13 - loads the session and routes onwards.
///
/// The progress bar is the same static four-segment widget used by onboarding,
/// and the loading line is plain text. No spinner: a spinner is a repeating
/// animation, and this is the first thing the app ever shows.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _arahkan());
  }

  Future<void> _arahkan() async {
    final auth = ref.read(authRepositoryProvider);
    if (!mounted) return;

    if (!auth.sudahMasuk) {
      context.go('/masuk');
      return;
    }

    // A caregiver with no child profile yet has not finished setting up, so
    // they land in onboarding rather than on an empty home screen.
    final peran = await ref.read(peranSayaProvider.future);
    if (!mounted) return;

    switch (peran) {
      case Peran.profesional:
        context.go('/profesional/masuk-kotak');
      case Peran.admin:
        context.go('/admin/verifikasi');
      case Peran.pengasuh || null:
        final anak = await ref.read(daftarAnakProvider.future);
        if (!mounted) return;
        context.go(anak.isEmpty ? '/onboarding/1' : '/beranda');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        // Centred while it fits, scrollable once it does not. At 200% text the
        // tagline alone wraps past the fold on a small phone.
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DekapSpace.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(S.appName, style: text.titleLarge),
                const SizedBox(height: DekapSpace.cardGap / 2),
                Text(S.tagline, style: text.bodyLarge),
                const SizedBox(height: DekapSpace.screenPadding),
                const StepIndicator(langkahSaatIni: 1, totalLangkah: 3),
                const SizedBox(height: DekapSpace.cardGap),
                Text(S.memuatRencana, style: text.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// L.14.
class MasukScreen extends ConsumerStatefulWidget {
  const MasukScreen({super.key});

  @override
  ConsumerState<MasukScreen> createState() => _MasukScreenState();
}

class _MasukScreenState extends ConsumerState<MasukScreen> {
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  bool _lihatSandi = false;
  bool _sibuk = false;
  String? _kesalahan;
  String? _kabar;

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text(S.titleMasuk)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DekapSpace.screenPadding),
          children: [
            Text(S.appName, style: text.titleLarge),
            const SizedBox(height: DekapSpace.cardGap / 2),
            Text(S.tagline, style: text.bodySmall),
            const SizedBox(height: DekapSpace.screenPadding),

            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(hintText: 'Email'),
            ),
            const SizedBox(height: DekapSpace.cardGap),
            TextField(
              controller: _sandi,
              obscureText: !_lihatSandi,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                hintText: 'Kata sandi',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _lihatSandi = !_lihatSandi),
                  icon: Icon(
                    _lihatSandi ? Icons.visibility_off : Icons.visibility,
                  ),
                  tooltip: _lihatSandi
                      ? 'Sembunyikan kata sandi'
                      : 'Tampilkan kata sandi',
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _sibuk ? null : _lupaSandi,
                child: const Text('Lupa kata sandi'),
              ),
            ),

            if (_kesalahan != null) ...[
              const SizedBox(height: DekapSpace.cardGap / 2),
              Text(
                _kesalahan!,
                style: text.bodyMedium?.copyWith(color: DekapColors.boundary),
              ),
            ],
            if (_kabar != null) ...[
              const SizedBox(height: DekapSpace.cardGap / 2),
              Text(_kabar!, style: text.bodyMedium),
            ],

            const SizedBox(height: DekapSpace.cardPadding),
            PrimaryButton(
              label: _sibuk ? 'Sedang masuk…' : 'Masuk',
              onPressed: _sibuk ? null : _masuk,
            ),
            const SizedBox(height: DekapSpace.cardPadding),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DekapSpace.cardGap,
                  ),
                  child: Text('atau', style: text.bodySmall),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: DekapSpace.cardPadding),
            SecondaryButton(
              label: 'Masuk dengan Google',
              onPressed: _sibuk ? null : _google,
            ),
            const SizedBox(height: DekapSpace.cardPadding),
            Center(
              child: TextButton(
                onPressed: () => context.go('/daftar'),
                child: const Text('Belum punya akun? Daftar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _jalankan(Future<void> Function() aksi, {String? kabar}) async {
    setState(() {
      _sibuk = true;
      _kesalahan = null;
      _kabar = null;
    });
    try {
      await aksi();
      if (!mounted) return;
      setState(() {
        _sibuk = false;
        _kabar = kabar;
      });
    } on KesalahanAuth catch (e) {
      if (!mounted) return;
      setState(() {
        _sibuk = false;
        _kesalahan = e.pesan;
      });
    }
  }

  Future<void> _masuk() => _jalankan(() async {
    await ref
        .read(authRepositoryProvider)
        .masuk(email: _email.text, sandi: _sandi.text);
    if (mounted) context.go('/splash');
  });

  Future<void> _google() =>
      _jalankan(() => ref.read(authRepositoryProvider).masukDenganGoogle());

  Future<void> _lupaSandi() {
    if (_email.text.trim().isEmpty) {
      setState(
        () => _kesalahan =
            'Isi email Anda lebih dulu, lalu tekan lupa kata sandi.',
      );
      return Future.value();
    }
    return _jalankan(
      () => ref
          .read(authRepositoryProvider)
          .kirimTautanAturUlangSandi(_email.text),
      kabar:
          'Tautan atur ulang kata sandi dikirim ke ${_email.text.trim()}. '
          'Buka tautan itu untuk membuat kata sandi baru.',
    );
  }
}

/// Sign-up, including the role choice that KF-01 asks for.
class DaftarScreen extends ConsumerStatefulWidget {
  const DaftarScreen({super.key});

  @override
  ConsumerState<DaftarScreen> createState() => _DaftarScreenState();
}

class _DaftarScreenState extends ConsumerState<DaftarScreen> {
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  Peran _peran = Peran.pengasuh;
  bool _setuju = false;
  bool _sibuk = false;
  String? _kesalahan;
  String? _kabar;

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text(S.titleDaftar)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DekapSpace.screenPadding),
          children: [
            TextField(
              controller: _nama,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Nama Anda'),
            ),
            const SizedBox(height: DekapSpace.cardGap),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'Email'),
            ),
            const SizedBox(height: DekapSpace.cardGap),
            TextField(
              controller: _sandi,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Kata sandi, minimal 8 karakter',
              ),
            ),
            const SizedBox(height: DekapSpace.cardPadding),

            Text('Anda mendaftar sebagai', style: text.titleMedium),
            const SizedBox(height: DekapSpace.cardGap),
            // Administrator is deliberately absent: that role is granted, never
            // self-selected.
            for (final p in [Peran.pengasuh, Peran.profesional]) ...[
              OptionTile(
                label: p.label,
                terpilih: _peran == p,
                onTap: () => setState(() => _peran = p),
              ),
              const SizedBox(height: DekapSpace.cardGap / 1.5),
            ],

            const SizedBox(height: DekapSpace.cardGap),
            MultiOptionChip(
              label: 'Saya menyetujui kebijakan privasi',
              terpilih: _setuju,
              onTap: () => setState(() => _setuju = !_setuju),
            ),
            const SizedBox(height: DekapSpace.cardGap),
            const PrivacyStrip(),

            if (_kesalahan != null) ...[
              const SizedBox(height: DekapSpace.cardGap),
              Text(
                _kesalahan!,
                style: text.bodyMedium?.copyWith(color: DekapColors.boundary),
              ),
            ],
            if (_kabar != null) ...[
              const SizedBox(height: DekapSpace.cardGap),
              Text(_kabar!, style: text.bodyMedium),
            ],

            const SizedBox(height: DekapSpace.cardPadding),
            PrimaryButton(
              label: _sibuk ? 'Sedang mendaftar…' : 'Buat akun',
              onPressed: _sibuk || !_setuju ? null : _daftar,
            ),
            const SizedBox(height: DekapSpace.cardGap),
            Center(
              child: TextButton(
                onPressed: () => context.go('/masuk'),
                child: const Text('Sudah punya akun? Masuk'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _daftar() async {
    setState(() {
      _sibuk = true;
      _kesalahan = null;
      _kabar = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .daftar(
            nama: _nama.text,
            email: _email.text,
            sandi: _sandi.text,
            peran: _peran,
          );
      if (!mounted) return;
      if (ref.read(authRepositoryProvider).sudahMasuk) {
        context.go('/splash');
      } else {
        setState(() {
          _sibuk = false;
          _kabar =
              'Akun dibuat. Buka tautan konfirmasi yang kami kirim ke '
              '${_email.text.trim()}, lalu masuk.';
        });
      }
    } on KesalahanAuth catch (e) {
      if (!mounted) return;
      setState(() {
        _sibuk = false;
        _kesalahan = e.pesan;
      });
    }
  }
}
