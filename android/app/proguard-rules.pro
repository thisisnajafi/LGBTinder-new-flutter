# R8/ProGuard rules for release build.
# Generated missing rule (Agora SDK references desugar runtime class not in our classpath):
-dontwarn com.google.devtools.build.android.desugar.runtime.ThrowableExtension

# SLF4J binding is optional at runtime (referenced by some SDKs/plugins).
-dontwarn org.slf4j.impl.StaticLoggerBinder

# Keep Agora SDK classes used via reflection (avoids R8 stripping)
-keep class io.agora.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
