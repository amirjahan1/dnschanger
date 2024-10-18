package com.example.dnschanger

import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.dnschanger/dns"
    private var dnsList: List<String> = listOf()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setDNS" -> {
                    val dns = call.argument<List<String>>("dns")
                    if (dns != null && dns.isNotEmpty()) {
                        dnsList = dns
                        val intent = VpnService.prepare(this)
                        if (intent != null) {
                            startActivityForResult(intent, VPN_REQUEST_CODE)
                        } else {
                            onActivityResult(VPN_REQUEST_CODE, RESULT_OK, null)
                        }
                        result.success("VPN DNS setup started")
                    } else {
                        result.error("INVALID_ARGUMENT", "No DNS provided", null)
                    }
                }
                "disconnectVPN" -> {
                    stopVpnService()
                    result.success("VPN disconnected")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private val VPN_REQUEST_CODE = 100

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == VPN_REQUEST_CODE) {
            if (resultCode == RESULT_OK) {
                startVpnService(dnsList)
            } else {
                // User denied VPN permission
            }
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun startVpnService(dns: List<String>) {
        val intent = Intent(this, DnsVpnService::class.java)
        intent.putStringArrayListExtra("DNS_SERVERS", ArrayList(dns))
        startService(intent)
    }

    private fun stopVpnService() {
        val intent = Intent(this, DnsVpnService::class.java)
        stopService(intent) // Stops the VPN service
    }
}