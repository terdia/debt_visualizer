# Flutter specific ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Keep your application classes that use native methods
-keep class com.debtfree.visualizer.** { *; }

# Handle Play Core library compatibility with Android 14
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Supabase & GoTrue authentication related classes
-keep class io.github.jan.supabase.** { *; }
-keep class com.supabase.** { *; }

# Hive database
-keep class com.hivedb.** { *; }
-keep class hive.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep the R class and its fields
-keep class **.R
-keep class **.R$* {
    <fields>;
}

# Keep annotated classes and methods
-keepattributes *Annotation*

# Some general rules to avoid common issues
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
-dontwarn java.awt.**
-dontwarn javax.**

# Prevent R8 from stripping information about enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
