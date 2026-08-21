import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../repositories/rencana_repository.dart';

/// Drains the offline outbox whenever the network comes back (KNF-02).
///
/// Deliberately dumb: it only decides *when* to try. Everything about *what* to
/// send, and the idempotency that makes retrying safe, lives in the repository
/// and in the unique client id on the server. That separation is what lets the
/// drain be triggered from anywhere, as often as it likes, without anyone
/// having to reason about duplicate rows.
class SyncService {
  SyncService(this._repo, {Stream<List<ConnectivityResult>>? konektivitas})
    : _konektivitas = konektivitas ?? Connectivity().onConnectivityChanged;

  final RencanaRepository _repo;
  final Stream<List<ConnectivityResult>> _konektivitas;

  StreamSubscription<List<ConnectivityResult>>? _langganan;
  bool _sedangMenguras = false;

  void mulai() {
    _langganan ??= _konektivitas.listen((status) {
      if (status.any((s) => s != ConnectivityResult.none)) {
        unawaited(kuras());
      }
    });
    unawaited(kuras());
  }

  /// One drain at a time. Two overlapping drains would both read the same
  /// pending rows and push each twice - harmless on the server thanks to the
  /// unique client id, but it would double the traffic on a connection that has
  /// only just come back.
  Future<int> kuras() async {
    if (_sedangMenguras) return 0;
    _sedangMenguras = true;
    try {
      return await _repo.kurasAntrean();
    } catch (_) {
      return 0;
    } finally {
      _sedangMenguras = false;
    }
  }

  Future<void> berhenti() async {
    await _langganan?.cancel();
    _langganan = null;
  }
}
