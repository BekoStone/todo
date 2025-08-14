import '../../domain/entities/block_entity.dart';

class BlockModel {
  final int value;
  const BlockModel(this.value);

  BlockEntity toEntity() => BlockEntity(value);
}
