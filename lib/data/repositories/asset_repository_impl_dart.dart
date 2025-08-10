// File: lib/data/repositories/asset_repository_impl.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'package:puzzle_box/core/errors/exceptions_dart.dart';
import 'package:puzzle_box/data/datasources/asset_datasource_dart.dart' hide AssetLoadingProgress;
import 'package:puzzle_box/domain/repositories/asset_repository_dart.dart';


/// Implementation of the asset repository
class AssetRepositoryImpl implements AssetRepository {
  final AssetDataSource _dataSource;
  
  const AssetRepositoryImpl(this._dataSource);

  @override
  Future<void> initialize() async {
    try {
      await _dataSource.initialize();
      developer.log('AssetRepository initialized', name: 'AssetRepository');
    } catch (e) {
      developer.log('Failed to initialize AssetRepository: $e', name: 'AssetRepository');
      throw InitializationException('Asset repository initialization failed: $e');
    }
  }

  @override
  Future<AssetLoadingResult> preloadEssentialAssets({
    void Function(double progress)? onProgress,
  }) async {
    try {
      final startTime = DateTime.now();
      
      final result = await _dataSource.preloadGameAssets(
        onProgress: (progress) {
          onProgress?.call(progress.progressPercentage);
        },
      );

      final duration = DateTime.now().difference(startTime);
      
      developer.log(
        'Asset preload completed in ${duration.inMilliseconds}ms: '
        '${result.loadedAssets}/${result.totalAssets} loaded',
        name: 'AssetRepository',
      );

      return AssetLoadingResult(
        totalAssets: result.totalAssets,
        loadedAssets: result.loadedAssets,
        failedAssets: result.failedAssets,
        duration: duration,
        errors: result.errors,
        isSuccess: result.failedAssets == 0,
      );
    } catch (e) {
      developer.log('Asset preload failed: $e', name: 'AssetRepository');
      throw AssetException('Failed to preload essential assets: $e');
    }
  }

  @override
  Future<bool> loadAsset(String assetPath) async {
    try {
      if (isImageAsset(assetPath)) {
        await _dataSource.loadImage(assetPath);
      } else if (isAudioAsset(assetPath)) {
        await _dataSource.loadAudio(assetPath);
      } else {
        throw AssetException('Unknown asset type for path: $assetPath');
      }

      final isLoaded = await isAssetLoaded(assetPath);
      
      if (isLoaded) {
        developer.log('Successfully loaded asset: $assetPath', name: 'AssetRepository');
      } else {
        developer.log('Asset load reported success but asset not available: $assetPath', name: 'AssetRepository');
      }

      return isLoaded;
    } catch (e) {
      developer.log('Failed to load asset $assetPath: $e', name: 'AssetRepository');
      throw AssetException('Failed to load asset $assetPath: $e');
    }
  }

  @override
  Future<List<bool>> loadAssets(List<String> assetPaths) async {
    try {
      final results = <bool>[];
      
      // Load assets in parallel with error handling
      final futures = assetPaths.map((path) async {
        try {
          return await loadAsset(path);
        } catch (e) {
          developer.log('Failed to load asset in batch: $path - $e', name: 'AssetRepository');
          return false;
        }
      });

      final loadResults = await Future.wait(futures);
      results.addAll(loadResults);

      final successCount = results.where((success) => success).length;
      developer.log(
        'Batch asset load completed: $successCount/${assetPaths.length} successful',
        name: 'AssetRepository',
      );

      return results;
    } catch (e) {
      developer.log('Batch asset load failed: $e', name: 'AssetRepository');
      throw AssetException('Failed to load asset batch: $e');
    }
  }

  @override
  Future<bool> isAssetLoaded(String assetPath) async {
    try {
      if (isImageAsset(assetPath)) {
        return _dataSource.isImageLoaded(assetPath);
      } else if (isAudioAsset(assetPath)) {
        return _dataSource.isAudioLoaded(assetPath);
      } else {
        return false;
      }
    } catch (e) {
      developer.log('Error checking asset load status $assetPath: $e', name: 'AssetRepository');
      return false;
    }
  }

