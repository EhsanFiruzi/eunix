import 'dart:io';
import 'dart:convert';
import 'package:shadcn_flutter/shadcn_flutter.dart';

enum ProxyMode { manual, dynamic }

enum LogType { received, connected, error, info }

class TcpProxyPage extends StatefulWidget {
  const TcpProxyPage({super.key});

  @override
  State<TcpProxyPage> createState() => _TcpProxyPageState();
}

class _TcpProxyPageState extends State<TcpProxyPage> {
  final TextEditingController localPortController = TextEditingController();
  final TextEditingController remoteHostController = TextEditingController();
  final TextEditingController remotePortController = TextEditingController();

  ProxyMode mode = ProxyMode.manual;
  bool bindAll = true;
  bool isRunning = false;

  ServerSocket? server;
  final List<Socket> clients = [];
  final List<_ProxyLog> logs = [];
  final ScrollController logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    remoteHostController.text = "example.com";
    remotePortController.text = "80";
  }

  @override
  void dispose() {
    for (var client in clients) {
      client.destroy();
    }
    clients.clear();
    server?.close();

    localPortController.dispose();
    remoteHostController.dispose();
    remotePortController.dispose();
    super.dispose();
  }

  void addLog(String message, LogType type) {
    setState(() {
      logs.insert(
        0,
        _ProxyLog(message: message, type: type, time: DateTime.now()),
      );
    });
  }

  Color getLogColor(LogType type) {
    switch (type) {
      case LogType.received:
        return const Color(0xFF22C55E);
      case LogType.connected:
        return const Color(0xFF06B6D4);
      case LogType.error:
        return const Color(0xFFEF4444);
      case LogType.info:
        return const Color(0xFFF59E0B);
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

  Future<void> startProxy() async {
    final localPort = int.tryParse(localPortController.text.trim());

    if (localPort == null) {
      addLog("Invalid local port", LogType.error);
      return;
    }

    final host = bindAll
        ? InternetAddress.anyIPv4
        : InternetAddress(await _getLocalIp());

    try {
      server = await ServerSocket.bind(host, localPort);
      setState(() => isRunning = true);

      addLog("Listening on ${host.address}:$localPort", LogType.info);

      server!.listen((client) {
        clients.add(client);

        addLog(
          "Client ${client.remoteAddress.address}:${client.remotePort}",
          LogType.connected,
        );

        Socket? remote;
        bool isHttpsTunnel = false;

        client.listen(
          (data) async {
            try {
              // اگر هنوز به ریموت وصل نشدیم
              if (remote == null) {
                final request = utf8.decode(data, allowMalformed: true);

                String? targetHost;
                int targetPort = 80;

                // =======================
                // HTTPS (CONNECT)
                // =======================
                if (request.startsWith("CONNECT")) {
                  isHttpsTunnel = true;

                  final parts = request.split(" ");
                  final hostPort = parts[1].split(":");

                  targetHost = hostPort[0];
                  targetPort = int.parse(hostPort[1]);

                  remote = await Socket.connect(targetHost, targetPort);

                  addLog(
                    "HTTPS Tunnel → $targetHost:$targetPort",
                    LogType.info,
                  );

                  // فقط همین پاسخ لازمه
                  client.write("HTTP/1.1 200 Connection Established\r\n\r\n");

                  // Remote → Client (raw TLS forward)
                  remote!.listen(
                    (rData) {
                      client.add(rData);
                      addLog(
                        "[R→C] ${rData.length} bytes (TLS)",
                        LogType.received,
                      );
                    },
                    onDone: () {
                      remote?.destroy();
                      client.destroy();
                    },
                    onError: (e) {
                      addLog("Remote error: $e", LogType.error);
                    },
                  );

                  return; // مهم
                }

                // =======================
                // HTTP معمولی
                // =======================
                final match = RegExp(
                  r'Host:\s*(.+)',
                  caseSensitive: false,
                ).firstMatch(request);

                if (match != null) {
                  final hostLine = match.group(1)!;

                  if (hostLine.contains(":")) {
                    final split = hostLine.split(":");
                    targetHost = split[0];
                    targetPort = int.parse(split[1]);
                  } else {
                    targetHost = hostLine;
                  }
                }

                if (targetHost == null) {
                  addLog("Host detection failed", LogType.error);
                  client.destroy();
                  return;
                }

                remote = await Socket.connect(targetHost, targetPort);

                addLog("Connected → $targetHost:$targetPort", LogType.info);

                // Remote → Client
                remote!.listen(
                  (rData) {
                    client.add(rData);

                    final text = utf8.decode(rData, allowMalformed: true);
                    addLog("[R→C]\n$text", LogType.received);
                  },
                  onDone: () {
                    remote?.destroy();
                    client.destroy();
                  },
                  onError: (e) {
                    addLog("Remote error: $e", LogType.error);
                  },
                );
              }

              // =======================
              // Client → Remote
              // =======================
              remote!.add(data);

              if (isHttpsTunnel) {
                addLog("[C→R] ${data.length} bytes (TLS)", LogType.received);
              } else {
                final text = utf8.decode(data, allowMalformed: true);
                addLog("[C→R]\n$text", LogType.received);
              }
            } catch (e) {
              addLog("Proxy error: $e", LogType.error);
            }
          },
          onDone: () {
            clients.remove(client);
            client.destroy();
            remote?.destroy();
            addLog("Client disconnected", LogType.info);
          },
          onError: (e) {
            addLog("Client error: $e", LogType.error);
          },
        );
      });
    } catch (e) {
      addLog("Start failed: $e", LogType.error);
    }
  }

  void stopProxy() {
    for (var client in clients) {
      client.destroy();
    }
    clients.clear();
    server?.close();
    server = null;
    setState(() => isRunning = false);
    addLog("Proxy stopped", LogType.info);
  }

  void clearLogs() {
    setState(() => logs.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          title: const Text("TCP Proxy"),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!isRunning)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: localPortController,
                        placeholder: const Text("Local Port"),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text("Bind"),
                          const SizedBox(width: 12),
                          Select<bool>(
                            value: bindAll,
                            onChanged: (v) => setState(() => bindAll = v!),
                            itemBuilder: (_, v) =>
                                Text(v ? "0.0.0.0" : "Device IP"),
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text("Mode"),
                          const SizedBox(width: 12),
                          Select<ProxyMode>(
                            value: mode,
                            onChanged: (v) => setState(() => mode = v!),
                            itemBuilder: (_, v) => Text(
                              v == ProxyMode.manual ? "Manual" : "Dynamic",
                            ),
                            popup: SelectPopup(
                              items: SelectItemList(
                                children: [
                                  SelectItemButton(
                                    value: ProxyMode.manual,
                                    child: const Text("Manual"),
                                  ),
                                  SelectItemButton(
                                    value: ProxyMode.dynamic,
                                    child: const Text("Dynamic"),
                                  ),
                                ],
                              ),
                            ).call,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (mode == ProxyMode.manual) ...[
                        TextField(
                          controller: remoteHostController,
                          placeholder: const Text("Remote Host"),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: remotePortController,
                          placeholder: const Text("Remote Port"),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: Button(
                          style: ButtonStyle.primary(),
                          onPressed: startProxy,
                          child: const Text("Start Proxy"),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: Button(
                  style: ButtonStyle.destructive(),
                  onPressed: stopProxy,
                  child: const Text("Stop Proxy"),
                ),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: logs.isEmpty
                      ? const Center(
                          child: Text(
                            "No logs yet...",
                            style: TextStyle(fontFamily: "monospace"),
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
                              final log = logs[index];
                              final time =
                                  "${log.time.hour.toString().padLeft(2, '0')}:"
                                  "${log.time.minute.toString().padLeft(2, '0')}:"
                                  "${log.time.second.toString().padLeft(2, '0')}";
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: SelectableText(
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
            ),
          ],
        ),
      ),
    );
  }
}

class _ProxyLog {
  final String message;
  final LogType type;
  final DateTime time;

  _ProxyLog({required this.message, required this.type, required this.time});
}
