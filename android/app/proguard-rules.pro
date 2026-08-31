# Flutter's Gradle plugin and the Android plugins provide their own consumer
# R8 rules. Broad `-keep` rules here prevented R8 from removing unused SDK and
# Kotlin code, substantially inflating the release APK.
#
# Add a narrowly scoped rule here only if a verified release-device failure
# requires it. Keeping this file free of blanket rules lets the optimizer
# safely shrink each supported plugin to the code it actually uses.
