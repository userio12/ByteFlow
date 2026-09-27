package com.byteflow

import com.byteflow.network.NetworkChannelHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var channelHandler: NetworkChannelHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channelHandler = NetworkChannelHandler(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onDestroy() {
        channelHandler?.dispose()
        channelHandler = null
        super.onDestroy()
    }
}
