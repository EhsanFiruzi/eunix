import 'dart:convert';
import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class NetworkDashboardPage extends StatefulWidget {
  const NetworkDashboardPage({super.key});

  @override
  State<NetworkDashboardPage> createState() => _NetworkDashboardPageState();
}

class _NetworkDashboardPageState extends State<NetworkDashboardPage> {
  final NetworkInfo _info = NetworkInfo();

  String localIp = "...";
  String publicIp = "...";
  String gateway = "...";
  String subnet = "...";
  String mac = "...";
  String wifiName = "...";
  String wifiIPv6 = "...";
  String broadcast = "...";

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    localIp = await _info.getWifiIP() ?? "Unknown";
    wifiIPv6 = await _info.getWifiIPv6() ?? "Unknown";
    wifiName = await _info.getWifiName() ?? "Unknown";
    mac = await _info.getWifiBSSID() ?? "Unknown";
    subnet = await _info.getWifiSubmask() ?? "Unknown";
    broadcast = await _info.getWifiBroadcast() ?? "Unknown";
    gateway = await _info.getWifiGatewayIP() ?? "Unknown";
    publicIp = "...";

    setState(() {});
    fetchPublicIp();
  }

  Future<void> fetchPublicIp() async {
    try {
      final response = await HttpClient()
          .getUrl(Uri.parse('https://api.ipify.org?format=json'))
          .timeout(const Duration(seconds: 5))
          .then((req) => req.close());

      if (response.statusCode == 200) {
        final json = await response.transform(utf8.decoder).join();
        final data = jsonDecode(json);
        setState(() {
          publicIp = data['ip'] ?? "Unknown";
        });
      } else {
        setState(() {
          publicIp = "Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        publicIp = "could not fetch";
      });
    }
  }

  Widget infoCard(String title, String value, IconData icon) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.blue.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.cyan.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon with glow
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.cyan.withOpacity(0.4), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.cyan, size: 26),
          ),

          const SizedBox(width: 18),

          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: "monospace",
                  ),
                ),

                const SizedBox(height: 6),

                // Divider line
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.25),
                  margin: const EdgeInsets.only(bottom: 8),
                ),

                // Value
                SelectableText(
                  value,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 17,
                    fontFamily: "monospace",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          title: const Text("Network Dashboard"),
          trailing: [
            IconButton(
              icon: const Icon(Icons.refresh),
              variance: ButtonStyle.secondary(),
              onPressed: loadData,
            ),
          ],
        ),
        const Divider(),
      ],
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            infoCard("Local IP", localIp, Icons.device_hub),
            infoCard("Public IP", publicIp, Icons.public),
            infoCard("Gateway", gateway, Icons.router),
            infoCard("Subnet Mask", subnet, Icons.grid_on),
            infoCard("Broadcast", broadcast, Icons.wifi_tethering),
            infoCard("MAC Address (BSSID)", mac, Icons.memory),

            infoCard("IPv6", wifiIPv6, Icons.code),
          ],
        ),
      ),
    );
  }
}
