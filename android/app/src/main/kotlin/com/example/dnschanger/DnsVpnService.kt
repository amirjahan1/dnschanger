package com.example.dnschanger

import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor

class DnsVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private var dns: List<String> = listOf()

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "STOP_VPN" -> {
                stopVpn()
                stopSelf()
                return START_NOT_STICKY
            }
            else -> {
                if (intent?.hasExtra("DNS_SERVERS") == true) {
                    dns = intent.getStringArrayListExtra("DNS_SERVERS") ?: listOf()
                    startVpn()
                }
                return START_STICKY
            }
        }
    }

    private fun startVpn() {
        if (vpnInterface == null && dns.isNotEmpty()) {
            vpnInterface = establishVPN()
        }
    }

    private fun stopVpn() {
        vpnInterface?.close()
        vpnInterface = null
    }

    private fun establishVPN(): ParcelFileDescriptor? {
        return try {
            val builder = Builder()
                .setSession("DNS Changer VPN")
                .addAddress("10.0.0.2", 32) // Dummy IP address with /32 mask

            // Add the DNS servers
            for (server in dns) {
                builder.addDnsServer(server)
            }

            // Do not add any routes
            // This ensures that only DNS settings are applied

            builder.establish()
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopVpn()
    }
}
