/// Cached template catalog (PERF-SCR-TEMPL-001).
class ProfileTemplate {
  const ProfileTemplate({
    required this.id,
    required this.name,
    required this.description,
    this.previewImage,
    this.isPremium = false,
  });

  final String id;
  final String name;
  final String description;
  final String? previewImage;
  final bool isPremium;
}

class ProfileTemplateCatalog {
  ProfileTemplateCatalog._();

  static const List<ProfileTemplate> defaults = [
    ProfileTemplate(
      id: '1',
      name: 'Classic',
      description: 'Traditional profile layout',
    ),
    ProfileTemplate(
      id: '2',
      name: 'Modern',
      description: 'Clean and minimalist design',
    ),
    ProfileTemplate(
      id: '3',
      name: 'Creative',
      description: 'Bold and expressive style',
      isPremium: true,
    ),
    ProfileTemplate(
      id: '4',
      name: 'Professional',
      description: 'Business-focused layout',
      isPremium: true,
    ),
  ];

  static List<ProfileTemplate>? _memory;

  static List<ProfileTemplate> cached() {
    return _memory ??= List<ProfileTemplate>.unmodifiable(defaults);
  }

  static void resetForTest() {
    _memory = null;
  }
}
