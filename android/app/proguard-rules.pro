# R8/ProGuard rules for release build.
# Generated missing rule (Agora SDK references desugar runtime class not in our classpath):
-dontwarn com.google.devtools.build.android.desugar.runtime.ThrowableExtension

# SLF4J binding is optional at runtime (referenced by some SDKs/plugins).
-dontwarn org.slf4j.impl.StaticLoggerBinder

# Keep Agora SDK classes used via reflection (avoids R8 stripping)
-keep class io.agora.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Flutter / plugins
-keep class io.flutter.** { *; }
-keep class com.google.firebase.** { *; }
-keep class androidx.lifecycle.** { *; }

# Flutter deferred components reference Play Core (optional; not used in this app)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
