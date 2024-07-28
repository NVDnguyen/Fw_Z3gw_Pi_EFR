-keep class my.package.name.** { *; }
-keepclassmembers class * {
    @my.package.name.annotations.KeepMembers *;
}

-keepclassmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}

-keepclassmembers class **.R$* {
    public static <fields>;
}

-keepattributes *Annotation*
