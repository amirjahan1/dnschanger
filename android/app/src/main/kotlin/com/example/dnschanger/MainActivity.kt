package com.example.dnschanger

import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.dnschanger/dns"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setDNS") {
                val dns = call.argument<List<String>>("dns")
                if (dns != null && dns.isNotEmpty()) {
                    val intent = VpnService.prepare(this)
                    if (intent != null) {
                        startActivityForResult(intent, 0)
                    } else {
                        startVpnService(dns)
                    }
                    result.success("VPN DNS setup started")
                } else {
                    result.error("INVALID_ARGUMENT", "No DNS provided", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 0 && resultCode == RESULT_OK) {
            val dns = listOf("8.8.8.8", "8.8.4.4") // Default DNS, you should pass this from Flutter
            startVpnService(dns)
        }
    }

    private fun startVpnService(dns: List<String>) {
        val intent = Intent(this, DnsVpnService::class.java)
        intent.putStringArrayListExtra("DNS_SERVERS", ArrayList(dns))
        startService(intent)
    }
}