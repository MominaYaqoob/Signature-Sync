package com.sid.signature.maker

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // #region agent log
        Log.e("SigSyncDebug", "{\"sessionId\":\"28faf2\",\"hypothesisId\":\"C\",\"location\":\"MainActivity.kt:onCreate\",\"message\":\"native_onCreate\",\"timestamp\":${System.currentTimeMillis()}}")
        // #endregion
        super.onCreate(savedInstanceState)
        // #region agent log
        Log.e("SigSyncDebug", "{\"sessionId\":\"28faf2\",\"hypothesisId\":\"C\",\"location\":\"MainActivity.kt:onCreate\",\"message\":\"native_onCreate_after_super\",\"timestamp\":${System.currentTimeMillis()}}")
        // #endregion
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "nativeAdSmall",
            NativeAdSmallFactory(layoutInflater),
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "nativeAdSmall")
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