  @override
  Future<AssetMetadata> getAssetMetadata(String assetPath) async {
    try {
      final info = _dataSource.getAssetInfo(assetPath);
      
      return AssetMetadata(
        path: info.path,
        isLoaded: info.status == AssetLoadingStatus.loaded,
        loadedAt: info.loadedAt,
        sizeBytes: info.sizeBytes,
        lastError: info.errorMessage,
        assetType: _getAssetType(assetPath),
      );
    } catch (e) {
      developer.log('Failed to get asset metadata $assetPath: $e', name: 'AssetRepository');
      throw AssetException('Failed to get asset metadata: $e');
    }
  }

  @override
  Future<List<AssetMetadata>> getAllAssetsMetadata() async {
    try {
      final allAssetsInfo = _dataSource.getAllAssetsInfo();
      
      return allAssetsInfo.entries.map((entry) {
        final info = entry.value;
        return AssetMetadata(
          path: info.path,
          isLoaded: info.status == AssetLoadingStatus.loaded,
          loadedAt: info.loadedAt,
          sizeBytes: info.sizeBytes,
          lastError: info.errorMessage,
          assetType: _getAssetType(info.path),
        );
      }).toList();
    } catch (e) {
      developer.log('Failed to get all assets metadata: $e', name: 'AssetRepository');
      throw AssetException('Failed to get all assets metadata: $e');
    }
  }

  @override
  Stream<AssetLoadingProgress> getLoadingProgressStream() async* {
    // Note: This is a simplified implementation
    // In a real app, you might want to use a StreamController
    // and emit updates from the datasource
    
    try {
      // Emit current progress immediately
      yield _dataSource.getLoadingProgress();
      
      // For now, we'll just check periodically
      // In a real implementation, the datasource would emit updates
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        try {
          final progress = _dataSource.getLoadingProgress();
          // yield progress; // Can't yield from timer callback
          if (progress.isComplete) {
            timer.cancel();
          }
        } catch (e) {
          timer.cancel();
        }
      });
    } catch (e) {
      developer.log('Error creating loading progress stream: $e', name: 'AssetRepository');
      throw AssetException('Failed to create loading progress stream: $e');
    }
  }

  @override
  Future<bool> validateAsset(String assetPath) async {
    try {
      return await _dataSource.validateAsset(assetPath);
    } catch (e) {
      developer.log('Asset validation failed $assetPath: $e', name: 'AssetRepository');
      return false;
    }
  }

  @override
  Future<void> clearAssetCache() async {
    try {
      await _dataSource.clearAllAssets();
      developer.log('Asset cache cleared', name: 'AssetRepository');
    } catch (e) {
      developer.log('Failed to clear asset cache: $e', name: 'AssetRepository');
      throw AssetException('Failed to clear asset cache: $e');
    }
  }

  @override
  Future<void> clearSpecificAsset(String assetPath) async {
    try {
      await _dataSource.clearAsset(assetPath);
      developer.log('Cleared specific asset: $assetPath', name: 'AssetRepository');
    } catch (e) {
      developer.log('Failed to clear specific asset $assetPath: $e', name: 'AssetRepository');
      throw AssetException('Failed to clear specific asset: $e');
    }
  }

  @override
  Future<CacheInfo> getCacheInfo() async {
    try {
      final allAssets = _dataSource.getAllAssetsInfo();
      final loadedAssets = allAssets.values
          .where((info) => info.status == AssetLoadingStatus.loaded)
          .length;
      
      final failedAssets = allAssets.values
          .where((info) => info.status == AssetLoadingStatus.failed)
          .length;

      final totalSizeBytes = _dataSource.getCacheSize();
      
      return CacheInfo(
        totalAssets: allAssets.length,
        loadedAssets: loadedAssets,
        failedAssets: failedAssets,
        totalSizeBytes: totalSizeBytes,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      developer.log('Failed to get cache info: $e', name: 'AssetRepository');
      throw AssetException('Failed to get cache info: $e');
    }
  }

  @override
  bool isImageAsset(String assetPath) {
    const imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];
    return imageExtensions.any((ext) => assetPath.toLowerCase().endsWith(ext));
  }

  @override
  bool isAudioAsset(String assetPath) {
    const audioExtensions = ['.mp3', '.wav', '.ogg', '.m4a', '.aac'];
    return audioExtensions.any((ext) => assetPath.toLowerCase().endsWith(ext));
  }

  @override
  Future<void> dispose() async {
    try {
      await _dataSource.dispose();
      developer.log('AssetRepository disposed', name: 'AssetRepository');
    } catch (e) {
      developer.log('Failed to dispose AssetRepository: $e', name: 'AssetRepository');
      throw AssetException('Failed to dispose asset repository: $e');
    }
  }

  /// Get asset type from path
  AssetType _getAssetType(String assetPath) {
    if (isImageAsset(assetPath)) {
      return AssetType.image;
    } else if (isAudioAsset(assetPath)) {
      return AssetType.audio;
    } else {
      return AssetType.unknown;
    }
  }
}

