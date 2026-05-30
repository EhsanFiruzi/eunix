import 'dart:convert';
import 'dart:io';

import 'package:shadcn_flutter/shadcn_flutter.dart';

class DnsLookupPage extends StatefulWidget {
  const DnsLookupPage({super.key});

  @override
  State<DnsLookupPage> createState() => _DnsLookupPageState();
}

class _DnsLookupPageState extends State<DnsLookupPage> {
  final TextEditingController domainController = TextEditingController();

  bool isLoading = false;

  List<String> aRecords = [];
  List<String> aaaaRecords = [];
  List<String> mxRecords = [];
  List<String> txtRecords = [];
  List<String> nsRecords = [];
  List<String> cnameRecords = [];

  Future<List<String>> _queryRecord(String name, String type) async {
    final uri = Uri.parse("https://dns.google/resolve?name=$name&type=$type");
    final client = HttpClient();
    final req = await client.getUrl(uri);
    final res = await req.close();

    if (res.statusCode != 200) {
      return ["Error: HTTP ${res.statusCode}"];
    }

    final body = await res.transform(utf8.decoder).join();
    final data = jsonDecode(body);

    if (data["Status"] != 0 || data["Answer"] == null) {
      return ["No records"];
    }

    final List answers = data["Answer"];
    final List<String> result = [];

    for (final ans in answers) {
      final typeCode = ans["type"];
      final value = ans["data"]?.toString() ?? "";

      switch (typeCode) {
        case 1: // A
        case 28: // AAAA
        case 2: // NS
          result.add(value);
          break;
        case 5: // CNAME
          result.add(value);
          break;
        case 15: // MX
          result.add(value);
          break;
        case 16: // TXT
          result.add(value);
          break;
        default:
          result.add(value);
      }
    }

    return result.isEmpty ? ["No records"] : result;
  }

  Future<void> runLookup() async {
    final domain = domainController.text.trim();
    if (domain.isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
      aRecords = [];
      aaaaRecords = [];
      mxRecords = [];
      txtRecords = [];
      nsRecords = [];
      cnameRecords = [];
    });

    try {
      final results = await Future.wait([
        _queryRecord(domain, "A"),
        _queryRecord(domain, "AAAA"),
        _queryRecord(domain, "MX"),
        _queryRecord(domain, "TXT"),
        _queryRecord(domain, "NS"),
        _queryRecord(domain, "CNAME"),
      ]);

      setState(() {
        aRecords = results[0];
        aaaaRecords = results[1];
        mxRecords = results[2];
        txtRecords = results[3];
        nsRecords = results[4];
        cnameRecords = results[5];
      });
    } catch (e) {
      setState(() {
        aRecords = ["Error: $e"];
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Widget recordCard(String title, List<String> values, IconData icon) {
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
          // Header
          Row(
            children: [
              Icon(icon, color: Colors.cyan, size: 24),
              const SizedBox(width: 10),
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

          const SizedBox(height: 8),

          Container(
            height: 1,
            color: Colors.cyan.withOpacity(0.25),
            margin: const EdgeInsets.only(bottom: 8),
          ),

          // Values
          if (values.isEmpty)
            const Text(
              "No records",
              style: TextStyle(
                color: Colors.cyan,
                fontFamily: "monospace",
              ),
            )
          else
            ...values.map(
              (v) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  v,
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontFamily: "monospace",
                    fontSize: 13,
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
          title: const Text("DNS Lookup"),
        ),
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
                  onPressed: isLoading ? null : runLookup,
                  style: isLoading
                      ? ButtonStyle.secondary()
                      : ButtonStyle.primary(),
                  child: Text(isLoading ? "Resolving..." : "Lookup"),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Results
            Expanded(
              child: ListView(
                children: [
                  recordCard("A Records", aRecords, Icons.language),
                  recordCard("AAAA Records", aaaaRecords, Icons.language),
                  recordCard("MX Records", mxRecords, Icons.mail),
                  recordCard("TXT Records", txtRecords, Icons.text_snippet),
                  recordCard("NS Records", nsRecords, Icons.dns),
                  recordCard("CNAME Records", cnameRecords, Icons.link),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}