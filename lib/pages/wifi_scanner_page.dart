import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';

class WifiScannerPage extends StatefulWidget {
  const WifiScannerPage({super.key});

  @override
  State<WifiScannerPage> createState() => _WifiScannerPageState();
}

class _WifiScannerPageState extends State<WifiScannerPage> {
  bool isScanning = false;
  List<WiFiAccessPoint> networks = [];
  String statusText = "Press Scan to search nearby WiFi networks";

  @override
  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _checkSupport();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }

    // Android 13+
    if (await Permission.nearbyWifiDevices.isDenied) {
      await Permission.nearbyWifiDevices.request();
    }
  }

  Future<void> _checkSupport() async {
    final can = await WiFiScan.instance.canStartScan();
    if (can != CanStartScan.yes) {
      setState(() {
        statusText = "WiFi scan not available: $can";
      });
    }
  }

  Future<void> _startScan() async {
    setState(() {
      isScanning = true;
      statusText = "Scanning for WiFi networks...";
      networks = [];
    });

    await WiFiScan.instance.startScan();

    final result = await WiFiScan.instance.getScannedResults();
    result.sort((a, b) => b.level.compareTo(a.level)); // قوی‌ترین سیگنال بالا

    setState(() {
      networks = result;
      isScanning = false;
      statusText = networks.isEmpty
          ? "No WiFi networks found"
          : "Found ${networks.length} networks";
    });
  }

  IconData _signalIcon(int level) {
    if (level >= -50) return Icons.wifi;
    if (level >= -60) return Icons.network_wifi;
    if (level >= -70) return Icons.wifi_2_bar;
    if (level >= -80) return Icons.wifi_1_bar;
    return Icons.signal_wifi_0_bar_sharp;
  }

  Color _signalColor(int level) {
    if (level >= -50) return Colors.green.shade800;
    if (level >= -60) return Colors.green.shade500;
    if (level >= -70) return Colors.amber.shade800;
    if (level >= -80) return Colors.orange.shade800;
    return Colors.red.shade400;
  }

  String _securityLabel(WiFiAccessPoint ap) {
    final caps = ap.capabilities.toUpperCase();
    if (caps.contains("WPA3")) return "WPA3";
    if (caps.contains("WPA2")) return "WPA2";
    if (caps.contains("WPA")) return "WPA";
    if (caps.contains("WEP")) return "WEP";
    return "Open";
  }

  Widget _networkCard(WiFiAccessPoint ap) {
    final ssid = ap.ssid.isEmpty ? "<Hidden SSID>" : ap.ssid;
    final level = ap.level; // dBm
    final freq = ap.frequency; // MHz
    final security = _securityLabel(ap);

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.blue.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyan.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.18),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(_signalIcon(level), color: _signalColor(level), size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ssid,
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: "monospace",
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "Signal: $level dBm",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontFamily: "monospace",
                  ),
                ),
                Text(
                  "Frequency: ${freq} MHz",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                    fontFamily: "monospace",
                  ),
                ),
                Text(
                  "Security: $security",
                  style: TextStyle(
                    color: security == "Open"
                        ? Colors.red.shade400
                        : Colors.green.shade800,
                    fontSize: 12,
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
      headers: const [
        AppBar(title: Text("WiFi Scanner")),
        Divider(),
      ],
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // وضعیت و دکمه اسکن
            Row(
              children: [
                Expanded(
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.cyan,
                      fontFamily: "monospace",
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Button(
                  onPressed: isScanning ? null : _startScan,
                  style: ButtonStyle.primary(),
                  child: Text(isScanning ? "Scanning..." : "Scan"),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // توضیح کوتاه
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Nearby WiFi networks with SSID, signal strength, frequency, and security type.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontFamily: "monospace",
                ),
              ),
            ),

            const SizedBox(height: 16),

            // لیست شبکه‌ها
            Expanded(
              child: networks.isEmpty
                  ? const Center(
                      child: Text(
                        "No networks to display",
                        style: TextStyle(
                          color: Colors.cyan,
                          fontFamily: "monospace",
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: networks.length,
                      itemBuilder: (context, index) {
                        return _networkCard(networks[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
