package com.example.dnschanger

import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import java.net.InetSocketAddress
import java.nio.channels.DatagramChannel

class MyVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val dns1 = intent?.getStringExtra("dns1") ?: "8.8.8.8" // Default to Google DNS
        val dns2 = intent?.getStringExtra("dns2") ?: "8.8.4.4" // Default to Google DNS

        if (vpnInterface == null) {
            vpnInterface = establishVPN(dns1, dns2)
        }
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        vpnInterface?.close()
        vpnInterface = null
    }

    private fun establishVPN(dns1: String, dns2: String): ParcelFileDescriptor? {
        val builder = Builder()
        builder.addAddress("10.0.0.2", 32) // Local VPN IP
        builder.addRoute("0.0.0.0", 0) // Route all traffic
        builder.addDnsServer(dns1)
        builder.addDnsServer(dns2)

         // Log the DNS values for debugging
        println("DNS 1: $dns1")
        println("DNS 2: $dns2")

        // Configure the VPN and return the interface
        return builder.setSession("DNS Changer VPN")
            .setMtu(1500)
            .establish()
    }
}
