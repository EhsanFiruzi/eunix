import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shadcn_flutter/shadcn_flutter.dart';

class TraceroutePage extends StatefulWidget {
  const TraceroutePage({super.key});

  @override
  State<TraceroutePage> createState() => _TraceroutePageState();
}

class _TraceroutePageState extends State<TraceroutePage> {
  final TextEditingController targetController = TextEditingController();

  bool isTracing = false;
  List<String> hops = [];

  Process? traceProcess;

  final ScrollController logScroll = ScrollController();

  void addHop(String text) {
    setState(() {
      hops.add(text);
    });

    Future.delayed(const Duration(milliseconds: 50), () {
      if (logScroll.hasClients) {
        logScroll.jumpTo(logScroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> startTraceroute() async {
    final target = targetController.text.trim();
    if (target.isEmpty) {
      addHop("❌ Enter a valid IP or domain");
      return;
    }

    setState(() {
      isTracing = true;
      hops.clear();
    });

    final isWindows = Platform.isWindows;
    final cmd = isWindows ? "tracert" : "traceroute";
    final args = [target];

    traceProcess = await Process.start(cmd, args);

    traceProcess!.stdout.transform(utf8.decoder).listen((line) {
      line = line.trim();
      if (line.isNotEmpty) {
        addHop("🟢 $line");
      }
    });

    traceProcess!.stderr.transform(utf8.decoder).listen((line) {
      addHop("🔴 $line");
    });

    traceProcess!.exitCode.then((_) {
      setState(() => isTracing = false);
    });
  }

  void stopTraceroute() {
    traceProcess?.kill();
    setState(() => isTracing = false);
  }

  Widget hopCard(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.green.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyan.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.cyan,
          fontFamily: "monospace",
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          title: const Text("Traceroute"),
          trailing: [
            IconButton(
              icon: const Icon(Icons.stop_circle),
              variance: ButtonStyle.destructive(),
              onPressed: isTracing ? stopTraceroute : null,
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
            // Input + Start Button
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
                  onPressed: isTracing ? stopTraceroute : startTraceroute,
                  style: isTracing
                      ? ButtonStyle.destructive()
                      : ButtonStyle.primary(),
                  child: Text(isTracing ? "Stop" : "Start"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Hop List
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: hops.isEmpty
                    ? const Center(
                        child: Text(
                          "Waiting...",
                          style: TextStyle(
                            color: Colors.cyan,
                            fontFamily: "monospace",
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: logScroll,
                        itemCount: hops.length,
                        itemBuilder: (context, index) {
                          return hopCard(hops[index]);
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