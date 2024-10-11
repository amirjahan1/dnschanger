package com.example.dnschanger

import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import kotlinx.coroutines.*
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.InetAddress
import java.net.InetSocketAddress
import java.nio.ByteBuffer
import java.nio.channels.DatagramChannel

class DnsVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private val vpnThread = CoroutineScope(Dispatchers.IO)
    private var dns: List<String> = listOf()
    private var isRunning = false

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.hasExtra("DNS_SERVERS") == true) {
            dns = intent.getStringArrayListExtra("DNS_SERVERS") ?: listOf()
            startVpn()
        }
        return START_STICKY
    }

    private fun startVpn() {
        if (vpnInterface == null && dns.isNotEmpty()) {
            vpnInterface = establishVPN()
            if (vpnInterface != null) {
                isRunning = true
                vpnThread.launch { runVpn() }
            }
        }
    }

    private fun establishVPN(): ParcelFileDescriptor? {
        return try {
            val builder = Builder()
                .setSession("DNS Changer VPN")
                .addAddress("10.0.0.2", 24)
                .addRoute("0.0.0.0", 0)

            // Add the DNS servers
            for (server in dns) {
                builder.addDnsServer(server)
            }

            builder.establish()
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private suspend fun runVpn() = withContext(Dispatchers.IO) {
        val fd = vpnInterface?.fileDescriptor ?: return@withContext
        val input = FileInputStream(fd)
        val output = FileOutputStream(fd)

        val buffer = ByteBuffer.allocate(32767)
        val tunnel = DatagramChannel.open()
        tunnel.configureBlocking(false)
        protect(tunnel.socket())

        while (isRunning) {
            buffer.clear()
            val length = input.read(buffer.array())
            if (length > 0) {
                buffer.limit(length)

                // Parse the packet to check if it's a DNS query
                val isDns = isDnsPacket(buffer)
                if (isDns) {
                    // Forward DNS packet to DNS server
                    forwardDnsPacket(buffer)
                } else {
                    // Forward non-DNS packet
                    val destAddress = getDestinationAddress(buffer)
                    if (destAddress != null) {
                        tunnel.send(buffer, destAddress)
                    }
                }
            }

            // Read responses from tunnel and write back to VPN interface
            buffer.clear()
            val senderAddress = tunnel.receive(buffer)
            if (senderAddress != null) {
                buffer.flip()
                output.write(buffer.array(), 0, buffer.limit())
            }
        }

        input.close()
        output.close()
        tunnel.close()
    }

    private fun isDnsPacket(buffer: ByteBuffer): Boolean {
        val position = buffer.position()
        val version = (buffer.get(0).toInt() shr 4) and 0x0F
        if (version == 4) {
            val protocol = buffer.get(9).toInt() and 0xFF
            val headerLength = (buffer.get(0).toInt() and 0x0F) * 4
            if (protocol == 17) { // UDP
                buffer.position(headerLength + 2)
                val destPort = buffer.getShort().toInt() and 0xFFFF
                buffer.position(position)
                return destPort == 53
            }
        }
        buffer.position(position)
        return false
    }

    private fun forwardDnsPacket(buffer: ByteBuffer) {
        try {
            val dnsServer = dns.firstOrNull() ?: return
            val dnsAddress = InetSocketAddress(dnsServer, 53)
            val channel = DatagramChannel.open()
            protect(channel.socket())
            channel.connect(dnsAddress)
            channel.write(buffer)
            buffer.clear()
            val bytesRead = channel.read(buffer)
            if (bytesRead > 0) {
                buffer.flip()
                val output = FileOutputStream(vpnInterface?.fileDescriptor)
                output.write(buffer.array(), 0, buffer.limit())
                output.close()
            }
            channel.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun getDestinationAddress(buffer: ByteBuffer): InetSocketAddress? {
        val position = buffer.position()
        val version = (buffer.get(0).toInt() shr 4) and 0x0F
        if (version == 4) {
            // IPv4
            val headerLength = (buffer.get(0).toInt() and 0x0F) * 4
            val protocol = buffer.get(9).toInt() and 0xFF
            val destAddressBytes = ByteArray(4)
            buffer.position(16)
            buffer.get(destAddressBytes, 0, 4)
            val destAddress = InetAddress.getByAddress(destAddressBytes)

            if (protocol == 6 || protocol == 17) {
                // TCP or UDP
                buffer.position(headerLength + 2)
                val destPort = buffer.getShort().toInt() and 0xFFFF
                buffer.position(position)
                return InetSocketAddress(destAddress, destPort)
            }
        }
        buffer.position(position)
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        vpnThread.cancel()
        vpnInterface?.close()
        vpnInterface = null
    }
}
