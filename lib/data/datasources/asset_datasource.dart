abstract class AssetDatasource {
  Future<List<String>> listAllAssets();
}

class AssetDatasourceImpl implements AssetDatasource {
  @override
  Future<List<String>> listAllAssets() async {
    // If you need to parse AssetManifest.json later, wire it here.
    // For now, repository provides concrete asset list via constants/usecase.
    return [
      'assets/images/logo.png',
      'assets/images/block.png',
      'assets/images/grid.png',
      'assets/audio/click.mp3',
      'assets/audio/clear.mp3',
      'assets/audio/bgm.mp3',
      'assets/animations/spark.json',
    ];
  }
}
