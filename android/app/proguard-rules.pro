# VidGrab ProGuard Rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep model classes
-keep class com.vidgrab.app.models.** { *; }
-keep class com.vidgrab.app.services.** { *; }

# HTTP
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Gson / JSON
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }

# Keep platform channel
-keep class * implements io.flutter.plugin.common.PluginRegistry$PluginRegistrantCallback { *; }