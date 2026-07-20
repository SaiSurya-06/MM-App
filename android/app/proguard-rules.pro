# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native plugins
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class es.antonborri.home_widget.** { *; }
-keep class com.tekartik.sqflite.** { *; }

-dontwarn kotlin.time.**
-dontwarn org.kxml2.**
-dontwarn org.xmlpull.v1.**
-dontwarn com.google.auth.oauth2.**
-dontwarn com.google.api.client.**
