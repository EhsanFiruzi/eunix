import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shadcn_flutter/shadcn_flutter.dart';

class PingToolPage extends StatefulWidget {
  const PingToolPage({super.key});

  @override
  State<PingToolPage> createState() => _PingToolPageState();
}

class _PingToolPageState extends State<PingToolPage> {
  final TextEditingController targetController = TextEditingController();

  bool isPinging = false;
  bool continuous = false;

  List<double> latencies = [];
  List<String> logs = [];

  double avgLatency = 0;
  double jitter = 0;
  double packetLoss = 0;

  Process? pingProcess;

  // 🔥 اضافه شد
  final ScrollController chartScrollController = ScrollController();

  void addLog(String text) {
    setState(() {
      logs.insert(0, text);
    });
  }

  Future<void> startPing() async {
    final target = targetController.text.trim();
    if (target.isEmpty) {
      addLog("❌ Enter a valid IP or domain");
      return;
    }

    setState(() {
      isPinging = true;
      latencies.clear();
      logs.clear();
      avgLatency = 0;
      jitter = 0;
      packetLoss = 0;
    });

    final args = continuous ? ["-O", target] : ["-c", "5", target];

    pingProcess = await Process.start("ping", args);

    pingProcess!.stdout.transform(utf8.decoder).listen((line) {
      line = line.trim();

      if (line.contains("time=")) {
        final match = RegExp(r'time=([\d\.]+)').firstMatch(line);
        if (match != null) {
          final latency = double.parse(match.group(1)!);
          latencies.add(latency);

          addLog("🟢 Reply: ${latency}ms");
          updateStats();
        }
      }

      if (line.contains("Destination Host Unreachable")) {
        addLog("🔴 Host unreachable");
      }
    });

    pingProcess!.exitCode.then((_) {
      if (!continuous) {
        setState(() => isPinging = false);
      }
    });
  }

  void updateStats() {
    if (latencies.isEmpty) return;

    avgLatency = latencies.reduce((a, b) => a + b) / latencies.length;

    if (latencies.length > 1) {
      jitter = (latencies.last - latencies[latencies.length - 2]).abs();
    }

    packetLoss = 0;
    setState(() {});

    // 🔥 اسکرول خودکار چارت
    Future.delayed(const Duration(milliseconds: 50), () {
      if (chartScrollController.hasClients) {
        chartScrollController.jumpTo(
          chartScrollController.position.maxScrollExtent,
        );
      }
    });
  }

  void stopPing() {
    pingProcess?.kill();
    setState(() => isPinging = false);
  }

  String buildAsciiChart() {
    if (latencies.isEmpty) return "No data yet";

    final maxVal = latencies.reduce((a, b) => a > b ? a : b);
    final buffer = StringBuffer();

    for (var l in latencies.take(20)) {
      final bars = (l / maxVal * 20).clamp(1, 20).toInt();
      buffer.writeln("${l.toStringAsFixed(1)} ms | ${"█" * bars}");
    }

    return buffer.toString();
  }

  Widget statCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.cyan,
              fontSize: 14,
              fontFamily: "monospace",
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.cyan,
              fontSize: 18,
              fontFamily: "monospace",
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 نسخه اصلاح‌شده infoCard با اسکرول خودکار
  Widget infoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.green.withOpacity(0.05)],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.cyan, size: 26),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: "monospace",
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            height: 1,
            color: Colors.cyan.withOpacity(0.25),
            margin: const EdgeInsets.only(bottom: 10),
          ),

          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 100),
            child: SingleChildScrollView(
              controller: chartScrollController, // 🔥 اضافه شد
              physics: const BouncingScrollPhysics(),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.cyan,
                  fontSize: 15,
                  fontFamily: "monospace",
                ),
              ),
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
          title: const Text("Ping Tool"),
          trailing: [
            IconButton(
              icon: const Icon(Icons.stop_circle),
              variance: ButtonStyle.destructive(),
              onPressed: isPinging ? stopPing : null,
            ),
          ],
        ),
        const Divider(),
      ],
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: targetController,
                    placeholder: const Text("Enter IP or domain"),
                  ),
                ),
                const SizedBox(width: 12),
                Button(
                  onPressed: isPinging ? stopPing : startPing,
                  style: isPinging
                      ? ButtonStyle.destructive()
                      : ButtonStyle.primary(),
                  child: Text(isPinging ? "Stop" : "Start"),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Checkbox(
                  state: continuous
                      ? CheckboxState.checked
                      : CheckboxState.unchecked,
                  onChanged: (v) =>
                      setState(() => continuous = v == CheckboxState.checked),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Continuous Ping",
                  style: TextStyle(color: Colors.cyan),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: statCard("Avg", "${avgLatency.toStringAsFixed(1)} ms"),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: statCard("Jitter", "${jitter.toStringAsFixed(1)} ms"),
                ),
                const SizedBox(width: 12),
                Expanded(child: statCard("Loss", "$packetLoss%")),
              ],
            ),

            const SizedBox(height: 20),

            infoCard("Latency Chart", buildAsciiChart(), Icons.show_chart),

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
                          style: TextStyle(color: Colors.cyan),
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          return Text(
                            logs[index],
                            style: const TextStyle(
                              color: Colors.cyan,
                              fontFamily: "monospace",
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
