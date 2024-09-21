package com.example.dnschanger

import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log
import kotlinx.coroutines.*
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.InetAddress
import java.net.InetSocketAddress
import java.nio.ByteBuffer
import java.nio.channels.DatagramChannel

class MyVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private var isRunning = false
    private val scope = CoroutineScope(Dispatchers.Default)
    private lateinit var dns1: String
    private lateinit var dns2: String

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
         
        dns1 = intent?.getStringExtra("dns1") ?: "8.8.8.8"
        dns2 = intent?.getStringExtra("dns2") ?: "8.8.4.4"

        if (vpnInterface == null) {
            vpnInterface = establishVPN(dns1, dns2)
            isRunning = true
            scope.launch { runVpn() }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        scope.cancel()
        vpnInterface?.close()
        vpnInterface = null
    }

    private fun establishVPN(dns1: String, dns2: String): ParcelFileDescriptor? {
        Log.d("MyVpnService", "Setting DNS: $dns1, $dns2")
        return Builder()
            .addAddress("10.0.0.2", 32)
            .addRoute("0.0.0.0", 0)
            .addDnsServer(dns1)
            .addDnsServer(dns2)
            .setSession("DNS Changer VPN")
            .setMtu(1500)
            .establish()
    }

    private suspend fun runVpn() = withContext(Dispatchers.IO) {
        val packet = ByteBuffer.allocate(32767)
        val input = FileInputStream(vpnInterface?.fileDescriptor)
        val output = FileOutputStream(vpnInterface?.fileDescriptor)

        while (isRunning) {
            packet.clear()
            val length = input.read(packet.array())
            if (length > 0) {
                packet.limit(length)
                handlePacket(packet, output)
            }
        }
    }

    private fun handlePacket(packet: ByteBuffer, output: FileOutputStream) {
        val version = packet.get(0).toInt() shr 4
        if (version == 4) { // IPv4
            val protocol = packet.get(9).toInt()
            val sourceIp = packet.getInt(12)
            val destIp = packet.getInt(16)

            when (protocol) {
                17 -> handleUdpPacket(packet, sourceIp, destIp, output)
                6 -> handleTcpPacket(packet, sourceIp, destIp, output)
                else -> Log.d("MyVpnService", "Unhandled protocol: $protocol")
            }
        }
    }

    private fun handleUdpPacket(packet: ByteBuffer, sourceIp: Int, destIp: Int, output: FileOutputStream) {
        val sourcePort = packet.getShort(20).toInt() and 0xFFFF
        val destPort = packet.getShort(22).toInt() and 0xFFFF

        if (destPort == 53) { // DNS query
            Log.d("MyVpnService", "DNS query detected")
            forwardDnsQuery(packet, sourceIp, sourcePort, destIp, output)
        } else {
            forwardUdpPacket(packet, sourceIp, destIp, sourcePort, destPort, output)
        }
    }

    private fun handleTcpPacket(packet: ByteBuffer, sourceIp: Int, destIp: Int, output: FileOutputStream) {
        val sourcePort = packet.getShort(20).toInt() and 0xFFFF
        val destPort = packet.getShort(22).toInt() and 0xFFFF

        if (destPort == 853) { // DNS over TLS
            Log.d("MyVpnService", "DNS over TLS detected")
            // Handle DNS over TLS (not implemented in this example)
        } else {
            forwardTcpPacket(packet, sourceIp, destIp, sourcePort, destPort, output)
        }
    }

    private fun forwardDnsQuery(packet: ByteBuffer, sourceIp: Int, sourcePort: Int, destIp: Int, output: FileOutputStream) {
        try {
            val channel = DatagramChannel.open()
            protect(channel.socket())
    
            val dnsServer = InetSocketAddress(InetAddress.getByName(dns1), 53)
            channel.connect(dnsServer)
    
            packet.position(20) // Skip IP header
            val bytesWritten = channel.write(packet)
            Log.d("MyVpnService", "Forwarded DNS query, bytes written: $bytesWritten")
    
            val responsePacket = ByteBuffer.allocate(1500)
            val bytesRead = channel.read(responsePacket)
            responsePacket.flip()
            Log.d("MyVpnService", "Received DNS response, bytes read: $bytesRead")
    
            // Construct response IP packet
            val response = ByteBuffer.allocate(20 + responsePacket.limit())
            response.put(packet.array(), 0, 20) // Copy original IP header
            response.put(responsePacket)
    
            // Update IP header
            response.putShort(2, (20 + responsePacket.limit()).toShort()) // Total length
            response.putInt(12, destIp) // Swap source and dest IP
            response.putInt(16, sourceIp)
    
            // Write response back to VPN interface
            val bytesWrittenToVpn = output.write(response.array(), 0, response.position())
            Log.d("MyVpnService", "Written DNS response to VPN, bytes: $bytesWrittenToVpn")
    
            channel.close()
        } catch (e: Exception) {
            Log.e("MyVpnService", "Error forwarding DNS query: ${e.message}", e)
        }
    }

    private fun forwardUdpPacket(packet: ByteBuffer, sourceIp: Int, destIp: Int, sourcePort: Int, destPort: Int, output: FileOutputStream) {
        // Implement UDP forwarding (not shown for brevity)
        Log.d("MyVpnService", "Forwarding UDP: $sourceIp:$sourcePort -> $destIp:$destPort")
        // For now, just write the original packet back to the output
        try {
            output.write(packet.array(), 0, packet.limit())
        } catch (e: Exception) {
            Log.e("MyVpnService", "Error forwarding UDP packet: ${e.message}")
        }
    }

    private fun forwardTcpPacket(packet: ByteBuffer, sourceIp: Int, destIp: Int, sourcePort: Int, destPort: Int, output: FileOutputStream) {
        // Implement TCP forwarding (not shown for brevity)
        Log.d("MyVpnService", "Forwarding TCP: $sourceIp:$sourcePort -> $destIp:$destPort")
        // For now, just write the original packet back to the output
        try {
            output.write(packet.array(), 0, packet.limit())
        } catch (e: Exception) {
            Log.e("MyVpnService", "Error forwarding TCP packet: ${e.message}")
        }
    }

    private fun ByteBuffer.getInt(index: Int): Int {
        return this.getInt(index)
    }

    private fun ByteBuffer.getShort(index: Int): Short {
        return this.getShort(index)
    }
}