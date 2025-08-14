import '../../domain/repositories/asset_repository.dart';
import '../datasources/asset_datasource.dart';

class AssetRepositoryImpl implements AssetRepository {
  final AssetDatasource ds;
  AssetRepositoryImpl(this.ds);
  @override
  Future<List<String>> listAll() => ds.listAllAssets();
}
