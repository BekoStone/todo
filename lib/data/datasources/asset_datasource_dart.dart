// File: lib/data/datasources/asset_datasource.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:puzzle_box/core/errors/exceptions_dart.dart';
import '../../core/constants/asset_constants.dart';

/// Asset loading status
enum AssetLoadingStatus {
  notLoaded,
  loading,
  loaded,
  failed,
}

/// Asset information with metadata
class AssetInfo {
  final String path;
  final AssetLoadingStatus status;
  final DateTime? loadedAt;
  final String? errorMessage;
  final int? sizeBytes;

  const AssetInfo({
    required this.path,
    required this.status,
    this.loadedAt,
    this.errorMessage,
    this.sizeBytes,
  });

  AssetInfo copyWith({
    String? path,
    AssetLoadingStatus? status,
    DateTime? loadedAt,
    String? errorMessage,
    int? sizeBytes,
  }) {
    return AssetInfo(
      path: path ?? this.path,
      status: status ?? this.status,
      loadedAt: loadedAt ?? this.loadedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      sizeBytes: sizeBytes ?? this.sizeBytes,
    );
  }

  Map<String, dynamic> toMap() => {
    'path': path,
    'status': status.name,
    'loadedAt': loadedAt?.millisecondsSinceEpoch,
    'errorMessage': errorMessage,
    'sizeBytes': sizeBytes,
  };
}

/// Asset loading progress
class AssetLoadingProgress {
  final int totalAssets;
  final int loadedAssets;
  final int failedAssets;
  final List<String> currentlyLoading;
  final Map<String, String> errors;

  const AssetLoadingProgress({
    required this.totalAssets,
    required this.loadedAssets,
    required this.failedAssets,
    required this.currentlyLoading,
    required this.errors,
  });

  double get progressPercentage =>
      totalAssets > 0 ? (loadedAssets + failedAssets) / totalAssets : 0.0;

  bool get isComplete => loadedAssets + failedAssets >= totalAssets;

  bool get hasErrors => errors.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'totalAssets': totalAssets,
    'loadedAssets': loadedAssets,
    'failedAssets': failedAssets,
    'progressPercentage': progressPercentage,
    'isComplete': isComplete,
    'hasErrors': hasErrors,
    'currentlyLoading': currentlyLoading,
    'errors': errors,
  };
}

/// Asset datasource interface
abstract class AssetDataSource {
  /// Initialize the asset system
  Future<void> initialize();

  /// Preload all essential game assets
  Future<AssetLoadingProgress> preloadGameAssets({
    void Function(AssetLoadingProgress)? onProgress,
  });

  /// Load a specific image asset
  Future<void> loadImage(String path);

  /// Load a specific audio asset
  Future<void> loadAudio(String path);

  /// Load multiple assets in parallel
  Future<void> loadAssets(List<String> paths);

  /// Check if an image asset is loaded
  bool isImageLoaded(String path);

  /// Check if an audio asset is loaded
  bool isAudioLoaded(String path);

  /// Get asset loading information
  AssetInfo getAssetInfo(String path);

  /// Get all loaded assets information
  Map<String, AssetInfo> getAllAssetsInfo();

  /// Get loading progress for all assets
  AssetLoadingProgress getLoadingProgress();

  /// Clear specific asset from cache
  Future<void> clearAsset(String path);

  /// Clear all assets from cache
  Future<void> clearAllAssets();

  /// Get cache size in bytes
  int getCacheSize();

  /// Validate asset integrity
  Future<bool> validateAsset(String path);

  /// Dispose of resources
  Future<void> dispose();
}

/// Default implementation of asset datasource
class DefaultAssetDataSource implements AssetDataSource {
  final Map<String, AssetInfo> _assetInfo = {};
  final Set<String> _currentlyLoading = {};
  final Map<String, Completer<void>> _loadingCompleters = {};
  bool _isInitialized = false;

  static const int _maxConcurrentLoads = 8;
  static const Duration _loadTimeout = Duration(seconds: 30);

  @override
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      // Initialize asset maps for all known assets
      for (final imagePath in AssetConstants.requiredImages) {
        _assetInfo[imagePath] = AssetInfo(
          path: imagePath,
          status: AssetLoadingStatus.notLoaded,
        );
      }

      for (final audioPath in AssetConstants.requiredAudio) {
        _assetInfo[audioPath] = AssetInfo(
          path: audioPath,
          status: AssetLoadingStatus.notLoaded,
        );
      }

