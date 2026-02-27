import 'dart:io';
import 'dart:convert';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class TcpClientPage extends StatefulWidget {
  const TcpClientPage({super.key});

  @override
  State<TcpClientPage> createState() => _TcpClientPageState();
}

class _TcpClientPageState extends State<TcpClientPage> {
  final TextEditingController ipController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  Socket? socket;
  bool isConnected = false;

  List<_LogItem> logs = [];

  void addLog(String message, LogType type) {
    setState(() {
      logs.insert(
        0,
        _LogItem(message: message, type: type, time: DateTime.now()),
      );
    });
  }

  Future<void> connect() async {
    final ip = ipController.text.trim();
    final port = int.tryParse(portController.text.trim());

    if (ip.isEmpty || port == null) {
      addLog("Invalid IP or Port", LogType.error);
      return;
    }

    try {
      socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 5),
      );

      setState(() => isConnected = true);

      addLog("Connected to $ip:$port", LogType.info);

      socket!.listen(
        (data) {
          final message = utf8.decode(data);
          addLog("Received: $message", LogType.received);
        },
        onError: (error) {
          addLog("Error: $error", LogType.error);
          disconnect();
        },
        onDone: () {
          addLog("Connection closed by server", LogType.info);
          disconnect();
        },
      );
    } catch (e) {
      addLog("Connection failed: $e", LogType.error);
    }
  }

  void disconnect() {
    socket?.destroy();
    socket = null;
    setState(() => isConnected = false);
  }

  void sendMessage() {
    if (!isConnected || socket == null) return;

    final message = messageController.text;
    if (message.isEmpty) return;

    socket!.write(message);
    addLog("Sent: $message", LogType.sent);

    messageController.clear();
  }

  void clearLogs() {
    setState(() => logs.clear());
  }

  Color getLogColor(LogType type) {
    switch (type) {
      case LogType.sent:
        return Colors.cyan;
      case LogType.received:
        return Colors.green;
      case LogType.error:
        return Colors.red;
      case LogType.info:
        return Colors.orange;
    }
  }

  @override
  void dispose() {
    disconnect();
    ipController.dispose();
    portController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          title: const Text("TCP Client"),
          trailing: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: clearLogs,
              variance: ButtonStyle.destructive(),
            ),
          ],
        ),
        const Divider(),
      ],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Connection Section
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ipController,
                    placeholder: const Text('IP Address'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: portController,
                    placeholder: const Text('Port'),
                  ),
                ),
                const SizedBox(width: 12),
                Button(
                  onPressed: isConnected ? disconnect : connect,
                  style: isConnected
                      ? ButtonStyle.destructive()
                      : ButtonStyle.primary(),
                  child: Text(isConnected ? "Disconnect" : "Connect"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🔹 Message Sender
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    placeholder: const Text('Enter your name'),
                  ),
                ),
                const SizedBox(width: 12),
                Button(
                  onPressed: isConnected ? sendMessage : null,
                  style: ButtonStyle.primary(),
                  child: const Text("Send"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🔹 Logs Section
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.gray.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: logs.isEmpty
                    ? const Center(
                        child: Text(
                          "No logs yet...",
                          style: TextStyle(color: Colors.gray),
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              "[${log.time.hour}:${log.time.minute}:${log.time.second}] ${log.message}",
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
          ],
        ),
      ),
    );
  }
}

enum LogType { sent, received, error, info }

class _LogItem {
  final String message;
  final LogType type;
  final DateTime time;

  _LogItem({required this.message, required this.type, required this.time});
}
