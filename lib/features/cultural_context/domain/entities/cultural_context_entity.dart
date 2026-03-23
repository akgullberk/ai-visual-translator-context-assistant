class CulturalContextEntity {
  const CulturalContextEntity({
    required this.value,
  });

  /// LLM'den gelen kültürel bağlam çıktısı (genelde JSON'dan ayıklanmış metin).
  final String value;
}

