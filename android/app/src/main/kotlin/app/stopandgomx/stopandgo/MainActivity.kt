package app.stopandgomx.stopandgo

import android.content.Intent
import android.os.Bundle
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "app.stopandgo/deeplink"
    }

    private var initialDeepLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initialDeepLink = intent?.dataString
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val latest = intent.dataString
        if (!latest.isNullOrBlank()) {
            initialDeepLink = latest
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialDeepLink" -> result.success(initialDeepLink)
                    "getInstallReferrer" -> fetchInstallReferrer(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun fetchInstallReferrer(result: MethodChannel.Result) {
        val client = InstallReferrerClient.newBuilder(this).build()
        client.startConnection(object : InstallReferrerStateListener {
            override fun onInstallReferrerSetupFinished(responseCode: Int) {
                when (responseCode) {
                    InstallReferrerClient.InstallReferrerResponse.OK -> {
                        try {
                            val details = client.installReferrer
                            val payload = hashMapOf(
                                "installReferrer" to details.installReferrer,
                                "referrerClickTimestampSeconds" to details.referrerClickTimestampSeconds,
                                "installBeginTimestampSeconds" to details.installBeginTimestampSeconds
                            )
                            result.success(payload)
                        } catch (e: Exception) {
                            result.error(
                                "INSTALL_REFERRER_ERROR",
                                e.message ?: "No se pudo leer install referrer",
                                null
                            )
                        } finally {
                            client.endConnection()
                        }
                    }
                    else -> {
                        result.success(null)
                        client.endConnection()
                    }
                }
            }

            override fun onInstallReferrerServiceDisconnected() {
                // Se reintenta en una próxima ejecución si aplica.
            }
        })
    }
}
