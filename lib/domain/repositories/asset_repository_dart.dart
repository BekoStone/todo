// File: lib/domain/repositories/asset_repository.dart

/// Asset type enumeration
enum AssetType {
  image,
  audio,
  unknown,
}

/// Asset loading progress information
class AssetLoadingProgress {
  final int totalAssets;
  final int loadedAssets;
  final int failedAssets;
  final double progressPercentage;
  final bool isComplete;
  final List<String> currentlyLoading;
  final Map<String, String> errors;

  const AssetLoadingProgress({
    required this.totalAssets,
    required this.loadedAssets,
    required this.failedAssets,
    required this.progressPercentage,
    required this.isComplete,
    required this.currentlyLoading,
    required this.errors,
  });

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

  @override
  String toString() => 'AssetLoadingProgress('
      'loaded: $loadedAssets/$totalAssets, '
      'progress: ${(progressPercentage * 100).toStringAsFixed(1)}%, '
      'errors: ${errors.length})';
}

/// Asset loading result after completion
class AssetLoadingResult {
  final int totalAssets;
  final int loadedAssets;
  final int failedAssets;
  final Duration duration;
  final Map<String, String> errors;
  final bool isSuccess;

  const AssetLoadingResult({
    required this.totalAssets,
    required this.loadedAssets,
    required this.failedAssets,
    required this.duration,
    required this.errors,
    required this.isSuccess,
  });

  double get successRate => totalAssets > 0 ? loadedAssets / totalAssets : 0.0;

  bool get hasErrors => errors.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'totalAssets': totalAssets,
    'loadedAssets': loadedAssets,
    'failedAssets': failedAssets,
    'duration_ms': duration.inMilliseconds,
    'success_rate': successRate,
    'is_success': isSuccess,
    'has_errors': hasErrors,
    'errors': errors,
  };

  @override
  String toString() => 'AssetLoadingResult('
      'success: $loadedAssets/$totalAssets in ${duration.inMilliseconds}ms, '
      'rate: ${(successRate * 100).toStringAsFixed(1)}%)';
}

/// Asset metadata information
class AssetMetadata {
  final String path;
  final bool isLoaded;
  final DateTime? loadedAt;
  final int? sizeBytes;
  final String? lastError;
  final AssetType assetType;

  const AssetMetadata({
    required this.path,
    required this.isLoaded,
    this.loadedAt,
    this.sizeBytes,
    this.lastError,
    required this.assetType,
  });

  bool get hasError => lastError != null;

  String get fileExtension {
    final parts = path.split('.');
    return parts.isNotEmpty ? parts.last.toLowerCase() : '';
  }

  String get fileName {
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : path;
  }

  Map<String, dynamic> toMap() => {
    'path': path,
    'is_loaded': isLoaded,
    'loaded_at': loadedAt?.millisecondsSinceEpoch,
    'size_bytes': sizeBytes,
    'last_error': lastError,
    'asset_type': assetType.name,
    'file_extension': fileExtension,
    'file_name': fileName,
    'has_error': hasError,
  };

  @override
  String toString() => 'AssetMetadata('
      'path: $path, '
      'loaded: $isLoaded, '
      'type: ${assetType.name}'
      '${hasError ? ', error: $lastError' : ''})';
}

/// Cache information summary
class CacheInfo {
  final int totalAssets;
  final int loadedAssets;
  final int failedAssets;
  final int totalSizeBytes;
  final DateTime lastUpdated;

  const CacheInfo({
    required this.totalAssets,
    required this.loadedAssets,
    required this.failedAssets,
    required this.totalSizeBytes,
    required this.lastUpdated,
  });

  double get loadSuccessRate => totalAssets > 0 ? loadedAssets / totalAssets : 0.0;

  double get totalSizeMB => totalSizeBytes / (1024 * 1024);

  int get pendingAssets => totalAssets - loadedAssets - failedAssets;

  Map<String, dynamic> toMap() => {
    'total_assets': totalAssets,
    'loaded_assets': loadedAssets,
    'failed_assets': failedAssets,
    'pending_assets': pendingAssets,
    'total_size_bytes': totalSizeBytes,
    'total_size_mb': totalSizeMB,
    'load_success_rate': loadSuccessRate,
    'last_updated': lastUpdated.millisecondsSinceEpoch,
  };

  @override
  String toString() => 'CacheInfo('
      'assets: $loadedAssets/$totalAssets, '
      'size: ${totalSizeMB.toStringAsFixed(2)}MB, '
      'rate: ${(loadSuccessRate * 100).toStringAsFixed(1)}%)';
}

/// Asset repository interface for managing game assets
abstract class AssetRepository {
  /// Initialize the asset repository
  Future<void> initialize();

  /// Preload essential game assets
  /// 
  /// Returns an [AssetLoadingResult] with details about the loading process.
  /// [onProgress] callback receives progress from 0.0 to 1.0.
  Future<AssetLoadingResult> preloadEssentialAssets({
    void Function(double progress)? onProgress,
  });

  /// Load a specific asset
  /// 
  /// Returns true if the asset was loaded successfully, false otherwise.
  Future<bool> loadAsset(String assetPath);

  /// Load multiple assets in parallel
  /// 
  /// Returns a list of boolean values indicating the success status of each asset.
  Future<List<bool>> loadAssets(List<String> assetPaths);

