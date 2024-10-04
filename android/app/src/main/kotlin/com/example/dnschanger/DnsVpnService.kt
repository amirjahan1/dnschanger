package com.example.dnschanger

import android.app.Service
import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import kotlinx.coroutines.*
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.channels.DatagramChannel

class DnsVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private var isRunning = false
    private val scope = CoroutineScope(Dispatchers.Default)
    private var dns: List<String> = listOf()

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.hasExtra("DNS_SERVERS") == true) {
            dns = intent.getStringArrayListExtra("DNS_SERVERS") ?: listOf()
            startVpn()
        }
        return Service.START_STICKY
    }

    private fun startVpn() {
        if (vpnInterface == null && dns.isNotEmpty()) {
            vpnInterface = establishVPN()
            if (vpnInterface != null) {
                isRunning = true
                scope.launch { runVpn() }
            }
        }
    }

    private fun establishVPN(): ParcelFileDescriptor? {
        return try {
            val builder = Builder()
                .addAddress("10.0.0.2", 32)
                .addRoute("0.0.0.0", 0)
                .addDnsServer(dns[0])
                .setSession("DNS Changer VPN")
                .setMtu(1500)

            if (dns.size > 1) {
                builder.addDnsServer(dns[1])
            }

            builder.establish()
        } catch (e: Exception) {
            null
        }
    }

    private suspend fun runVpn() = withContext(Dispatchers.IO) {
        val packet = ByteBuffer.allocate(32767)
        val input = FileInputStream(vpnInterface?.fileDescriptor)
        val output = FileOutputStream(vpnInterface?.fileDescriptor)

        while (isRunning) {
            try {
                packet.clear()
                val length = input.read(packet.array())
                if (length > 0) {
                    packet.limit(length)
                    handlePacket(packet, output)
                }
            } catch (e: Exception) {
                // Log error
            }
        }
    }

    private fun handlePacket(packet: ByteBuffer, output: FileOutputStream) {
        val version = packet.get(0).toInt() shr 4
        if (version == 4 && packet.get(9).toInt() == 17) { // Check for UDP
            forwardDnsQuery(packet, output)
        } else {
            output.write(packet.array(), 0, packet.limit())
        }
    }

    private fun forwardDnsQuery(packet: ByteBuffer, output: FileOutputStream) {
        try {
            val channel = DatagramChannel.open()
            protect(channel.socket()) // Protect the socket from VPN routing
            channel.connect(java.net.InetSocketAddress(java.net.InetAddress.getByName(dns[0]), 53))

            packet.position(20)
            channel.write(packet)

            val responsePacket = ByteBuffer.allocate(1500)
            channel.read(responsePacket)
            responsePacket.flip()

            val response = ByteBuffer.allocate(20 + responsePacket.limit())
            response.put(packet.array(), 0, 20)
            response.put(responsePacket)
            response.putShort(2, (20 + responsePacket.limit()).toShort())

            output.write(response.array(), 0, response.position())
            channel.close()
        } catch (e: Exception) {
            // Log error
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        scope.cancel()
        vpnInterface?.close()
        vpnInterface = null
    }
}