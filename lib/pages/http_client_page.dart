import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shadcn_flutter/shadcn_flutter.dart';

class HttpClientPage extends StatefulWidget {
  const HttpClientPage({super.key});

  @override
  State<HttpClientPage> createState() => _HttpClientPageState();
}

class _HttpClientPageState extends State<HttpClientPage> {
  final TextEditingController urlController = TextEditingController();
  final TextEditingController rawBodyController = TextEditingController();

  List<MapEntry<String, String>> headers = [];
  List<MapEntry<String, String>> bodyFields = [];

  String method = "GET";
  String bodyMode = "raw"; // raw / form
  String responseText = "";
  int? statusCode;

  bool isLoading = false;

  final List<String> methods = ["GET", "POST", "PUT", "DELETE"];
  final List<String> bodyModes = ["raw", "form"];

  // --- NEW: Scroll controllers for response viewer ---
  late final ScrollController _responseVerticalController;
  late final ScrollController _responseHorizontalController;

  @override
  void initState() {
    super.initState();
    // init scroll controllers
    _responseVerticalController = ScrollController();
    _responseHorizontalController = ScrollController();
  }

  @override
  void dispose() {
    // dispose controllers
    _responseVerticalController.dispose();
    _responseHorizontalController.dispose();
    urlController.dispose();
    rawBodyController.dispose();
    super.dispose();
  }

  // CLEAR LOGS
  void clearLogs() {
    setState(() {
      responseText = "";
      statusCode = null;
    });
  }

  // SEND REQUEST
  Future<void> sendRequest() async {
    final url = urlController.text.trim();
    if (url.isEmpty) {
      setState(() => responseText = "❌ URL cannot be empty");
      return;
    }

    setState(() {
      isLoading = true;
      responseText = "";
      statusCode = null;
    });

    try {
      final uri = Uri.parse(url);

      final headerMap = {for (var h in headers) h.key: h.value};

      http.Response res;

      dynamic bodyToSend;

      if (bodyMode == "raw") {
        bodyToSend = rawBodyController.text;
      } else {
        bodyToSend = {for (var f in bodyFields) f.key: f.value};
      }

      switch (method) {
        case "POST":
          res = await http.post(uri, headers: headerMap, body: bodyToSend);
          break;
        case "PUT":
          res = await http.put(uri, headers: headerMap, body: bodyToSend);
          break;
        case "DELETE":
          res = await http.delete(uri, headers: headerMap, body: bodyToSend);
          break;
        default:
          res = await http.get(uri, headers: headerMap);
      }

      setState(() {
        statusCode = res.statusCode;

        try {
          final jsonBody = const JsonEncoder.withIndent(
            "  ",
          ).convert(json.decode(res.body));
          responseText = jsonBody;
        } catch (_) {
          responseText = res.body;
        }
      });
    } catch (e) {
      setState(() => responseText = "❌ Error: $e");
    }

    setState(() => isLoading = false);
  }

