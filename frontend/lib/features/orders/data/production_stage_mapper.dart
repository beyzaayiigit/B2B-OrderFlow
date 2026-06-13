/// DB `production_stage` ↔ ekrandaki Türkçe aşama adları.
class ProductionStageMapper {
  ProductionStageMapper._();

  static String? toUi(String? db) {
    if (db == null || db.isEmpty) return null;
    return switch (db) {
      'cutting' => 'Kesim',
      'sewing' => 'Dikim',
      'packing' => 'Paketleme',
      'logistics' => 'Lojistik',
      _ => null,
    };
  }

  static String? toDb(String? ui) {
    if (ui == null || ui.isEmpty) return null;
    return switch (ui) {
      'Kesim' => 'cutting',
      'Dikim' => 'sewing',
      'Paketleme' => 'packing',
      'Lojistik' => 'logistics',
      _ => null,
    };
  }
}
