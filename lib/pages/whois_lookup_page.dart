import 'dart:convert';
import 'dart:io';

import 'package:shadcn_flutter/shadcn_flutter.dart';

class WhoisLookupPage extends StatefulWidget {
  const WhoisLookupPage({super.key});

  @override
  State<WhoisLookupPage> createState() => _WhoisLookupPageState();
}

class _WhoisLookupPageState extends State<WhoisLookupPage> {
  final TextEditingController domainController = TextEditingController();

  bool isLoading = false;

  String registrant = "—";
  String registrar = "—";
  String created = "—";
  String expires = "—";
  String rawWhois = "";

  Future<void> runWhois() async {
    final domain = domainController.text.trim();
    if (domain.isEmpty) return;

    setState(() {
      isLoading = true;
      registrant = "—";
      registrar = "—";
      created = "—";
      expires = "—";
      rawWhois = "";
    });

    try {
      final uri = Uri.parse("https://api.hackertarget.com/whois/?q=$domain");
      final client = HttpClient();
      final req = await client.getUrl(uri);
      final res = await req.close();

      final body = await res.transform(utf8.decoder).join();
      rawWhois = body;

      // استخراج اطلاعات مهم
      for (final line in body.split("\n")) {
        final l = line.toLowerCase();

        if (l.startsWith("registrant organization:") ||
            l.startsWith("org:") ||
            l.startsWith("owner:")) {
          registrant = line.split(":").sublist(1).join(":").trim();
        }

        if (l.startsWith("registrar:")) {
          registrar = line.split(":").sublist(1).join(":").trim();
        }

        if (l.startsWith("creation date:") ||
            l.startsWith("registered on:")) {
          created = line.split(":").sublist(1).join(":").trim();
        }

        if (l.startsWith("registry expiry date:") ||
            l.startsWith("expiry date:")) {
          expires = line.split(":").sublist(1).join(":").trim();
        }
      }
    } catch (e) {
      rawWhois = "Error: $e";
    }

    setState(() => isLoading = false);
  }

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
      child: Row(
        children: [
          Icon(icon, color: Colors.cyan, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: "monospace",
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 1,
                  color: Colors.cyan.withOpacity(0.25),
                  margin: const EdgeInsets.only(bottom: 8),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontSize: 15,
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

  Widget rawCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: SingleChildScrollView(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.cyan,
              fontFamily: "monospace",
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(title: const Text("WHOIS Lookup")),
        const Divider(),
      ],
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Input + Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: domainController,
                    placeholder: const Text("Enter domain (e.g. google.com)"),
                  ),
                ),
                const SizedBox(width: 12),
                Button(
                  onPressed: isLoading ? null : runWhois,
                  style: isLoading
                      ? ButtonStyle.secondary()
                      : ButtonStyle.primary(),
                  child: Text(isLoading ? "Loading..." : "Lookup"),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                children: [
                  infoCard("Registrant", registrant, Icons.person),
                  infoCard("Registrar", registrar, Icons.business),
                  infoCard("Created On", created, Icons.calendar_month),
                  infoCard("Expires On", expires, Icons.timer_off),

                  const SizedBox(height: 10),

                  // Raw WHOIS
                  rawCard(rawWhois),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}