  // HEADER ROW
  Widget headerRow(int index) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            // جایگزین InputDecoration(hintText: "Key")
            placeholder: const Text("Key"),
            controller: TextEditingController(text: headers[index].key),
            onChanged: (v) =>
                headers[index] = MapEntry(v, headers[index].value),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            // جایگزین InputDecoration(hintText: "Value")
            placeholder: const Text("Value"),
            controller: TextEditingController(text: headers[index].value),
            onChanged: (v) => headers[index] = MapEntry(headers[index].key, v),
          ),
        ),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.red.shade400),
          onPressed: () => setState(() => headers.removeAt(index)),
          variance: ButtonStyle.destructive(),
        ),
      ],
    );
  }

  // BODY FIELD ROW (Key–Value)
  Widget bodyFieldRow(int index) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            placeholder: const Text("Key"),
            controller: TextEditingController(text: bodyFields[index].key),
            onChanged: (v) =>
                bodyFields[index] = MapEntry(v, bodyFields[index].value),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            placeholder: const Text("Value"),
            controller: TextEditingController(text: bodyFields[index].value),
            onChanged: (v) =>
                bodyFields[index] = MapEntry(bodyFields[index].key, v),
          ),
        ),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.red.shade400),
          onPressed: () => setState(() => bodyFields.removeAt(index)),
          variance: ButtonStyle.destructive(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: const [
        AppBar(title: Text("HTTP Client (Mini Postman)")),
        Divider(),
      ],
      child: Container(
        color: Colors.black,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // METHOD + URL
            Row(
              children: [
                SizedBox(
                  width: 140,
                  child: Select<String>(
                    value: method,
                    onChanged: (v) => setState(() => method = v!),
                    itemBuilder: (context, item) => Text(item),
                    popup: SelectPopup(
                      items: SelectItemList(
                        children: methods
                            .map(
                              (m) => SelectItemButton(value: m, child: Text(m)),
                            )
                            .toList(),
                      ),
                    ).call,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: urlController,
                    placeholder: const Text("Enter URL (https://...)"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // HEADERS
            Row(
              children: [
                const Text("Headers", style: TextStyle(color: Colors.cyan)),
                const Spacer(),
                Button(
                  style: ButtonStyle.secondary(),
                  onPressed: () =>
                      setState(() => headers.add(const MapEntry("", ""))),
                  child: const Text("Add Header"),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (headers.isEmpty)
              Text(
                "No headers added",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.54),
                  fontFamily: "monospace",
                ),
              ),

            ...List.generate(headers.length, (i) => headerRow(i)),

            const SizedBox(height: 16),

            // BODY MODE SELECTOR
            if (method != "GET")
              Row(
                children: [
                  const Text(
                    "Body Mode:",
                    style: TextStyle(color: Colors.cyan),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 160,
                    child: Select<String>(
                      value: bodyMode,
                      onChanged: (v) => setState(() => bodyMode = v!),
                      itemBuilder: (context, item) =>
                          Text(item == "raw" ? "Raw Body" : "Key–Value"),
                      popup: SelectPopup(
                        items: SelectItemList(
                          children: [
                            SelectItemButton(
                              value: "raw",
                              child: const Text("Raw Body"),
                            ),
                            SelectItemButton(
                              value: "form",
                              child: const Text("Key–Value"),
                            ),
                          ],
                        ),
                      ).call,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // BODY CONTENT
            if (method != "GET")
              if (bodyMode == "raw")
                // قبلاً: decoration: InputDecoration.collapsed(hintText: "JSON or raw body...")
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.cyan.withOpacity(0.4)),
                  ),
                  child: TextField(
                    controller: rawBodyController,
                    maxLines: 6,
                    // جایگزین InputDecoration.collapsed
                    placeholder: const Text("JSON or raw body..."),
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              else
                Column(
                  children: [
                    if (bodyFields.isEmpty)
                      Text(
                        "No body fields added",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.54),
                          fontFamily: "monospace",
                        ),
                      ),
                    ...List.generate(bodyFields.length, (i) => bodyFieldRow(i)),
                    const SizedBox(height: 8),
                    Button(
                      style: ButtonStyle.secondary(),
                      onPressed: () => setState(
                        () => bodyFields.add(const MapEntry("", "")),
                      ),
                      child: const Text("Add Field"),
                    ),
                  ],
                ),

            const SizedBox(height: 16),

            // SEND BUTTON
            Button(
              onPressed: isLoading ? null : sendRequest,
              style: ButtonStyle.primary(),
              child: Text(isLoading ? "Sending..." : "Send Request"),
            ),

            const SizedBox(height: 16),

            // RESPONSE + CLEAR BUTTON
            Row(
              children: [
                const Text(
                  "Response",
                  style: TextStyle(color: Colors.cyan, fontFamily: "monospace"),
                ),
                const Spacer(),
                Button(
                  style: ButtonStyle.destructive(),
                  onPressed: clearLogs,
                  child: const Text("Clear Logs"),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // RESPONSE VIEWER (scrollable + selectable) with explicit controllers
            Container(
              height: 320,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withOpacity(0.4)),
              ),
              child: responseText.isEmpty
                  ? const Text(
                      "Response will appear here...",
                      style: TextStyle(
                        color: Colors.cyan,
                        fontFamily: "monospace",
                      ),
                    )
                  : Scrollbar(
                      controller: _responseVerticalController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _responseVerticalController,
                        scrollDirection: Axis.vertical,
                        child: Scrollbar(
                          controller: _responseHorizontalController,
                          thumbVisibility: true,
                          notificationPredicate: (notification) =>
                              notification.metrics.axis == Axis.horizontal,
                          child: SingleChildScrollView(
                            controller: _responseHorizontalController,
                            scrollDirection: Axis.horizontal,
                            child: SelectableText(
                              responseText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: "monospace",
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