      _isInitialized = true;
      developer.log('AssetDataSource initialized with ${_assetInfo.length} assets', name: 'Assets');
    } catch (e) {
      throw InitializationException('Failed to initialize asset datasource: $e');
    }
  }

  @override
  Future<AssetLoadingProgress> preloadGameAssets({
    void Function(AssetLoadingProgress)? onProgress,
  }) async {
    if (!_isInitialized) {
      throw StateException('AssetDataSource not initialized');
    }

    try {
      final allAssets = [
        ...AssetConstants.requiredImages,
        ...AssetConstants.requiredAudio,
      ];

      developer.log('Starting preload of ${allAssets.length} assets', name: 'Assets');

      // Load assets in batches to control concurrency
      final batches = _createBatches(allAssets, _maxConcurrentLoads);
      
      for (final batch in batches) {
        await Future.wait(
          batch.map((path) => _loadAssetWithRetry(path)),
          eagerError: false, // Continue loading even if some fail
        );

        // Notify progress
        onProgress?.call(getLoadingProgress());
      }

      final finalProgress = getLoadingProgress();
      developer.log(
        'Asset preload completed: ${finalProgress.loadedAssets}/${finalProgress.totalAssets} loaded',
        name: 'Assets',
      );

      return finalProgress;
    } catch (e) {
      throw AssetException('Failed to preload game assets: $e');
    }
  }

  @override
  Future<void> loadImage(String path) async {
    if (!_isInitialized) {
      throw StateException('AssetDataSource not initialized');
    }

    await _loadAssetWithRetry(path, isImage: true);
  }

  @override
  Future<void> loadAudio(String path) async {
    if (!_isInitialized) {
      throw StateException('AssetDataSource not initialized');
    }

    await _loadAssetWithRetry(path, isImage: false);
  }

  @override
  Future<void> loadAssets(List<String> paths) async {
    if (!_isInitialized) {
      throw StateException('AssetDataSource not initialized');
    }

    try {
      await Future.wait(
        paths.map((path) => _loadAssetWithRetry(path)),
        eagerError: false,
      );
    } catch (e) {
      throw AssetException('Failed to load assets: $e');
    }
  }

  @override
  bool isImageLoaded(String path) {
    try {
      final image = Flame.images.fromCache(path);
      return image != null && _assetInfo[path]?.status == AssetLoadingStatus.loaded;
    } catch (e) {
      return false;
    }
  }

  @override
  bool isAudioLoaded(String path) {
    final info = _assetInfo[path];
    return info?.status == AssetLoadingStatus.loaded;
  }

  @override
  AssetInfo getAssetInfo(String path) {
    return _assetInfo[path] ?? AssetInfo(
      path: path,
      status: AssetLoadingStatus.notLoaded,
    );
  }

  @override
  Map<String, AssetInfo> getAllAssetsInfo() {
    return Map.unmodifiable(_assetInfo);
  }

  @override
  AssetLoadingProgress getLoadingProgress() {
    final totalAssets = _assetInfo.length;
    final loadedAssets = _assetInfo.values
        .where((info) => info.status == AssetLoadingStatus.loaded)
        .length;
    final failedAssets = _assetInfo.values
        .where((info) => info.status == AssetLoadingStatus.failed)
        .length;
    
    final errors = <String, String>{};
    for (final entry in _assetInfo.entries) {
      if (entry.value.status == AssetLoadingStatus.failed && entry.value.errorMessage != null) {
        errors[entry.key] = entry.value.errorMessage!;
      }
    }

    return AssetLoadingProgress(
      totalAssets: totalAssets,
      loadedAssets: loadedAssets,
      failedAssets: failedAssets,
      currentlyLoading: _currentlyLoading.toList(),
      errors: errors,
    );
  }

  @override
  Future<void> clearAsset(String path) async {
    try {
      // Remove from Flame cache
      Flame.images.clearCache(path);
      
      // Clear from audio cache
      FlameAudio.audioCache.clear(path);

      // Update asset info
      _assetInfo[path] = _assetInfo[path]?.copyWith(
        status: AssetLoadingStatus.notLoaded,
        loadedAt: null,
        errorMessage: null,
      ) ?? AssetInfo(path: path, status: AssetLoadingStatus.notLoaded);

      developer.log('Cleared asset: $path', name: 'Assets');
    } catch (e) {
      throw AssetException('Failed to clear asset $path: $e');
    }
  }

  @override
  Future<void> clearAllAssets() async {
    try {
      // Clear Flame caches
      Flame.images.clearCache();
      FlameAudio.audioCache.clearAll();

      // Reset all asset info
      for (final path in _assetInfo.keys) {
        _assetInfo[path] = _assetInfo[path]!.copyWith(
          status: AssetLoadingStatus.notLoaded,
          loadedAt: null,
          errorMessage: null,
        );
      }

      developer.log('Cleared all assets', name: 'Assets');
    } catch (e) {
      throw AssetException('Failed to clear all assets: $e');
    }
  }

  @override
  int getCacheSize() {
    // Approximate cache size calculation
    // In a real implementation, you might track actual file sizes
    final loadedCount = _assetInfo.values
        .where((info) => info.status == AssetLoadingStatus.loaded)
        .length;
    
    return loadedCount * 50000; // Approximate 50KB per asset
  }

  @override
  Future<bool> validateAsset(String path) async {
    try {
      final info = _assetInfo[path];
      if (info?.status != AssetLoadingStatus.loaded) {
        return false;
      }

      // For images, check if they're in the Flame cache
      if (AssetConstants.requiredImages.contains(path)) {
        final image = Flame.images.fromCache(path);
        return image != null;
      }

      // For audio, assume valid if marked as loaded
      if (AssetConstants.requiredAudio.contains(path)) {
        return true;
      }

      return false;
    } catch (e) {
      developer.log('Asset validation failed for $path: $e', name: 'Assets');
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    try {
      // Cancel any pending loads
      for (final completer in _loadingCompleters.values) {
        if (!completer.isCompleted) {
          completer.completeError(const AssetException('Asset loading cancelled'));
        }
      }

      // Clear all assets
      await clearAllAssets();

      // Clear internal state
      _assetInfo.clear();
      _currentlyLoading.clear();
      _loadingCompleters.clear();
      
      _isInitialized = false;
      developer.log('AssetDataSource disposed', name: 'Assets');
    } catch (e) {
      throw AssetException('Failed to dispose asset datasource: $e');
    }
  }

  /// Load asset with retry logic
  Future<void> _loadAssetWithRetry(String path, {bool? isImage, int maxRetries = 3}) async {
    // Skip if already loaded or currently loading
    final currentInfo = _assetInfo[path];
    if (currentInfo?.status == AssetLoadingStatus.loaded) {
      return;
    }

    if (_currentlyLoading.contains(path)) {
      // Wait for existing load to complete
      final completer = _loadingCompleters[path];
      if (completer != null) {
        return completer.future;
      }
    }

    // Create completer for this load
    final completer = Completer<void>();
    _loadingCompleters[path] = completer;
    _currentlyLoading.add(path);

    // Update status to loading
    _assetInfo[path] = currentInfo?.copyWith(status: AssetLoadingStatus.loading) ??
        AssetInfo(path: path, status: AssetLoadingStatus.loading);

    int attempts = 0;
    Exception? lastError;

    while (attempts < maxRetries) {
      try {
        attempts++;
        
        // Determine asset type if not specified
        final actualIsImage = isImage ?? AssetConstants.requiredImages.contains(path);
        
        if (actualIsImage) {
          await _loadImageAsset(path);
        } else {
          await _loadAudioAsset(path);
        }

        // Success - update status
        _assetInfo[path] = _assetInfo[path]!.copyWith(
          status: AssetLoadingStatus.loaded,
          loadedAt: DateTime.now(),
          errorMessage: null,
        );

        completer.complete();
        break;

      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        
        if (attempts >= maxRetries) {
          // Failed - update status
          _assetInfo[path] = _assetInfo[path]!.copyWith(
            status: AssetLoadingStatus.failed,
            errorMessage: e.toString(),
          );

          completer.completeError(lastError);
          developer.log('Failed to load asset $path after $attempts attempts: $e', name: 'Assets');
        } else {
          // Wait before retry
          await Future.delayed(Duration(milliseconds: 500 * attempts));
        }
      }
    }

    // Cleanup
    _currentlyLoading.remove(path);
    _loadingCompleters.remove(path);
  }

  /// Load image asset
  Future<void> _loadImageAsset(String path) async {
    await Future.any([
      Flame.images.load(path),
      Future.delayed(_loadTimeout).then((_) => throw TimeoutException('Image load timeout: $path')),
    ]);
  }

  /// Load audio asset
  Future<void> _loadAudioAsset(String path) async {
    await Future.any([
      FlameAudio.audioCache.load(path),
      Future.delayed(_loadTimeout).then((_) => throw TimeoutException('Audio load timeout: $path')),
    ]);
  }

  /// Create batches of assets for parallel loading
  List<List<String>> _createBatches(List<String> assets, int batchSize) {
    final batches = <List<String>>[];
    for (int i = 0; i < assets.length; i += batchSize) {
      final end = (i + batchSize < assets.length) ? i + batchSize : assets.length;
      batches.add(assets.sublist(i, end));
    }
    return batches;
  }
}