# R8/ProGuard rules for release build.
# Generated missing rule (Agora SDK references desugar runtime class not in our classpath):
-dontwarn com.google.devtools.build.android.desugar.runtime.ThrowableExtension

# Keep Agora SDK classes used via reflection (avoids R8 stripping)
-keep class io.agora.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
