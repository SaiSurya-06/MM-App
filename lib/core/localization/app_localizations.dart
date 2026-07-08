import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

const Map<String, Map<String, String>> _localizedValues = {
  'en': {
    'settings': 'Settings',
    'preferred_currency': 'Preferred Currency',
    'dark_mode': 'Dark Mode',
    'biometric_login': 'Biometric Login',
    'daily_reminder': 'Daily Reminder',
    'reminder_time': 'Reminder Time',
    'backup_restore': 'Backup & Restore',
    'sign_out': 'Sign Out',
    'language': 'Language',
    'money_manager': 'Money Manager',
    'accounts': 'Accounts',
    'transactions': 'Transactions',
    'budgets': 'Budgets',
    'overview': 'Overview',
    'savings_goals': 'Savings Goals',
    'debts_loans': 'Debts & Loans',
    'category': 'Category',
    'amount': 'Amount',
    'title': 'Title',
    'add_transaction': 'Add Transaction',
    'name': 'Name',
    'edit_profile': 'Edit Profile',
    'save': 'Save',
    'cancel': 'Cancel',
    'security': 'Security',
    'notifications': 'Notifications',
    'dashboard': 'Dashboard',
    'more': 'More',
    'total_balance': 'Total Balance',
    'monthly_spend': 'Monthly Spend',
    'monthly_income': 'Monthly Income',
    'active_budgets': 'Active Budgets',
    'net_worth': 'Net Worth',
    'recent_transactions': 'Recent Transactions',
    'view_all': 'View All',
    'edit': 'Edit',
    'delete': 'Delete',
    'confirm': 'Confirm',
    'retry': 'Retry',
    'refresh': 'Refresh',
    'sync_now': 'Sync Now',
    'disconnect': 'Disconnect',
    'profile_settings': 'Profile Settings',
    'theme_preferences': 'Theme Preferences',
    'database_backup': 'Database Backup',
    'backup_database': 'Backup Database',
    'restore_database': 'Restore Database',
    'security_biometrics': 'Security & Biometrics',
    'account': 'Account',
    'date': 'Date',
    'note': 'Note',
    'recurrence': 'Recurrence',
    'tags': 'Tags',
    'is_private': 'Private',
    'transfer_to_account': 'Transfer to Account',
    'budget_limit': 'Limit',
    'budget_remaining': 'Remaining',
    'overspent': 'Overspent',
    'rolled_over': 'Rolled Over',
    'good_morning': 'Good Morning',
    'good_afternoon': 'Good Afternoon',
    'good_evening': 'Good Evening',
    'hello': 'Hello',
  },
  'es': {
    'settings': 'Configuración',
    'preferred_currency': 'Moneda Preferida',
    'dark_mode': 'Modo Oscuro',
    'biometric_login': 'Inicio Biométrico',
    'daily_reminder': 'Recordatorio Diario',
    'reminder_time': 'Hora del Recordatorio',
    'backup_restore': 'Copia de Seguridad',
    'sign_out': 'Cerrar Sesión',
    'language': 'Idioma',
    'money_manager': 'Gestor de Dinero',
    'accounts': 'Cuentas',
    'transactions': 'Transacciones',
    'budgets': 'Presupuestos',
    'overview': 'Resumen',
    'savings_goals': 'Metas de Ahorro',
    'debts_loans': 'Deudas y Préstamos',
    'category': 'Categoría',
    'amount': 'Cantidad',
    'title': 'Título',
    'add_transaction': 'Agregar Transacción',
    'name': 'Nombre',
    'edit_profile': 'Editar Perfil',
    'save': 'Guardar',
    'cancel': 'Cancelar',
    'security': 'Seguridad',
    'notifications': 'Notificaciones',
    'dashboard': 'Tablero',
    'more': 'Más',
    'total_balance': 'Saldo Total',
    'monthly_spend': 'Gasto Mensual',
    'monthly_income': 'Ingreso Mensual',
    'active_budgets': 'Presupuestos Activos',
    'net_worth': 'Patrimonio Neto',
    'recent_transactions': 'Transacciones Recientes',
    'view_all': 'Ver Todo',
    'edit': 'Editar',
    'delete': 'Eliminar',
    'confirm': 'Confirmar',
    'retry': 'Reintentar',
    'refresh': 'Actualizar',
    'sync_now': 'Sincronizar Ahora',
    'disconnect': 'Desconectar',
    'profile_settings': 'Ajustes de Perfil',
    'theme_preferences': 'Preferencias de Tema',
    'database_backup': 'Copia de Seguridad de Base de Datos',
    'backup_database': 'Copia de Seguridad de Base de Datos',
    'restore_database': 'Restaurar Base de Datos',
    'security_biometrics': 'Seguridad y Biometría',
    'account': 'Cuenta',
    'date': 'Fecha',
    'note': 'Nota',
    'recurrence': 'Recurrencia',
    'tags': 'Etiquetas',
    'is_private': 'Privado',
    'transfer_to_account': 'Transferir a Cuenta',
    'budget_limit': 'Límite',
    'budget_remaining': 'Restante',
    'overspent': 'Sobregastado',
    'rolled_over': 'Traspasado',
    'good_morning': 'Buenos Días',
    'good_afternoon': 'Buenas Tardes',
    'good_evening': 'Buenas Noches',
    'hello': 'Hola',
  },
  'hi': {
    'settings': 'सेटिंग्स',
    'preferred_currency': 'पसंदीदा मुद्रा',
    'dark_mode': 'डार्क मोड',
    'biometric_login': 'बायोमेट्रिक लॉगिन',
    'daily_reminder': 'दैनिक अनुस्मारक',
    'reminder_time': 'अनुस्मारक समय',
    'backup_restore': 'बैकअप और पुनर्स्थापना',
    'sign_out': 'साइन आउट',
    'language': 'भाषा',
    'money_manager': 'मनी मैनेजर',
    'accounts': 'खाते',
    'transactions': 'लेन-देन',
    'budgets': 'बजट',
    'overview': 'अवलोकन',
    'savings_goals': 'बचत लक्ष्य',
    'debts_loans': 'ऋण और उधार',
    'category': 'श्रेणी',
    'amount': 'राशि',
    'title': 'शीर्षक',
    'add_transaction': 'लेन-देन जोड़ें',
    'name': 'नाम',
    'edit_profile': 'प्रोफाइल संपादित करें',
    'save': 'सहेजें',
    'cancel': 'रद्द करें',
    'security': 'सुरक्षा',
    'notifications': 'सूचनाएं',
    'dashboard': 'डैशबोर्ड',
    'more': 'अधिक',
    'total_balance': 'कुल शेष',
    'monthly_spend': 'मासिक खर्च',
    'monthly_income': 'मासिक आय',
    'active_budgets': 'सक्रिय बजट',
    'net_worth': 'कुल संपत्ति',
    'recent_transactions': 'हाल के लेन-देन',
    'view_all': 'सभी देखें',
    'edit': 'संपादित करें',
    'delete': 'हटाएं',
    'confirm': 'पुष्टि करें',
    'retry': 'पुनः प्रयास करें',
    'refresh': 'रीफ्रेश करें',
    'sync_now': 'अभी सिंक करें',
    'disconnect': 'डिसकनेक्ट करें',
    'profile_settings': 'प्रोफ़ाइल सेटिंग्स',
    'theme_preferences': 'थीम प्राथमिकताएं',
    'database_backup': 'डेटाबेस बैकअप',
    'backup_database': 'बैकअप डेटाबेस',
    'restore_database': 'डेटाबेस पुनर्स्थापित करें',
    'security_biometrics': 'सुरक्षा और बायोमेट्रिक्स',
    'account': 'खाता',
    'date': 'तिथि',
    'note': 'नोट',
    'recurrence': 'पुनरावृत्ति',
    'tags': 'टैग',
    'is_private': 'निजी',
    'transfer_to_account': 'खाते में स्थानांतरण',
    'budget_limit': 'सीमा',
    'budget_remaining': 'शेष',
    'overspent': 'अधिक खर्च',
    'rolled_over': 'रोल ओवर',
    'good_morning': 'सुप्रभात',
    'good_afternoon': 'शुभ दोपहर',
    'good_evening': 'शुभ संध्या',
    'hello': 'नमस्ते',
  }
};

class LocaleNotifier extends StateNotifier<String> {
  LocaleNotifier() : super('en') {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/language.txt');
      if (await file.exists()) {
        final savedLocale = await file.readAsString();
        if (_localizedValues.containsKey(savedLocale)) {
          state = savedLocale;
        }
      }
    } catch (_) {}
  }

  Future<void> setLocale(String locale) async {
    if (_localizedValues.containsKey(locale)) {
      state = locale;
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/language.txt');
        await file.writeAsString(locale);
      } catch (_) {}
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  return LocaleNotifier();
});

extension TranslationExtension on String {
  String tr(WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return _localizedValues[locale]?[this] ?? this;
  }
}
