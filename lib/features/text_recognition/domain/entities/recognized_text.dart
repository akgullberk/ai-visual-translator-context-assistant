class RecognizedTextEntity {
  const RecognizedTextEntity({
    required this.value,
    required this.items,
  });

  final String value;
  final List<RecognizedTextItemEntity> items;
}

class RecognizedTextItemEntity {
  const RecognizedTextItemEntity({
    required this.value,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String value;
  final double left;
  final double top;
  final double right;
  final double bottom;
}
