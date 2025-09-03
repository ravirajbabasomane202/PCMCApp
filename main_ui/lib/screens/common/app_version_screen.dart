import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionScreen extends StatefulWidget {
  const AppVersionScreen({super.key});

  @override
  State<AppVersionScreen> createState() => _AppVersionScreenState();
}

class _AppVersionScreenState extends State<AppVersionScreen> {
  String version = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      version = "${info.version} (Build ${info.buildNumber})";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("App Version")),
      body: Center(
        child: Text("Current Version: $version", style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
