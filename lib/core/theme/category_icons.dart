import 'package:flutter/material.dart';

class CategoryIcons {
  static final Map<String, IconData> iconMap = {
    // Food & Drink
    'fastfood': Icons.fastfood,
    'restaurant': Icons.restaurant,
    'local_cafe': Icons.local_cafe,
    'local_bar': Icons.local_bar,
    'icecream': Icons.icecream,
    'cake': Icons.cake,
    
    // Housing & Utilities
    'home': Icons.home,
    'power': Icons.power,
    'water_drop': Icons.water_drop,
    'wifi': Icons.wifi,
    'tv': Icons.tv,
    'cleaning_services': Icons.cleaning_services,
    'construction': Icons.construction,
    
    // Transportation
    'directions_bus': Icons.directions_bus,
    'directions_car': Icons.directions_car,
    'local_taxi': Icons.local_taxi,
    'flight': Icons.flight,
    'train': Icons.train,
    'local_gas_station': Icons.local_gas_station,
    'motorcycle': Icons.motorcycle,
    
    // Entertainment & Leisure
    'movie': Icons.movie,
    'sports_esports': Icons.sports_esports,
    'music_note': Icons.music_note,
    'brush': Icons.brush,
    'pool': Icons.pool,
    'celebration': Icons.celebration,
    'sports_soccer': Icons.sports_soccer,
    
    // Shopping & Personal Care
    'shopping_bag': Icons.shopping_bag,
    'shopping_cart': Icons.shopping_cart,
    'store': Icons.store,
    'checkroom': Icons.checkroom,
    'face': Icons.face,
    'spa': Icons.spa,
    'watch': Icons.watch,
    
    // Education & Kids
    'school': Icons.school,
    'book': Icons.book,
    'child_care': Icons.child_care,
    'toys': Icons.toys,
    
    // Health & Wellness
    'local_hospital': Icons.local_hospital,
    'medical_services': Icons.medical_services,
    'fitness_center': Icons.fitness_center,
    'healing': Icons.healing,
    
    // Financial & Income
    'payments': Icons.payments,
    'account_balance': Icons.account_balance,
    'credit_card': Icons.credit_card,
    'monetization_on': Icons.monetization_on,
    'trending_up': Icons.trending_up,
    'savings': Icons.savings,
    'work': Icons.work,
    'business_center': Icons.business_center,
    'account_balance_wallet': Icons.account_balance_wallet,
    
    // Others/Miscellaneous
    'category': Icons.category,
    'pets': Icons.pets,
    'card_giftcard': Icons.card_giftcard,
    'local_shipping': Icons.local_shipping,
    'phone_iphone': Icons.phone_iphone,
    'build': Icons.build,
    'umbrella': Icons.umbrella,
  };

  static IconData getIcon(String key) {
    return iconMap[key] ?? Icons.category;
  }

  static List<String> get keys => iconMap.keys.toList();
}
