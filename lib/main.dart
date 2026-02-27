import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'pages/home_page.dart';

void main() {
  runApp(
    ShadcnApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorSchemes.darkSlate.teal,
        radius: 0.8,
      ),
      home: const HomePage(),
    ),
  );
}