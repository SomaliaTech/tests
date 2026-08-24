package com.yourcompany.farxada

import android.os.Bundle
import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsLogger
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        FacebookSdk.sdkInitialize(applicationContext)
        AppEventsLogger.activateApp(application)
        super.onCreate(savedInstanceState)
    }
}