import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shadcn_flutter/shadcn_flutter.dart';

class PortScannerPage extends StatefulWidget {
  const PortScannerPage({super.key});

  @override
  State createState() => _PortScannerPageState();
}

class _PortScannerPageState extends State<PortScannerPage> {
  final TextEditingController ipController = TextEditingController();
  final TextEditingController portRangeController = TextEditingController(
    text: "1-1024",
  );

  final List<String> logs = [];
  final ScrollController logScrollController = ScrollController();

  bool scanning = false;
  int maxConcurrent = 200; // سرعت بالا ولی منطقی

  void addLog(String text) {
    setState(() {
      logs.insert(
        0,
        "[${DateTime.now().toIso8601String().substring(11, 19)}] $text",
      );
    });

    Future.delayed(const Duration(milliseconds: 50), () {
      if (logScrollController.hasClients) {
        logScrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<int> parsePortRange(String input) {
    input = input.trim();
    if (input.contains("-")) {
      final parts = input.split("-");
      if (parts.length == 2) {
        final start = int.tryParse(parts[0].trim()) ?? 0;
        final end = int.tryParse(parts[1].trim()) ?? 0;
        if (start > 0 && end >= start) {
          return List.generate(end - start + 1, (i) => start + i);
        }
      }
    } else {
      final single = int.tryParse(input);
      if (single != null && single > 0) {
        return [single];
      }
    }
    return [];
  }

  Future<bool> scanTcp(String ip, int port) async {
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(milliseconds: 200),
      );
      socket.destroy();

      addLog("🟢 TCP OPEN  $ip:$port");
      return true;
    } catch (e) {
      // پورت بسته → هیچ لاگی چاپ نکن
      return false;
    }
  }

  Future<void> scanUdp(String ip, int port) async {
    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
        reusePort: true,
      );

      socket.send(utf8.encode("ping"), InternetAddress(ip), port);

      final completer = Completer();

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            addLog("🟢 UDP OPEN  $ip:$port");
            if (!completer.isCompleted) completer.complete();
          }
        }
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!completer.isCompleted) completer.complete();
      });

      await completer.future;
      socket.close();
    } catch (e) {
      // پورت بسته → هیچ لاگی چاپ نکن
    }
  }

  Future<void> startScan() async {
    final ip = ipController.text.trim();
    final ports = parsePortRange(portRangeController.text);

    if (ip.isEmpty || ports.isEmpty) {
      addLog("❌ Invalid IP or Port range");
      return;
    }

    scanning = true;
    logs.clear();
    setState(() {});

    addLog("⚡ Starting scan on $ip, ports: ${ports.first}-${ports.last}");

    final semaphore = _Semaphore(maxConcurrent);
    final List<Future> tasks = [];

    for (final port in ports) {
      tasks.add(_scanPortWithSemaphore(ip, port, semaphore));
    }

    await Future.wait(tasks);

    addLog("✅ Scan finished.");
    scanning = false;
    setState(() {});
  }

  Future<void> _scanPortWithSemaphore(
    String ip,
    int port,
    _Semaphore semaphore,
  ) async {
    await semaphore.acquire();
    try {
      await Future.wait([scanTcp(ip, port), scanUdp(ip, port)]);
    } finally {
      semaphore.release();
    }
  }

  @override
  void dispose() {
    ipController.dispose();
    portRangeController.dispose();
    logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          title: const Text("Port Scanner"),
          trailing: [
            IconButton(
              icon: const Icon(Icons.delete),
              variance: ButtonStyle.destructive(),
              onPressed: () {
                setState(() => logs.clear());
              },
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
            // IP + Port Range Inputs
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.gray.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ipController,
                          placeholder: const Text(
                            "Target IP (e.g. 192.168.1.10)",
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: portRangeController,
                          placeholder: const Text(
                            "Port range (e.g. 1-1024 or 80)",
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Button(
                      onPressed: scanning ? null : startScan,
                      style: ButtonStyle.primary(),
                      child: Text(scanning ? "Scanning..." : "Start Scan"),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Logs
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.gray.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: logs.isEmpty
                    ? const Center(
                        child: Text(
                          "No logs yet...",
                          style: TextStyle(
                            color: Colors.green,
                            fontFamily: "monospace",
                          ),
                        ),
                      )
                    : Scrollbar(
                        controller: logScrollController,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: logScrollController,
                          reverse: true,
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            return SelectableText(
                              logs[index],
                              style: TextStyle(
                                fontFamily: "monospace",
                                color: Colors.green.withOpacity(0.85),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ساده‌ترین پیاده‌سازی Semaphore برای محدود کردن کانکشن‌های همزمان
class _Semaphore {
  int _available;
  final List<VoidCallback> _waitQueue = [];

  _Semaphore(this._available);

  Future<void> acquire() {
    if (_available > 0) {
      _available--;
      return Future.value();
    }
    final completer = Completer<void>();
    _waitQueue.add(() {
      _available--;
      completer.complete();
    });
    return completer.future;
  }

  void release() {
    _available++;
    if (_waitQueue.isNotEmpty && _available > 0) {
      final next = _waitQueue.removeAt(0);
      next();
    }
  }
}
