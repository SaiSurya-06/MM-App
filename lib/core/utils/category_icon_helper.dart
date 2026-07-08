import 'package:flutter/material.dart';

class CategoryIconHelper {
  static final Map<String, IconData> _icons = {
    'fastfood': Icons.fastfood,
    'home': Icons.home,
    'payments': Icons.payments,
    'directions_bus': Icons.directions_bus,
    'movie': Icons.movie,
    'local_hospital': Icons.local_hospital,
    'power': Icons.power,
    'category': Icons.category,
    'swap_horiz': Icons.swap_horiz,
    'shopping_cart': Icons.shopping_cart,
    'work': Icons.work,
    'card_giftcard': Icons.card_giftcard,
    'flight': Icons.flight,
    'pets': Icons.pets,
    'school': Icons.school,
    'fitness_center': Icons.fitness_center,
    'sports_esports': Icons.sports_esports,
    'shopping_bag': Icons.shopping_bag,
    'business': Icons.business,
    'restaurant': Icons.restaurant,
    'coffee': Icons.coffee,
    'savings': Icons.savings,
    'build': Icons.build,
    'brush': Icons.brush,
    'volunteer_activism': Icons.volunteer_activism,
    'theater_comedy': Icons.theater_comedy,
    'medical_services': Icons.medical_services,
    'wallet': Icons.wallet,
    'monetization_on': Icons.monetization_on,
    'phone_android': Icons.phone_android,
    'water_drop': Icons.water_drop,
    'electrical_services': Icons.electrical_services,
    'directions_car': Icons.directions_car,
  };

  /// Returns the IconData associated with the given name, falling back to a default coin icon.
  static IconData getIcon(String name) {
    return _icons[name] ?? Icons.monetization_on;
  }

  /// List of icon names suitable for user custom categories.
  static List<String> getSelectableIcons() {
    return [
      'fastfood',
      'home',
      'payments',
      'directions_bus',
      'movie',
      'local_hospital',
      'power',
      'category',
      'shopping_cart',
      'work',
      'card_giftcard',
      'flight',
      'pets',
      'school',
      'fitness_center',
      'sports_esports',
      'shopping_bag',
      'business',
      'restaurant',
      'coffee',
      'savings',
      'build',
      'brush',
      'volunteer_activism',
      'theater_comedy',
      'medical_services',
      'wallet',
      'phone_android',
      'water_drop',
      'directions_car',
    ];
  }
}
