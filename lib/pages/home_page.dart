import 'package:shadcn_flutter/shadcn_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget toolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return CardButton(
      
      onPressed: onTap,
      child: Basic(
        
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          title: const Text("eunix"),
          trailing: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {},
              variance: ButtonStyle.primary(),
            ),
          ],
        ),
        const Divider(),
      ],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Status Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.cloud),
                  SizedBox(width: 8),
                  Text(
                    "Local IP: 192.168.1.42",
                    style: TextStyle(fontFamily: "monospace"),
                  ),
                  Spacer(),
                  Icon(Icons.circle, size: 10, color: Colors.green),
                  SizedBox(width: 6),
                  Text("Ready"),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Network Tools",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                children: [
                  toolCard(
                    icon: Icons.cloud_upload,
                    title: "TCP Client",
                    subtitle: "Create outgoing TCP connection",
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  toolCard(
                    icon: Icons.cloud,
                    title: "TCP Server",
                    subtitle: "Listen for TCP connections",
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  toolCard(
                    icon: Icons.swap_horiz,
                    title: "TCP Proxy",
                    subtitle: "Forward traffic between endpoints",
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  toolCard(
                    icon: Icons.wifi_tethering,
                    title: "UDP Client",
                    subtitle: "Send and receive UDP packets",
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  toolCard(
                    icon: Icons.search,
                    title: "Port Scanner",
                    subtitle: "Scan ports (use with permission)",
                    badge: "Beta",
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Use network tools responsibly. Unauthorized scanning may violate laws.",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}