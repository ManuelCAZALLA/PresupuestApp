# Android

Native Android application using Kotlin and Jetpack Compose. The pure Kotlin
domain module contains the Android implementation of quote calculation; its
tests consume the same TSV contract fixture as `QuoteCore` on iOS.

Open this directory in Android Studio and sync Gradle. Current setup targets
Android 8.0 (API 26) or newer; the minimum version is provisional (Q-010).

Run the domain tests with:

```sh
./gradlew :domain:test
```

The local Android SDK must be installed. The current prototype supports manual
catalog entry, draft quotes with catalog snapshots, VAT/percentage discount
calculation, and local PDF sharing. Business profile, imports, quote editing,
and final PDF styling remain future milestones.
