// dns_list_screen.dart
import 'package:flutter/material.dart';
import '../../data/dns_data.dart';
import '../../models/dns_model.dart';
import '../../services/dns_service.dart';
import '../../main.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DNSListScreen extends StatefulWidget {
  @override
  _DNSListScreenState createState() => _DNSListScreenState();
}

class _DNSListScreenState extends State<DNSListScreen> with WidgetsBindingObserver {
  late DNSService dnsService;
  int? activeDNSIndex;
  List<DNSModel> dnsList = [];

  @override
  void initState() {
    super.initState();
    dnsService = DNSService();
    activeDNSIndex = null;

    WidgetsBinding.instance.addObserver(this);

    requestNotificationPermissions();

    // Load DNS entries
    loadDNSList();

    // Check VPN state on startup
    checkVpnState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Load DNS entries
  Future<void> loadDNSList() async {
    List<DNSModel> allDNS = await DNSdata.getAllDNS();
    setState(() {
      dnsList = allDNS;
    });
  }

  // Request notification permissions
  Future<void> requestNotificationPermissions() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  // Check VPN state on app resume
  Future<void> checkVpnState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool vpnConnected = prefs.getBool('vpnConnected') ?? false;

    if (vpnConnected) {
      String? activeDNSName = prefs.getString('activeDNSName');
      await loadDNSList(); // Ensure dnsList is loaded
      if (activeDNSName != null) {
        int index = dnsList.indexWhere((dns) => dns.name == activeDNSName);
        if (index >= 0) {
          setState(() {
            activeDNSIndex = index;
          });
        } else {
          setState(() {
            activeDNSIndex = null;
          });
        }
      } else {
        setState(() {
          activeDNSIndex = null;
        });
      }
    } else {
      setState(() {
        activeDNSIndex = null;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkVpnState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("DNS Changer")),
      
      body: ListView.builder(
        itemCount: dnsList.length,
        itemBuilder: (context, index) {
          final dns = dnsList[index];
          final isActive = activeDNSIndex == index;
          return Card(
            child: ListTile(
              title: Text(dns.name),
              subtitle: Text(dns.ipAddress.join(", ")),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dns.isCustom)
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () async {
                        await showDNSForm(dns: dns, index: index - DNSdata.defaultDNS.length);
                      },
                    ),
                  if (dns.isCustom)
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        int customIndex = index - DNSdata.defaultDNS.length;
                        await DNSdata.deleteCustomDNS(customIndex);
                        if (dns.name == (await getActiveDNSName())) {
                          await disconnectDNS();
                        }
                        await loadDNSList();
                      },
                    ),
                  IconButton(
                    icon: Icon(
                      isActive ? Icons.power_off : Icons.wifi,
                      color: isActive ? Colors.green : null,
                    ),
                    onPressed: () async {
                      if (isActive) {
                        await disconnectDNS();
                      } else {
                        await connectDNS(dns, index);
                      }
                    },
                  ),
                ],
              ),
            ),
           
          );
       
        },
        padding: EdgeInsets.only(bottom: 100)
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDNSForm();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  // Show form to add or edit DNS
  Future<void> showDNSForm({DNSModel? dns, int? index}) async {
    TextEditingController nameController = TextEditingController(text: dns?.name ?? '');
    TextEditingController dns1Controller = TextEditingController(
        text: dns != null && dns.ipAddress.isNotEmpty ? dns.ipAddress[0] : '');
    TextEditingController dns2Controller = TextEditingController(
        text: dns != null && dns.ipAddress.length > 1 ? dns.ipAddress[1] : '');

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(dns == null ? 'Add DNS' : 'Edit DNS'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: dns1Controller,
                    decoration: InputDecoration(labelText: 'DNS 1'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter DNS 1';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: dns2Controller,
                    decoration: InputDecoration(labelText: 'DNS 2 (Optional)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  String name = nameController.text.trim();
                  String dns1 = dns1Controller.text.trim();
                  String dns2 = dns2Controller.text.trim();

                  List<String> ipAddresses = [dns1];
                  if (dns2.isNotEmpty) {
                    ipAddresses.add(dns2);
                  }

                  DNSModel newDNS = DNSModel(
                    name: name,
                    ipAddress: ipAddresses,
                    isCustom: true,
                  );

                  if (dns == null) {
                    // Add new DNS
                    await DNSdata.addCustomDNS(newDNS);
                  } else {
                    // Update existing DNS
                    await DNSdata.updateCustomDNS(index!, newDNS);
                  }

                  await loadDNSList();
                  Navigator.of(context).pop(); // Close dialog
                }
              },
              child: Text(dns == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  // Get the active DNS name
  Future<String?> getActiveDNSName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('activeDNSName');
  }

  // Connect to a DNS
  Future<void> connectDNS(DNSModel dns, int index) async {
    try {
      await DNSChangerApp.setDNS(dns.ipAddress);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('vpnConnected', true);
      await prefs.setString('activeDNSName', dns.name);

      setState(() {
        activeDNSIndex = index;
      });

      await showDisconnectNotification();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connected to: ${dns.name}"),
        ),
      );
    } on Exception catch (e) {
      print("Failed to set DNS: $e");
    }
  }

  // Disconnect the current DNS
  Future<void> disconnectDNS() async {
    try {
      await DNSChangerApp.disconnectVPN();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('vpnConnected', false);
      await prefs.remove('activeDNSName');

      setState(() {
        activeDNSIndex = null;
      });

      await AwesomeNotifications().cancel(0);
      await AwesomeNotifications().resetGlobalBadge();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Disconnected from DNS"),
        ),
      );
    } on Exception catch (e) {
      print("Failed to disconnect DNS: $e");
    }
  }

  // Show notification with disconnect action
  Future<void> showDisconnectNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'dns_disconnect_channel',
        title: 'DNS Connected',
        body: 'Tap to disconnect',
        notificationLayout: NotificationLayout.Default,
        locked: true,
        autoDismissible: false,
        badge: 1,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'DISCONNECT_DNS',
          label: 'Disconnect',
          autoDismissible: false,
          actionType: ActionType.KeepOnTop,
        ),
      ],
    );
  }
}
