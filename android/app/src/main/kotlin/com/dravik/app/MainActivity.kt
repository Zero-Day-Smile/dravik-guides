package com.dravik.app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
	override fun onCreate(savedInstanceState: Bundle?) {
		// Prevent screenshots and screen recording for security-sensitive content
		window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
		super.onCreate(savedInstanceState)
	}
}
