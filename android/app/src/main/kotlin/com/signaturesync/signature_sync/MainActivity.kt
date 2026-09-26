package com.signaturesync.signature_sync

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

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
}
