import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';


class BackgroundClearPolicy {
  final bool clearOnPaused;
  final bool clearOnInactive;
  final bool clearOnDetached;

  const BackgroundClearPolicy({
    this.clearOnPaused = true,
    this.clearOnInactive = false,
    this.clearOnDetached = true,
  });
}

class _SecretToken {
  Uint8List value;
  DateTime expiresAt;

  _SecretToken(this.value, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  void zeroize() {
    for (var i = 0; i < value.length; i++) {
      value[i] = 0;
    }
    value = Uint8List(0);
  }
}

typedef PassphrasePrompt = Future<Uint8List?> Function(String keyId);

class PassphraseVault with ChangeNotifier, WidgetsBindingObserver {
  PassphraseVault({
    Duration defaultTtl = const Duration(minutes: 15),
    BackgroundClearPolicy backgroundPolicy = const BackgroundClearPolicy(),
  })  : _defaultTtl = defaultTtl,
        _bgPolicy = backgroundPolicy {
    WidgetsBinding.instance.addObserver(this);
    _housekeeper = Timer.periodic(const Duration(seconds: 5), (_) => _sweep());
  }

  Duration _defaultTtl;
  final BackgroundClearPolicy _bgPolicy;
  late final Timer _housekeeper;

  /// keyId -> token
  final Map<String, _SecretToken> _secrets = {};

  /// Optional per‑key TTL override.
  final Map<String, Duration> _perKeyTtl = {};

  /// For consumers (UI/services) that want to reflect lock status.
  bool isUnlocked(String keyId) => _secrets[keyId] != null && !_secrets[keyId]!.isExpired;

  Duration get defaultTtl => _defaultTtl;

  set defaultTtl(Duration v) {
    _defaultTtl = v;
    _bumpAll();
  }

  void setPerKeyTtl(String keyId, Duration ttl) {
    _perKeyTtl[keyId] = ttl;
    _bump(keyId);
  }

  void clearPerKeyTtl(String keyId) => _perKeyTtl.remove(keyId);

  void put(String keyId, Uint8List passphrase, {Duration? ttl}) {
    _wipe(keyId);
    final effectiveTtl = ttl ?? _perKeyTtl[keyId] ?? _defaultTtl;
    _secrets[keyId] = _SecretToken(passphrase, DateTime.now().add(effectiveTtl));
    notifyListeners();
  }

  Uint8List? peek(String keyId) {
    final t = _secrets[keyId];
    if (t == null || t.isExpired) return null;
    return Uint8List.fromList(t.value);
  }

  void touch(String keyId) {
    final t = _secrets[keyId];
    if (t == null || t.isExpired) return;
    final ttl = _perKeyTtl[keyId] ?? _defaultTtl;
    t.expiresAt = DateTime.now().add(ttl);
    notifyListeners();
  }

  void lock(String keyId) {
    final changed = _wipe(keyId);
    if (changed) notifyListeners();
  }

  void lockAll() {
    bool changed = false;
    for (final k in _secrets.keys.toList()) {
      changed = _wipe(k) || changed;
    }
    if (changed) notifyListeners();
  }

  Future<Uint8List> getOrPrompt(String keyId, PassphrasePrompt prompt, {Duration? ttl}) async {
    final existing = peek(keyId);
    if (existing != null) {
      return existing;
    }
    final entered = await prompt(keyId);
    if (entered == null) {
      throw PassphraseCancelled();
    }
    put(keyId, entered, ttl: ttl);
    return Uint8List.fromList(entered);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _housekeeper.cancel();
    lockAll();
    super.dispose();
  }

  // ---- WidgetsBindingObserver ----

  @override  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        if (_bgPolicy.clearOnPaused) lockAll();
        break;
      case AppLifecycleState.inactive:
        if (_bgPolicy.clearOnInactive) lockAll();
        break;
      case AppLifecycleState.detached:
        if (_bgPolicy.clearOnDetached) lockAll();
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.hidden:
        if (_bgPolicy.clearOnPaused) lockAll();
        break;
    }
  }

  void _bump(String keyId) {
    final t = _secrets[keyId];
    if (t == null || t.isExpired) return;
    final ttl = _perKeyTtl[keyId] ?? _defaultTtl;
    t.expiresAt = DateTime.now().add(ttl);
  }

  void _bumpAll() {
    for (final k in _secrets.keys) {
      _bump(k);
    }
    notifyListeners();
  }

  bool _wipe(String keyId) {
    final t = _secrets.remove(keyId);
    if (t == null) return false;
    t.zeroize();
    return true;
  }

  void _sweep() {
    bool changed = false;
    final now = DateTime.now();
    for (final entry in _secrets.entries.toList()) {
      final k = entry.key;
      final t = entry.value;
      if (now.isAfter(t.expiresAt)) {
        _wipe(k);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }
}

class PassphraseCancelled implements Exception {
  @override
  String toString() => 'PassphraseCancelled';
}


Future<T> withPassphrase<T>(
    PassphraseVault vault,
    String keyId, {
      required PassphrasePrompt prompt,
      Duration? ttl,
      required Future<T> Function(Uint8List passphrase) body,
    }) async {
  final secret = await vault.getOrPrompt(keyId, prompt, ttl: ttl);
  try {
    vault.touch(keyId);
    final result = await body(secret);
    return result;
  } finally {
    for (var i = 0; i < secret.length; i++) {
      secret[i] = 0;
    }
  }
}