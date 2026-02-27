import 'dart:io';
import 'dart:convert';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class TcpServerPage extends StatefulWidget {
  const TcpServerPage({super.key});

  @override
  State<TcpServerPage> createState() => _TcpServerPageState();
}

class _TcpServerPageState extends State<TcpServerPage> {
  final TextEditingController portController = TextEditingController();
  final TextEditingController welcomeController = TextEditingController();

  ServerSocket? server;
  bool isListening = false;
  bool bindAll = true;

  final List<_LogItem> logs = [];
  final List<Socket> connectedClients = [];

  void addLog(String message, LogType type) {
    setState(() {
      logs.insert(
        0,
        _LogItem(message: message, type: type, time: DateTime.now()),
      );
    });
  }

  Future<void> startServer() async {
    final port = int.tryParse(portController.text.trim());

    if (port == null) {
      addLog("Invalid port", LogType.error);
      return;
    }

    final host = bindAll
        ? InternetAddress.anyIPv4
        : InternetAddress(await _getLocalIp());

    try {
      server = await ServerSocket.bind(host, port);
      setState(() => isListening = true);

      addLog("Listening on ${server!.address.address}:$port", LogType.info);

      server!.listen((client) {
        connectedClients.add(client);

        addLog(
          "Client connected: ${client.remoteAddress.address}:${client.remotePort}",
          LogType.connected,
        );

        final welcomeMsg = welcomeController.text.trim();
        if (welcomeMsg.isNotEmpty) {
          client.write(welcomeMsg);
        }

        client.listen(
          (data) {
            final message = utf8.decode(data);
            addLog(
              "From ${client.remoteAddress.address}: $message",
              LogType.received,
            );
          },
          onDone: () {
            addLog(
              "Client disconnected: ${client.remoteAddress.address}",
              LogType.info,
            );
            connectedClients.remove(client);
            client.destroy();
          },
          onError: (error) {
            addLog("Client error: $error", LogType.error);
          },
        );
      });
    } catch (e) {
      addLog("Server start failed: $e", LogType.error);
    }
  }

  Future<String> _getLocalIp() async {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          return addr.address;
        }
      }
    }
    return "0.0.0.0";
  }

  void stopServer() {
    for (var client in connectedClients) {
      client.destroy();
    }
    connectedClients.clear();

    server?.close();
    server = null;

    setState(() => isListening = false);
    addLog("Server stopped", LogType.info);
  }

  void clearLogs() {
    setState(() => logs.clear());
  }

  // رنگ‌ها بدون Material
  Color getLogColor(LogType type) {
    switch (type) {
      case LogType.received:
        return const Color(0xFF22C55E); // green
      case LogType.connected:
        return const Color(0xFF06B6D4); // cyan
      case LogType.error:
        return const Color(0xFFEF4444); // red
      case LogType.info:
        return const Color(0xFFF59E0B); // orange
    }
  }

  @override
  void dispose() {
    for (var client in connectedClients) {
      client.destroy();
    }
    connectedClients.clear();

    server?.close();
    server = null;

    portController.dispose();
    welcomeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          title: const Text("TCP Server"),
          trailing: [
            Button(
              style: ButtonStyle.destructive(),
              onPressed: clearLogs,
              child: const Text("Clear Logs"),
            ),
          ],
        ),
        const Divider(),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (!isListening) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: portController,
                        placeholder: const Text("Port"),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text("Bind to"),
                          const SizedBox(width: 12),
                          Select<bool>(
                            value: bindAll,
                            onChanged: (value) {
                              setState(() => bindAll = value!);
                            },
                            itemBuilder: (context, item) {
                              return Text(item ? "0.0.0.0" : "Device IP");
                            },
                            placeholder: const Text("Select Bind IP"),
                            popup: SelectPopup(
                              items: SelectItemList(
                                children: [
                                  SelectItemButton(
                                    value: true,
                                    child: const Text("0.0.0.0"),
                                  ),
                                  SelectItemButton(
                                    value: false,
                                    child: const Text("Device IP"),
                                  ),
                                ],
                              ),
                            ).call,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: welcomeController,
                        placeholder: const Text("Welcome message (optional)"),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: Button(
                          style: ButtonStyle.primary(),
                          onPressed: startServer,
                          child: const Text("Start Listening"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: Button(
                  style: ButtonStyle.destructive(),
                  onPressed: stopServer,
                  child: const Text("Stop Server"),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Logs Section
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: logs.isEmpty
                      ? const Center(
                          child: Text(
                            "No logs yet...",
                            style: TextStyle(fontFamily: "monospace"),
                          ),
                        )
                      : ListView.builder(
                          reverse: true,
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            final time =
                                "${log.time.hour.toString().padLeft(2, '0')}:"
                                "${log.time.minute.toString().padLeft(2, '0')}:"
                                "${log.time.second.toString().padLeft(2, '0')}";

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                "[$time] ${log.message}",
                                style: TextStyle(
                                  fontFamily: "monospace",
                                  color: getLogColor(log.type),
                                ),
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

enum LogType { received, connected, error, info }

class _LogItem {
  final String message;
  final LogType type;
  final DateTime time;

  _LogItem({required this.message, required this.type, required this.time});
}
