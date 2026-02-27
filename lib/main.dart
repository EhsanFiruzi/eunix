import 'package:eunix/pages/home_page.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  runApp(
    ShadcnApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorSchemes.darkSlate.teal, radius: 0.75),
      home: HomePage(),
    ),
  );
}
