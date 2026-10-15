import '../widgets/pooja_detail_modal.dart';

/// Helper to map carousel banner slides to valid, verified PoojaDetail entities.
/// Prevents legacy slugs or unverified identifiers from silently defaulting to
/// incorrect rituals or failing backend UUID validation.
class CarouselPoojaMapper {
  /// Verified mapping of legacy/semantic slugs to genuine database UUIDs
  static const Map<String, String> legacySlugToUuid = {
    'navratri_pooja': '67e77a47-8ffb-403a-bc64-c948ab5e2abc',
    'navratri-pooja': '67e77a47-8ffb-403a-bc64-c948ab5e2abc',
    'satyanarayan_katha': '92086a65-41a9-4545-9588-6f35c8bb8b6b',
    'satyanarayan-katha': '92086a65-41a9-4545-9588-6f35c8bb8b6b',
    'griha_pravesh_pooja': '9ae802b2-95f9-4461-af5a-e7c32d6fb1af',
    'griha-pravesh-pooja': '9ae802b2-95f9-4461-af5a-e7c32d6fb1af',
    'mahamrityunjaya_jaap': '9484cd34-05de-4b00-9621-b190d075be33',
    'mahamrityunjaya-jaap': '9484cd34-05de-4b00-9621-b190d075be33',
    'vastu_shanti_pooja': 'ec3b0465-06c0-4621-addc-d2e6fbcb2291',
    'vastu-shanti-pooja': 'ec3b0465-06c0-4621-addc-d2e6fbcb2291',
  };

  /// Resolves the corresponding [PoojaDetail] for a given carousel slide map.
  ///
  /// Searches through [availablePoojas] by exact UUID, mapped legacy slug,
  /// or known ritual keywords.
  ///
  /// Returns `null` if no verified mapping exists, rather than silently defaulting
  /// to an incorrect ritual.
  static PoojaDetail? findPoojaForSlide(
    Map<String, String> slide,
    List<PoojaDetail> availablePoojas,
  ) {
    final rawId = slide['poojaId']?.trim() ?? '';
    final slug = slide['slug']?.trim() ?? '';
    final title = slide['title']?.toLowerCase().trim() ?? '';

    if (rawId.isEmpty && slug.isEmpty && title.isEmpty) {
      return null;
    }

    final targetUuid = legacySlugToUuid[rawId] ?? rawId;

    // 1. Match by exact UUID or target identifier
    for (final p in availablePoojas) {
      if (p.id.toLowerCase() == targetUuid.toLowerCase()) {
        return p;
      }
    }

    // 2. Match by slug if provided in slide
    if (slug.isNotEmpty) {
      final slugUuid = legacySlugToUuid[slug];
      for (final p in availablePoojas) {
        if (p.id.toLowerCase() == slugUuid?.toLowerCase()) {
          return p;
        }
      }
    }

    // 3. Match by semantic title keywords
    if (title.isNotEmpty) {
      for (final p in availablePoojas) {
        final pTitle = p.title.toLowerCase();
        if ((title.contains('navratri') && pTitle.contains('navratri')) ||
            (title.contains('satyanarayan') && pTitle.contains('satyanarayan')) ||
            (title.contains('griha pravesh') && pTitle.contains('griha pravesh')) ||
            (title.contains('mahamrityunjaya') && pTitle.contains('mahamrityunjaya'))) {
          return p;
        }
      }
    }

    // Unmapped: DO NOT fall back to an arbitrary ritual!
    return null;
  }
}
