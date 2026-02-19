package com.example.flutter_singular

import android.Manifest
import android.content.pm.PackageManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.singular.flutter_sdk.SingularBridge

class MainActivity : FlutterActivity() {
    private val NOTIFICATION_CHANNEL = "com.example.flutter_singular/notifications"
    private val DEEPLINK_CHANNEL = "com.example.flutter_singular/deeplinks"
    private val REQUEST_CODE_NOTIFICATION_PERMISSION = 1001

    private var pendingResult: MethodChannel.Result? = null
    private var deepLinkMethodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Canal de notificaciones (existente)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestNotificationPermission" -> {
                        requestNotificationPermission(result)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        
        // Canal de deep links (nuevo)
        deepLinkMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEEPLINK_CHANNEL
        )
        
        // Procesar intent pendiente después de que Flutter está listo
        handleDeepLink(intent)
    }

    

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // El intent se procesará en configureFlutterEngine cuando Flutter esté listo
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleDeepLink(intent)
    }

    private fun handleDeepLink(intent: Intent) {
        // Primero, procesar con Singular
        SingularBridge.onNewIntent(intent)
        
        // Se envia a Flutter usando el method Channel. 
        val uri = intent.data
        if (uri != null && isDeepLink(uri)) {
            sendDeepLinkToFlutter(uri)
        }
    }

    private fun isDeepLink(uri: Uri): Boolean {
        // Verifica que sea un deep link válido (no mailto:, tel:, etc.)
        return uri.scheme == "app" || 
               uri.scheme == "https" && uri.host == "minders.sng.link" ||
               uri.scheme == "https" && uri.host == "flutter-singular.obed.lat"
        // Ajusta según tus esquemas configurados
    }

   private fun sendDeepLinkToFlutter(uri: Uri) {
        val data = mapOf(
            "url" to uri.toString(),
            "scheme" to (uri.scheme ?: ""),
            "host" to (uri.host ?: ""),
            "path" to (uri.path ?: ""),
            "queryParams" to uri.queryParameterNames.associate { param ->
                param to (uri.getQueryParameter(param) ?: "")
            }
        )

        try {
            deepLinkMethodChannel?.invokeMethod("onDeepLink", data)
        } catch (e: Exception) {
            window.decorView.postDelayed({
                deepLinkMethodChannel?.invokeMethod("onDeepLink", data)
            }, 500)
        }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            when {
                ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.POST_NOTIFICATIONS
                ) == PackageManager.PERMISSION_GRANTED -> {
                    result.success(true)
                }
                else -> {
                    pendingResult = result
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                        REQUEST_CODE_NOTIFICATION_PERMISSION
                    )
                }
            }
        } else {
            result.success(true)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == REQUEST_CODE_NOTIFICATION_PERMISSION) {
            val granted = grantResults.isNotEmpty() && 
                         grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingResult?.success(granted)
            pendingResult = null
        }
    }
}