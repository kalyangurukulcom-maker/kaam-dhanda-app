/// In-memory TTL cache for Firestore query results.
///
/// Usage:
///   CacheService.instance.set('jobs_list', data);
///   final cached = CacheService.instance.get<List>('jobs_list');
///   if (cached != null) { use cached } else { fetch from Firestore }
library;

class CacheService {
  static final CacheService instance = CacheService._();
  CacheService._();

  final Map<String, _CacheEntry> _store = {};

  /// Store [value] under [key] with optional TTL (default 5 minutes).
  void set(String key, dynamic value,
      {Duration ttl = const Duration(minutes: 5)}) {
    _store[key] = _CacheEntry(value, DateTime.now().add(ttl));
  }

  /// Return cached value for [key], or null if missing/expired.
  T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null || entry.isExpired) {
      _store.remove(key);
      return null;
    }
    return entry.data as T?;
  }

  /// Force-remove a cached key (e.g. after writing new data).
  void invalidate(String key) => _store.remove(key);

  /// Remove all keys matching a prefix.
  void invalidatePrefix(String prefix) {
    _store.removeWhere((k, _) => k.startsWith(prefix));
  }

  /// Wipe entire cache.
  void clear() => _store.clear();

  /// Check if key exists and is not expired.
  bool has(String key) {
    final entry = _store[key];
    if (entry == null || entry.isExpired) {
      _store.remove(key);
      return false;
    }
    return true;
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiry;
  _CacheEntry(this.data, this.expiry);
  bool get isExpired => DateTime.now().isAfter(expiry);
}
