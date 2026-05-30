import 'dart:async';
import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class IpFinderPage extends StatefulWidget {
  const IpFinderPage({super.key});

  @override
  State createState() => _IpFinderPageState();
}

class _IpFinderPageState extends State<IpFinderPage> {
  final NetworkInfo _networkInfo = NetworkInfo();

  String localIp = "Loading...";
  String ssid = "";

  String? netId;

  bool scanning = false;

  bool manualNetId = false;
  final TextEditingController manualNetIdController = TextEditingController();

  List<String> foundIps = [];
  List<String> logs = [];

  void addLog(String text) {
    setState(() {
      logs.insert(
        0,
        "[${DateTime.now().toIso8601String().substring(11, 19)}] $text",
      );
    });
  }

  // -------------------------------
  // GET LOCAL IP (WiFi → Mobile)
  // -------------------------------
  Future<void> detectLocalIp() async {
    try {
      final wifiIp = await _networkInfo.getWifiIP();
      final wifiName = await _networkInfo.getWifiName();

      if (!mounted) return;

      if (wifiIp != null && wifiIp.isNotEmpty) {
        setState(() {
          localIp = wifiIp;
          ssid = wifiName?.replaceAll('"', '') ?? "";
        });
      } else {
        final mobileIp = await _networkInfo.getWifiIP();

        setState(() {
          localIp = mobileIp ?? "Not Connected";
          ssid = "";
        });
      }

      if (localIp != "Not Connected" && localIp != "Unavailable") {
        final parts = localIp.split(".");
        if (parts.length == 4) {
          netId = "${parts[0]}.${parts[1]}.${parts[2]}";
        }
      }
    } catch (e) {
      setState(() {
        localIp = "Unavailable";
        ssid = "";
      });
    }
  }

  // -------------------------------
  // TCP ALIVE CHECK (Reliable on Mobile)
  // -------------------------------
  Future<bool> isHostAlive(String ip) async {
    try {
      final socket = await Socket.connect(
        ip,
        80,
        timeout: const Duration(milliseconds: 200),
      );
      socket.destroy();
      return true;
    } catch (e) {
      if (e.toString().contains("Connection refused")) {
        return true;
      }
      return false;
    }
  }

  // -------------------------------
  // SCAN ONE IP
  // -------------------------------
  Future<void> scanIp(String ip) async {
    bool alive = await isHostAlive(ip);

    if (alive) {
      if (!foundIps.contains(ip)) {
        foundIps.add(ip);
        addLog("🟢 Host detected: $ip");
      }
    }
  }

  // -------------------------------
  // START SCAN
  // -------------------------------
  Future<void> startScan() async {
    String? finalNetId;

    if (manualNetId) {
      finalNetId = manualNetIdController.text.trim();
      if (finalNetId.isEmpty || !finalNetId.contains(".")) {
        addLog("❌ Invalid manual Net ID");
        return;
      }
    } else {
      finalNetId = netId;
      if (finalNetId == null) {
        addLog("❌ No valid Net ID found.");
        return;
      }
    }

    scanning = true;
    foundIps.clear();
    logs.clear();
    setState(() {});

    addLog("🔍 Starting scan on $finalNetId.x ...");

    List<Future> tasks = [];

    for (int i = 1; i < 255; i++) {
      final target = "$finalNetId.$i";
      tasks.add(scanIp(target));
    }

    await Future.wait(tasks);

    addLog("✅ Scan finished. Found ${foundIps.length} hosts.");
    scanning = false;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    detectLocalIp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(title: const Text("IP Finder")),
        const Divider(),
      ],
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // IP Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.gray.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Local IP: $localIp",
                    style: const TextStyle(color: Colors.green, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  // Mode selector
                  Row(
                    children: [
                      const Text("Net ID Mode:", style: TextStyle(color: Colors.cyan)),
                      const SizedBox(width: 12),
                      Select<bool>(
                        value: manualNetId,
                        onChanged: (value) {
                          setState(() => manualNetId = value!);
                        },
                        itemBuilder: (context, item) {
                          return Text(item ? "Manual" : "Automatic");
                        },
                        placeholder: const Text("Select Mode"),
                        popup: SelectPopup(
                          items: SelectItemList(
                            children: [
                              SelectItemButton(
                                value: false,
                                child: const Text("Automatic"),
                              ),
                              SelectItemButton(
                                value: true,
                                child: const Text("Manual"),
                              ),
                            ],
                          ),
                        ).call,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (!manualNetId)
                    Text(
                      "Net ID: ${netId ?? "---"}",
                      style: const TextStyle(color: Colors.cyan, fontSize: 16),
                    ),

                  if (manualNetId)
                    TextField(
                      controller: manualNetIdController,
                      placeholder: const Text("Enter Net ID (e.g. 192.168.1)"),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Button(
              onPressed: scanning ? null : startScan,
              style: ButtonStyle.primary(),
              child: Text(scanning ? "Scanning..." : "Start Scan"),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: logs.isEmpty
                    ? const Center(
                        child: Text(
                          "Waiting...",
                          style: TextStyle(color: Colors.green),
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          return SelectableText(
                            logs[index],
                            style: TextStyle(
                              fontFamily: "monospace",
                              color: Colors.green.withOpacity(0.8),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}