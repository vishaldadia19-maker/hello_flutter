import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/user_session.dart';

class FolderSetupScreen extends StatefulWidget {
  const FolderSetupScreen({super.key});

  @override
  State<FolderSetupScreen> createState() => _FolderSetupScreenState();
}

class _FolderSetupScreenState extends State<FolderSetupScreen> {
  String? folderPath;
  bool isSaving = false;

  int get userId => UserSession.bdmId ?? 0;

  @override
  void initState() {
    super.initState();
    loadSavedPath();
  }

  // 🔹 Load existing saved folder
  Future<void> loadSavedPath() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      folderPath = prefs.getString('recording_folder');
    });
  }

  // 🔹 Pick folder
  Future<void> pickFolder() async {
    String? path = await FilePicker.platform.getDirectoryPath();

    if (path != null) {
      setState(() {
        folderPath = path;
      });
    }
  }

  // 🔹 Save to DB + local
  Future<void> saveFolderPath() async {
    if (folderPath == null || folderPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a folder")),
      );
      return;
    }

    if (userId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      var response = await http.post(
        Uri.parse('https://backoffice.thecubeclub.co/apis/update_recording_path.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "file_path": folderPath,
        }),
      );

      print("SAVE STATUS: ${response.statusCode}");
      print("SAVE BODY: ${response.body}");

      var data = jsonDecode(response.body);

      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('recording_folder', folderPath!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Folder saved successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Failed to save")),
        );
      }
    } catch (e) {
      print("ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    }

    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Recording Folder"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 📁 Folder Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                folderPath ?? "No folder selected",
                style: const TextStyle(fontSize: 13),
              ),
            ),

            const SizedBox(height: 15),

            /// 🔘 Select Folder
            ElevatedButton(
              onPressed: pickFolder,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Select Folder"),
            ),

            const SizedBox(height: 10),

            /// 💾 Save Button
            ElevatedButton(
              onPressed: isSaving ? null : saveFolderPath,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
              ),
              child: Text(isSaving ? "Saving..." : "Save Folder"),
            ),
          ],
        ),
      ),
    );
  }
}
