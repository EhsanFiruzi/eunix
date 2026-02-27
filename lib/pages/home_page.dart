import 'package:shadcn_flutter/shadcn_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        // Use Shadcn AppBar in the Scaffold header area.
        AppBar(title: Text('Shadcn Home Page')),
        // A divider beneath the AppBar to separate header and body.
        Divider(),
      ],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CardButton(
              onPressed: () {},
              child: const Basic(
                leading: Icon(Icons.wifi),
                title: Text('TCP Client'),
                subtitle: Text('project description'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CardButton(
              onPressed: () {},
              child: const Basic(
                leading: Icon(Icons.wifi),
                title: Text('UDP Client'),
                subtitle: Text('project description'),
              ),
            ),
          ),
           Padding(
            padding: const EdgeInsets.all(8.0),
            child: CardButton(
              onPressed: () {},
              child: const Basic(
                leading: Icon(Icons.wifi),
                title: Text('TCP Proxy'),
                subtitle: Text('project description'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CardButton(
              onPressed: () {},
              child: const Basic(
                leading: Icon(Icons.wifi),
                title: Text('TCP Server'),
                subtitle: Text('project description'),
              ),
            ),
          ),
         
        ],
      ),
    );
  }
}