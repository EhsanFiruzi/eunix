import 'package:eunix/pages/tcp_client_page.dart';
import 'package:eunix/pages/tcp_server_page.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final NetworkInfo _networkInfo = NetworkInfo();

  String localIp = "Loading...";
  String ssid = "";

  @override
  void initState() {
    super.initState();
    _loadNetworkInfo();
  }

  Future<void> _loadNetworkInfo() async {
    try {
      final ip = await _networkInfo.getWifiIP();
      final wifiName = await _networkInfo.getWifiName();

      if (!mounted) return;

      setState(() {
        localIp = ip ?? "Not Connected";
        ssid = wifiName?.replaceAll('"', '') ?? "";
      });
    } catch (e) {
      setState(() {
        localIp = "Unavailable";
      });
    }
  }

  Widget toolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return CardButton(
      onPressed: onTap,
      child: Basic(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          title: const Text("eunix"),
          trailing: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadNetworkInfo,
              variance: ButtonStyle.secondary(),
            ),
          ],
        ),
        const Divider(),
      ],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Network Status Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "IP: $localIp",
                          style: const TextStyle(fontFamily: "monospace"),
                        ),
                        if (ssid.isNotEmpty)
                          Text(
                            "SSID: $ssid",
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.circle, size: 10, color: Colors.green),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: ListView(
                children: [
                  toolCard(
                    icon: Icons.cloud_upload,
                    title: "TCP Client",
                    subtitle: "Create outgoing TCP connection",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TcpClientPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  toolCard(
                    icon: Icons.cloud,
                    title: "TCP Server",
                    subtitle: "Listen for TCP connections",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TcpServerPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  toolCard(
                    icon: Icons.swap_horiz,
                    title: "TCP Proxy",
                    subtitle: "Forward traffic",
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  toolCard(
                    icon: Icons.wifi_tethering,
                    title: "UDP Client",
                    subtitle: "Send and receive UDP packets",
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  toolCard(
                    icon: Icons.search,
                    title: "Port Scanner",
                    subtitle: "Scan ports (with permission)",
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Use network tools responsibly.",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
