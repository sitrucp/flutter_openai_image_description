// settings_page.dart

import 'package:flutter/material.dart';
import 'data_storage.dart';

class SettingsPage extends StatefulWidget {
  // Add a callback function parameter
  final VoidCallback onAllImageDataDeleted;

  // Update the constructor to require the callback function
  const SettingsPage({super.key, required this.onAllImageDataDeleted});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final TextEditingController _openAIKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getOpenAIKey(); // load key into form
  }

  Future<void> _getOpenAIKey() async {
    final dataStorage = DataStorage();
    String? openAIKey = await dataStorage.getOpenAIKey();
    setState(() {
      _openAIKeyController.text = openAIKey!;
    });
  }

  Future<void> _setOpenAIKey() async {
    final dataStorage = DataStorage();
    await dataStorage.setOpenAIKey(_openAIKeyController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key saved.')),
      );
    }
  }

  void _confirmDeleteOpenAIKey() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          //title: const Text('Confirm'),
          content: const Text('Confirm deletion of API key.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pop(), // Dismiss the dialog without doing anything
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Clear all data
                _deleteOpenAIKey();
                // Close the dialog
                Navigator.of(context).pop();
                // Trigger the refresh UI callback
                //widget.onAllImageDataDeleted();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteOpenAIKey() async {
    final dataStorage = DataStorage();
    await dataStorage.deleteOpenAIKey();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key deleted.')),
      );
      // Clear the form field TextEditingController
      setState(() {
        _openAIKeyController.clear();
      });
      // Invoke the callback to notify that the reset is complete
      widget.onAllImageDataDeleted();
    }
  }

  void _confirmdeleteAllImageData() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          //title: const Text('Confirm'),
          content: const Text('Confirm deletion of all image data.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pop(), // Dismiss the dialog without doing anything
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Clear all data
                _deleteAllImageData();
                // Close the dialog
                Navigator.of(context).pop();
                // Trigger the refresh UI callback
                //widget.onAllImageDataDeleted();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAllImageData() async {
    final dataStorage = DataStorage();
    await dataStorage.deleteAllImageData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All image data deleted.')),
      );
      // Invoke image gallery callback to notify that the reset is complete
      widget.onAllImageDataDeleted();
    }
  }

  void _confirmExportJSONData() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          //title: const Text('Confirm'),
          content: const Text('Confirm data export.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pop(), // Dismiss the dialog without doing anything
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _exportJsonData(); // Clear all data
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportJsonData() async {
    final dataStorage = DataStorage();
    await dataStorage.exportAndShareJsonFile();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export data.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            const Text(
              "You have to provide your own OpenAI API key which will be safely encrypted and stored on your device and is not shared except when it is sent using https secure transmission to the API for authentication.\n\n"
              "Learn about the OpenAI API at https://platform.openai.com",
            ),
            const SizedBox(height: 20),
            Semantics(
              label: 'Enter API key here',
              child: TextFormField(
                controller: _openAIKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Enter API key here',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Tooltip(
              message: 'Save API key',
              child: ElevatedButton(
                onPressed: _setOpenAIKey,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 50), // Custom height
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                ),
                child: const Text('Save API key'),
              ),
            ),
            const SizedBox(height: 20),
            Tooltip(
              message: 'Delete API key',
              child: ElevatedButton(
                onPressed: _confirmDeleteOpenAIKey,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 50), // Custom height
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                ),
                child: const Text('Delete API key'),
              ),
            ),
            const SizedBox(height: 20),
            Tooltip(
              message: 'Delete all image data',
              child: ElevatedButton(
                onPressed: _confirmdeleteAllImageData,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 50), // Custom height
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                ),
                child: const Text('Delete all image data'),
              ),
            ),
            const SizedBox(height: 20),
            Tooltip(
              message: 'Export all image data',
              child: ElevatedButton(
                onPressed: _confirmExportJSONData,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 50), // Custom height
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                ),
                child: const Text('Export all image data'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
