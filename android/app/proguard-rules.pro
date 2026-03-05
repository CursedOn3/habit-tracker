# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Hive
-keep class com.example.habit_tracker.** { *; }

# Keep model classes
-keep class ** extends com.google.gson.reflect.TypeToken { *; }
-keep class * implements java.io.Serializable { *; }

# Prevent R8 from stripping interface information
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# For native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
