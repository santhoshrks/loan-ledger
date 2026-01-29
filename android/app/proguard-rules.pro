# Flutter ProGuard Rules

# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }

# Keep Flutter engine
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.view.** { *; }

# Hive - Local database
-keep class com.hive.** { *; }
-keep interface com.hive.** { *; }
-keepclassmembers class * extends com.hive.HiveObject {
  *** get*();
  *** set*(...);
}

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ===== FLUTTER LOCAL NOTIFICATIONS - CRITICAL =====
# Keep the notification plugin and all its classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep interface com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }

# Keep Gson classes (required for notification serialization)
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Keep TypeToken generic signature for Gson
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# Prevent R8 from stripping generic type information
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep notification models
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# Google Play Core (optional - don't crash if missing)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Remove logging in release build
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
