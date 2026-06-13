/// UI metinleri ↔ Supabase `catalog_status` enum.
abstract final class CatalogStatusMapper {
  static const uiDraft = 'Taslak';
  static const uiPublished = 'Yayında';

  static String toUi(String dbStatus) {
    switch (dbStatus) {
      case 'draft':
        return uiDraft;
      case 'published':
        return uiPublished;
      default:
        return uiPublished;
    }
  }

  static String toDb(String uiStatus) {
    switch (uiStatus) {
      case uiDraft:
        return 'draft';
      case uiPublished:
        return 'published';
      default:
        if (uiStatus == 'Stokta' || uiStatus == 'Numune') return 'published';
        return 'draft';
    }
  }

  static bool isVisibleToBuyer(String uiStatus) => uiStatus != uiDraft;
}
