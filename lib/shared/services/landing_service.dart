import '../../core/constants/api_endpoints.dart';
import 'api_service.dart';

/// Landing (public) API data for about screen, contact, etc.
/// Routes 1–8 in API_DOCUMENTATION.md.
class LandingService {
  final ApiService _apiService;

  LandingService(this._apiService);

  /// GET landing/settings — app store URLs, tagline, features, FAQ (no auth).
  /// Backend returns { data: { app_store_url, ... } }; we unwrap data.
  Future<LandingSettings?> getSettings() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.landingSettings,
        fromJson: (json) => json as Map<String, dynamic>,
        useCache: true,
      );
      if (response.isSuccess && response.data != null) {
        final raw = response.data!;
        final inner = raw['data'] as Map<String, dynamic>?;
        return LandingSettings.fromJson(inner ?? raw);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// GET landing/blogs — list blog posts (no auth). Returns data array: slug, title, excerpt, date, image, category.
  Future<List<LandingBlogItem>> getBlogs() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.landingBlogs,
        fromJson: (json) => json as Map<String, dynamic>,
        useCache: true,
      );
      if (response.isSuccess && response.data != null) {
        final raw = response.data!;
        final list = raw['data'];
        if (list is List) {
          return list.map((e) => LandingBlogItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// GET landing/blogs/{slug} — single blog post (no auth). Returns slug, title, excerpt, body/content, date, etc.
  Future<LandingBlogItem?> getBlogBySlug(String slug) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.landingBlogBySlug(slug),
        fromJson: (json) => json as Map<String, dynamic>,
      );
      if (response.isSuccess && response.data != null) {
        final raw = response.data!;
        final inner = raw['data'] as Map<String, dynamic>?;
        return LandingBlogItem.fromJson(inner ?? raw);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// GET landing/stats — marketing/About stats (no auth). Returns data array: { key, value, label, icon }.
  Future<List<LandingStatItem>> getStats() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.landingStats,
        fromJson: (json) => json as Map<String, dynamic>,
        useCache: true,
      );
      if (response.isSuccess && response.data != null) {
        final raw = response.data!;
        final list = raw['data'];
        if (list is List) {
          return list.map((e) => LandingStatItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// GET landing/testimonials — testimonial quotes (no auth). Returns data array: { quote, author, location }.
  Future<List<LandingTestimonialItem>> getTestimonials() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.landingTestimonials,
        fromJson: (json) => json as Map<String, dynamic>,
        useCache: true,
      );
      if (response.isSuccess && response.data != null) {
        final raw = response.data!;
        final list = raw['data'];
        if (list is List) {
          return list.map((e) => LandingTestimonialItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// POST landing/contact — send contact form (no auth).
  /// Backend body: name, email, message (required); subject (optional).
  Future<bool> sendContact({
    required String name,
    required String email,
    required String message,
    String? subject,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'email': email,
        'message': message,
      };
      if (subject != null && subject.trim().isNotEmpty) body['subject'] = subject.trim();
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.landingContact,
        data: body,
        fromJson: (json) => json as Map<String, dynamic>,
      );
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }
}

/// Parsed GET landing/settings response (data object).
class LandingSettings {
  final String? appStoreUrl;
  final String? googlePlayUrl;
  final String? siteName;
  final String? tagline;
  final String? description;

  LandingSettings({
    this.appStoreUrl,
    this.googlePlayUrl,
    this.siteName,
    this.tagline,
    this.description,
  });

  factory LandingSettings.fromJson(Map<String, dynamic> json) {
    return LandingSettings(
      appStoreUrl: json['app_store_url']?.toString(),
      googlePlayUrl: json['google_play_url']?.toString(),
      siteName: json['site_name']?.toString(),
      tagline: json['tagline']?.toString(),
      description: json['description']?.toString(),
    );
  }
}

/// Single blog item from GET landing/blogs or GET landing/blogs/{slug}.
class LandingBlogItem {
  final String slug;
  final String? title;
  final String? excerpt;
  final String? date;
  final String? image;
  final String? category;
  final String? body;

  LandingBlogItem({
    required this.slug,
    this.title,
    this.excerpt,
    this.date,
    this.image,
    this.category,
    this.body,
  });

  factory LandingBlogItem.fromJson(Map<String, dynamic> json) {
    return LandingBlogItem(
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString(),
      excerpt: json['excerpt']?.toString(),
      date: json['date']?.toString(),
      image: json['image']?.toString(),
      category: json['category']?.toString(),
      body: json['body']?.toString(),
    );
  }
}

/// Single stat from GET landing/stats (key, value, label, icon).
class LandingStatItem {
  final String key;
  final String? value;
  final String? label;
  final String? icon;

  LandingStatItem({required this.key, this.value, this.label, this.icon});

  factory LandingStatItem.fromJson(Map<String, dynamic> json) {
    return LandingStatItem(
      key: json['key']?.toString() ?? '',
      value: json['value']?.toString(),
      label: json['label']?.toString(),
      icon: json['icon']?.toString(),
    );
  }
}

/// Single testimonial from GET landing/testimonials (quote, author, location).
class LandingTestimonialItem {
  final String? quote;
  final String? author;
  final String? location;

  LandingTestimonialItem({this.quote, this.author, this.location});

  factory LandingTestimonialItem.fromJson(Map<String, dynamic> json) {
    return LandingTestimonialItem(
      quote: json['quote']?.toString(),
      author: json['author']?.toString(),
      location: json['location']?.toString(),
    );
  }
}
