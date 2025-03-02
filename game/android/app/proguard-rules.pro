# Flutter-specific rules
-keep class io.flutter.** { *; }
-keep class com.example.** { *; }
-keep class com.google.** { *; }

# Keep application classes
-keep class com.yourpackage.** { *; }

# Avoid stripping Kotlin metadata
-keep class kotlin.Metadata { *; }
