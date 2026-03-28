# Flutter-specific ProGuard rules
# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep application entry points
-keep class com.fsm.fsm_frontend.** { *; }

# Keep annotations
-keepattributes *Annotation*

# Suppress notes about reflection
-dontnote io.flutter.**
