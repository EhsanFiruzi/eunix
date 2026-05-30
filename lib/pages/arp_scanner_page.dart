import 'dart:async';
import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ArpScannerPage extends StatefulWidget {
  const ArpScannerPage({super.key});

  @override
  State<ArpScannerPage> createState() => _ArpScannerPageState();
}

class _ArpScannerPageState extends State<ArpScannerPage> {
  final NetworkInfo _info = NetworkInfo();
  final TextEditingController subnetController = TextEditingController();

  bool isScanning = false;
  bool manualMode = false;

  String subnetBase = "";
  String localIp = "";
  int currentHost = 0;
  int totalHosts = 254;

  List<_DeviceEntry> devices = [];
  List<String> logs = [];

  final ScrollController logScroll = ScrollController();

  void addLog(String text) {
    setState(() => logs.insert(0, text));
    Future.delayed(const Duration(milliseconds: 50), () {
      if (logScroll.hasClients) {
        logScroll.jumpTo(logScroll.position.minScrollExtent);
      }
    });
  }

  Future<void> initNetwork() async {
    localIp = await _info.getWifiIP() ?? "";

    if (localIp.isNotEmpty) {
      final parts = localIp.split(".");
      subnetBase = "${parts[0]}.${parts[1]}.${parts[2]}";
      subnetController.text = "$subnetBase.0/24";
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initNetwork();
  }

  Future<bool> pingHost(String ip) async {
    try {
      final sw = Stopwatch()..start();
      final result = await Process.run("ping", ["-c", "1", "-W", "1", ip]);
      sw.stop();

      if (result.exitCode == 0) {
        devices.add(
          _DeviceEntry(ip: ip, latencyMs: sw.elapsedMilliseconds.toDouble()),
        );
        addLog("🟢 $ip responded in ${sw.elapsedMilliseconds}ms");
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getMacForIp(String ip) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));

      final res = await Process.run("ip", ["neigh"]);
      if (res.exitCode == 0) {
        final lines = res.stdout.toString().split("\n");
        for (final line in lines) {
          if (line.contains(ip) && line.contains("lladdr")) {
            final parts = line.split(" ");
            final idx = parts.indexOf("lladdr");
            if (idx != -1 && idx + 1 < parts.length) {
              return parts[idx + 1].trim();
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  IconData getDeviceIcon(String? mac) {
    if (mac == null) return Icons.device_unknown;

    final oui = mac.substring(0, 8).toUpperCase();

    if (oui.startsWith("FC:EC:DA") || oui.startsWith("D8:BB:C1")) {
      return Icons.phone_android;
    }
    if (oui.startsWith("A4:50:46")) {
      return Icons.phone_android;
    }
    if (oui.startsWith("F4:F5:D8")) {
      return Icons.phone_iphone;
    }
    if (oui.startsWith("00:1A:2B")) {
      return Icons.router;
    }

    return Icons.devices_other;
  }

  Future<void> startScan() async {
    if (manualMode) {
      final input = subnetController.text.trim();

      if (!input.contains("/")) {
        addLog("❌ Invalid format. Example: 10.0.2.0/24");
        return;
      }

      final parts = input.split("/");
      final base = parts[0];
      final mask = parts[1];

      if (mask != "24") {
        addLog("❌ Only /24 is supported");
        return;
      }

      final ipParts = base.split(".");
      if (ipParts.length != 4) {
        addLog("❌ Invalid IP format");
        return;
      }

      subnetBase = "${ipParts[0]}.${ipParts[1]}.${ipParts[2]}";
    } else {
      await initNetwork();
      if (subnetBase.isEmpty) {
        addLog("❌ Cannot detect subnet");
        return;
      }
    }

    setState(() {
      isScanning = true;
      devices.clear();
      logs.clear();
      currentHost = 0;
    });

    addLog("🚀 Starting ARP scan on $subnetBase.0/24");

    for (int i = 1; i <= 254; i++) {
      if (!isScanning) break;

      final ip = "$subnetBase.$i";
      currentHost = i;
      setState(() {});

      final alive = await pingHost(ip);
      if (alive) {
        final idx = devices.indexWhere((d) => d.ip == ip);
        if (idx != -1) {
          final mac = await getMacForIp(ip);
          if (mac != null) {
            devices[idx] = devices[idx].copyWith(mac: mac);
          }
        }
      }
    }

    setState(() => isScanning = false);
    addLog("✅ Scan finished");
  }

  void stopScan() {
    setState(() => isScanning = false);
    addLog("⛔ Scan stopped");
  }

  Widget deviceCard(_DeviceEntry d) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.green.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyan.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(getDeviceIcon(d.mac), color: Colors.cyan, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.ip,
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: "monospace",
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "MAC: ${d.mac ?? "Unknown"}",
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontSize: 13,
                    fontFamily: "monospace",
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Latency: ${d.latencyMs?.toStringAsFixed(1) ?? "-"} ms",
                  style: TextStyle(
                    color: Colors.cyan.withOpacity(0.8),
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

  Widget progressBar() {
    if (!isScanning) return const SizedBox.shrink();

    final progress = currentHost / totalHosts;
    final percent = (progress * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Scanning: $currentHost / $totalHosts  ($percent%)",
          style: const TextStyle(color: Colors.cyan, fontFamily: "monospace"),
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.green.withOpacity(0.2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0, 1),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.cyan,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget logBox() {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withOpacity(0.4)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 120),
        child: logs.isEmpty
            ? const Text(
                "Waiting...",
                style: TextStyle(color: Colors.cyan, fontFamily: "monospace"),
              )
            : ListView.builder(
                controller: logScroll,
                reverse: true,
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  return Text(
                    logs[index],
                    style: const TextStyle(
                      color: Colors.cyan,
                      fontFamily: "monospace",
                      fontSize: 12,
                    ),
                  );
                },
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(title: const Text("ARP Scanner")),
        const Divider(),
      ],
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // MODE SELECTOR
            // MODE SELECTOR (Auto / Manual)
            Row(
              children: [
                const Text("Subnet:", style: TextStyle(color: Colors.cyan)),
                const SizedBox(width: 12),
                Expanded(
                  child: Select<bool>(
                    value: manualMode,
                    onChanged: (value) {
                      setState(() => manualMode = value!);
                    },
                    itemBuilder: (context, item) {
                      return Text(
                        item ? "Manual" : "Automatic",
                        style: const TextStyle(
                          color: Colors.cyan,
                          fontFamily: "monospace",
                        ),
                      );
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
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (manualMode)
              TextField(
                controller: subnetController,
                placeholder: const Text("Enter subnet (e.g. 10.0.2.0/24)"),
              ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Text(
                    "Local IP: $localIp",
                    style: const TextStyle(
                      color: Colors.cyan,
                      fontFamily: "monospace",
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Button(
                  onPressed: isScanning ? stopScan : startScan,
                  style: isScanning
                      ? ButtonStyle.destructive()
                      : ButtonStyle.primary(),
                  child: Text(isScanning ? "Stop" : "Start Scan"),
                ),
              ],
            ),

            const SizedBox(height: 12),

            progressBar(),

            const SizedBox(height: 12),

            logBox(),

            Expanded(
              child: devices.isEmpty
                  ? const Center(
                      child: Text(
                        "No devices found yet",
                        style: TextStyle(
                          color: Colors.cyan,
                          fontFamily: "monospace",
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        return deviceCard(devices[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceEntry {
  final String ip;
  final String? mac;
  final double? latencyMs;

  _DeviceEntry({required this.ip, this.mac, this.latencyMs});

  _DeviceEntry copyWith({String? ip, String? mac, double? latencyMs}) {
    return _DeviceEntry(
      ip: ip ?? this.ip,
      mac: mac ?? this.mac,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }
}
