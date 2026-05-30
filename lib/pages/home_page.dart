import 'package:eunix/pages/arp_scanner_page.dart';
import 'package:eunix/pages/dns_lookup_page.dart';
import 'package:eunix/pages/http_client_page.dart';
import 'package:eunix/pages/ip_finder_page.dart';
import 'package:eunix/pages/network_dashbord_page.dart';
import 'package:eunix/pages/ping_tool_page.dart';
import 'package:eunix/pages/port_scanner_page.dart';
import 'package:eunix/pages/tcp_client_page.dart';
import 'package:eunix/pages/tcp_proxy_page.dart';
import 'package:eunix/pages/tcp_server_page.dart';
import 'package:eunix/pages/traceroute_page.dart';
import 'package:eunix/pages/udp_client_page.dart';
import 'package:eunix/pages/whois_lookup_page.dart';
import 'package:eunix/pages/wifi_scanner_page.dart';
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

  Widget bigCategoryButton({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.cyan.withOpacity(0.10)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.cyan.withOpacity(0.45), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.18),
              blurRadius: 14,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.cyan, size: 42),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.cyan,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: "monospace",
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                      fontFamily: "monospace",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void openCategory(List<Widget> tools, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryPage(title: title, tools: tools),
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
                  const Icon(Icons.wifi, color: Colors.cyan),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "IP: $localIp",
                          style: const TextStyle(
                            fontFamily: "monospace",
                            color: Colors.white,
                          ),
                        ),
                        if (ssid.isNotEmpty)
                          Text(
                            "SSID: $ssid",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.circle, size: 10, color: Colors.green),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: [
                  bigCategoryButton(
                    icon: Icons.terminal,
                    title: "Netcat Tools",
                    description: "TCP/UDP communication utilities",
                    onTap: () => openCategory([
                      _tool(
                        "TCP Client",
                        "Create outgoing TCP connection",
                        Icons.cloud_upload,
                        const TcpClientPage(),
                      ),
                      _tool(
                        "TCP Server",
                        "Listen for TCP connections",
                        Icons.cloud,
                        const TcpServerPage(),
                      ),
                      _tool(
                        "UDP Client",
                        "Send & receive UDP packets",
                        Icons.wifi_tethering,
                        const UdpClientPage(),
                      ),
                    ], "Netcat Tools"),
                  ),

                  bigCategoryButton(
                    icon: Icons.search,
                    title: "Discovery Tools",
                    description: "Scan, trace, and discover network devices",
                    onTap: () => openCategory([
                      _tool(
                        "TCP Proxy",
                        "Forward traffic",
                        Icons.swap_horiz,
                        const TcpProxyPage(),
                      ),
                      _tool(
                        "Port Scanner",
                        "Scan ports",
                        Icons.search,
                        const PortScannerPage(),
                      ),
                      _tool(
                        "Ping Tool",
                        "ICMP ping test",
                        Icons.network_ping,
                        const PingToolPage(),
                      ),
                      _tool(
                        "Traceroute",
                        "Trace network hops",
                        Icons.alt_route,
                        const TraceroutePage(),
                      ),
                      _tool(
                        "ARP Scanner",
                        "Detect devices via ARP",
                        Icons.router,
                        const ArpScannerPage(),
                      ),
                      _tool(
                        "IP Finder",
                        "Scan local network",
                        Icons.travel_explore,
                        const IpFinderPage(),
                      ),
                    ], "Discovery Tools"),
                  ),

                  bigCategoryButton(
                    icon: Icons.info_outline,
                    title: "Lookup Tools",
                    description: "DNS, Whois, and domain information",
                    onTap: () => openCategory([
                      _tool(
                        "DNS Lookup",
                        "Resolve domain records",
                        Icons.dns,
                        const DnsLookupPage(),
                      ),
                      _tool(
                        "Whois Lookup",
                        "Domain registration info",
                        Icons.info_outline,
                        const WhoisLookupPage(),
                      ),
                    ], "Lookup Tools"),
                  ),

                  bigCategoryButton(
                    icon: Icons.settings,
                    title: "System Tools",
                    description: "Device and network system utilities",
                    onTap: () => openCategory([
                      _tool(
                        "Network Dashboard",
                        "Device & network info",
                        Icons.dashboard_customize,
                        const NetworkDashboardPage(),
                      ),
                      _tool(
                        "WiFi Scanner",
                        "Nearby WiFi networks",
                        Icons.wifi_find,
                        const WifiScannerPage(),
                      ),
                      _tool(
                        "HTTP Client",
                        "Send HTTP requests",
                        Icons.http,
                        const HttpClientPage(),
                      ),
                    ], "System Tools"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tool(String title, String subtitle, IconData icon, Widget? page) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: CardButton(
        onPressed: page == null
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => page),
              ),
        child: Basic(
          leading: Icon(icon, color: Colors.cyan, size: 26),
          title: Text(title, style: const TextStyle(fontFamily: "monospace")),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, color: Colors.cyan),
        ),
      ),
    );
  }
}

class CategoryPage extends StatelessWidget {
  final String title;
  final List<Widget> tools;

  const CategoryPage({super.key, required this.title, required this.tools});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(title: Text(title)),
        const Divider(),
      ],
      child: ListView(padding: const EdgeInsets.all(16), children: tools),
    );
  }
}