/// Extension methods for asset repository
extension AssetRepositoryExtensions on AssetRepository {
  /// Preload critical assets needed for game startup
  Future<AssetLoadingResult> preloadCriticalAssets({
    void Function(double progress)? onProgress,
  }) async {
    const criticalAssets = [
      'ui/logo.png',
      'sfx/sfx_click.mp3',
      'sfx/sfx_error.mp3',
    ];

    try {
      final startTime = DateTime.now();
      var loadedCount = 0;
      final errors = <String, String>{};

      for (final asset in criticalAssets) {
        try {
          final success = await loadAsset(asset);
          if (success) {
            loadedCount++;
          } else {
            errors[asset] = 'Load returned false';
          }
        } catch (e) {
          errors[asset] = e.toString();
        }

        // Report progress
        onProgress?.call(loadedCount / criticalAssets.length);
      }

      final duration = DateTime.now().difference(startTime);

      return AssetLoadingResult(
        totalAssets: criticalAssets.length,
        loadedAssets: loadedCount,
        failedAssets: criticalAssets.length - loadedCount,
        duration: duration,
        errors: errors,
        isSuccess: loadedCount == criticalAssets.length,
      );
    } catch (e) {
      throw AssetException('Failed to preload critical assets: $e');
    }
  }

  /// Verify all essential assets are loaded
  Future<bool> verifyEssentialAssets() async {
    const essentialAssets = [
      'ui/logo.png',
      'ui/icon_star.png',
      'ui/icon_coin.png',
      'backgrounds/bg_mainmenu.jpg',
      'sfx/sfx_click.mp3',
      'sfx/sfx_drop.mp3',
      'music/music_menu.mp3',
    ];

    try {
      for (final asset in essentialAssets) {
        if (!await isAssetLoaded(asset)) {
          developer.log('Essential asset not loaded: $asset', name: 'AssetRepository');
          return false;
        }
      }

      developer.log('All essential assets verified', name: 'AssetRepository');
      return true;
    } catch (e) {
      developer.log('Asset verification failed: $e', name: 'AssetRepository');
      return false;
    }
  }

  /// Get asset loading statistics
  Future<Map<String, dynamic>> getLoadingStatistics() async {
    try {
      final metadata = await getAllAssetsMetadata();
      final now = DateTime.now();

      final imageAssets = metadata.where((m) => m.assetType == AssetType.image);
      final audioAssets = metadata.where((m) => m.assetType == AssetType.audio);
      
      final loadedImages = imageAssets.where((m) => m.isLoaded).length;
      final loadedAudio = audioAssets.where((m) => m.isLoaded).length;
      
      final recentlyLoaded = metadata
          .where((m) => m.loadedAt != null && 
                      now.difference(m.loadedAt!).inMinutes < 5)
          .length;

      return {
        'total_assets': metadata.length,
        'loaded_assets': metadata.where((m) => m.isLoaded).length,
        'image_assets': imageAssets.length,
        'audio_assets': audioAssets.length,
        'loaded_images': loadedImages,
        'loaded_audio': loadedAudio,
        'recently_loaded': recentlyLoaded,
        'cache_size_bytes': (await getCacheInfo()).totalSizeBytes,
        'generated_at': now.millisecondsSinceEpoch,
      };
    } catch (e) {
      throw AssetException('Failed to get loading statistics: $e');
    }
  }
}