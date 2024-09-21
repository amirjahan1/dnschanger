package com.example.dnschanger

import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.dnschanger/dns"
    private var dns: List<String>? = null

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setDNS") {
                dns = call.argument<List<String>>("dns")
                if (dns != null && dns!!.isNotEmpty()) {
                    // Request VPN permission
                    val intent = VpnService.prepare(this)
                    if (intent != null) {
                        startActivityForResult(intent, 0) // Request VPN permission
                    } else {
                        // VPN permission already granted, start the VPN service
                        startVpnService(dns!!)
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
        if (requestCode == 0 && resultCode == RESULT_OK && dns != null) {
            // VPN permission granted, start the VPN service
            startVpnService(dns!!)
        }
    }

    private fun startVpnService(dns: List<String>) {
        val intent = Intent(this, MyVpnService::class.java)
        intent.putExtra("dns1", dns[0])
        if (dns.size > 1) {
            intent.putExtra("dns2", dns[1])
        }
        startService(intent)
    }
}