  /// Check if an asset is currently loaded in memory
  Future<bool> isAssetLoaded(String assetPath);

  /// Get metadata information for a specific asset
  Future<AssetMetadata> getAssetMetadata(String assetPath);

  /// Get metadata for all tracked assets
  Future<List<AssetMetadata>> getAllAssetsMetadata();

  /// Get a stream of loading progress updates
  /// 
  /// Useful for showing progress bars during asset loading.
  Stream<AssetLoadingProgress> getLoadingProgressStream();

  /// Validate that an asset is properly loaded and accessible
  Future<bool> validateAsset(String assetPath);

  /// Clear all assets from the cache
  Future<void> clearAssetCache();

  /// Clear a specific asset from the cache
  Future<void> clearSpecificAsset(String assetPath);

  /// Get information about the current asset cache
  Future<CacheInfo> getCacheInfo();

  /// Check if a given path represents an image asset
  bool isImageAsset(String assetPath);

  /// Check if a given path represents an audio asset
  bool isAudioAsset(String assetPath);

  /// Dispose of the repository and clean up resources
  Future<void> dispose();
}

/// Extension methods for common asset operations
extension AssetRepositoryExtensions on AssetRepository {
  /// Preload only image assets
  Future<AssetLoadingResult> preloadImages({
    void Function(double progress)? onProgress,
  }) async {
    final allMetadata = await getAllAssetsMetadata();
    final imagePaths = allMetadata
        .where((metadata) => metadata.assetType == AssetType.image)
        .map((metadata) => metadata.path)
        .toList();

    final startTime = DateTime.now();
    final results = await loadAssets(imagePaths);
    final duration = DateTime.now().difference(startTime);

    final loadedCount = results.where((success) => success).length;
    final errors = <String, String>{};
    
    for (int i = 0; i < imagePaths.length; i++) {
      if (!results[i]) {
        errors[imagePaths[i]] = 'Failed to load';
      }
    }

    return AssetLoadingResult(
      totalAssets: imagePaths.length,
      loadedAssets: loadedCount,
      failedAssets: imagePaths.length - loadedCount,
      duration: duration,
      errors: errors,
      isSuccess: loadedCount == imagePaths.length,
    );
  }

  /// Preload only audio assets
  Future<AssetLoadingResult> preloadAudio({
    void Function(double progress)? onProgress,
  }) async {
    final allMetadata = await getAllAssetsMetadata();
    final audioPaths = allMetadata
        .where((metadata) => metadata.assetType == AssetType.audio)
        .map((metadata) => metadata.path)
        .toList();

    final startTime = DateTime.now();
    final results = await loadAssets(audioPaths);
    final duration = DateTime.now().difference(startTime);

    final loadedCount = results.where((success) => success).length;
    final errors = <String, String>{};
    
    for (int i = 0; i < audioPaths.length; i++) {
      if (!results[i]) {
        errors[audioPaths[i]] = 'Failed to load';
      }
    }

    return AssetLoadingResult(
      totalAssets: audioPaths.length,
      loadedAssets: loadedCount,
      failedAssets: audioPaths.length - loadedCount,
      duration: duration,
      errors: errors,
      isSuccess: loadedCount == audioPaths.length,
    );
  }

  /// Check if all essential assets are loaded
  Future<bool> areEssentialAssetsLoaded() async {
    const essentialAssets = [
      'ui/logo.png',
      'sfx/sfx_click.mp3',
      'sfx/sfx_error.mp3',
    ];

    for (final asset in essentialAssets) {
      if (!await isAssetLoaded(asset)) {
        return false;
      }
    }

    return true;
  }

  /// Get loading statistics summary
  Future<Map<String, dynamic>> getLoadingStatistics() async {
    final cacheInfo = await getCacheInfo();
    final allMetadata = await getAllAssetsMetadata();

    final imageAssets = allMetadata.where((m) => m.assetType == AssetType.image);
    final audioAssets = allMetadata.where((m) => m.assetType == AssetType.audio);
    
    final assetsWithErrors = allMetadata.where((m) => m.hasError);

    return {
      'cache_info': cacheInfo.toMap(),
      'total_assets': allMetadata.length,
      'image_assets': imageAssets.length,
      'audio_assets': audioAssets.length,
      'loaded_images': imageAssets.where((m) => m.isLoaded).length,
      'loaded_audio': audioAssets.where((m) => m.isLoaded).length,
      'assets_with_errors': assetsWithErrors.length,
      'error_rate': allMetadata.isNotEmpty ? assetsWithErrors.length / allMetadata.length : 0.0,
    };
  }

  /// Retry loading failed assets
  Future<AssetLoadingResult> retryFailedAssets() async {
    final allMetadata = await getAllAssetsMetadata();
    final failedAssets = allMetadata
        .where((metadata) => metadata.hasError && !metadata.isLoaded)
        .map((metadata) => metadata.path)
        .toList();

    if (failedAssets.isEmpty) {
      return AssetLoadingResult(
        totalAssets: 0,
        loadedAssets: 0,
        failedAssets: 0,
        duration: Duration.zero,
        errors: const {},
        isSuccess: true,
      );
    }

    return AssetLoadingResult(
      totalAssets: failedAssets.length,
      loadedAssets: 0,
      failedAssets: 0,
      duration: Duration.zero,
      errors: const {},
      isSuccess: true,
    );
  }
}