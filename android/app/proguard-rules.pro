# Proguard rules for app size reduction (Phase 7 Sprint)
# These rules preserve Flutter and Firebase functionality while removing unused code

# Keep Flutter entry points
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep interface com.google.firebase.** { *; }

# Keep Firestore
-keep class com.google.cloud.firestore.** { *; }

# Keep model/serialization classes (adjust package name if needed)
-keep class com.example.shop.** { *; }

# Preserve native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Preserve Parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep R classes and their members for resource references
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Suppress some known non-critical warnings
-dontwarn android.**
-dontwarn com.google.**
-dontwarn com.squareup.**
-dontwarn okhttp3.**
-dontwarn okio.**

# Optimize
-optimizationpasses 5
-allowaccessmodification
