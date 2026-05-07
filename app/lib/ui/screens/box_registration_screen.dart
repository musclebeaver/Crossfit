import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../styles/app_colors.dart';
import '../../core/api/api_client.dart';

class BoxRegistrationScreen extends StatefulWidget {
  const BoxRegistrationScreen({super.key});

  @override
  State<BoxRegistrationScreen> createState() => _BoxRegistrationScreenState();
}

class _BoxRegistrationScreenState extends State<BoxRegistrationScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _businessNumberController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty || _locationController.text.isEmpty || _businessNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ApiClient().dio.post('/boxes', data: {
        'name': _nameController.text,
        'location': _locationController.text,
        'businessNumber': _businessNumberController.text,
      });

      if (res.data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Box registration application submitted successfully.')));
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint("Box Register Error: $e");
      if (mounted) {
        String message = 'Failed to register box: Connection error';
        if (e is DioException && e.response != null && e.response?.data != null) {
          message = 'Failed to register box: ${e.response?.data['message'] ?? 'Unknown error'}';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Register Your Box', style: TextStyle(color: Color(0xFF115D33), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF115D33)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.business, size: 80, color: Color(0xFF115D33)),
            const SizedBox(height: 24),
            const Text(
              'Apply for Official Box Registration',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Once approved, you can manage members and WODs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF757575)),
            ),
            const SizedBox(height: 48),
            _buildTextField(_nameController, 'Box Name', Icons.drive_file_rename_outline),
            const SizedBox(height: 16),
            _buildTextField(_locationController, 'Location', Icons.location_on),
            const SizedBox(height: 16),
            _buildTextField(_businessNumberController, 'Business Registration Number', Icons.numbers),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF115D33),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit Application', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF757575)),
        prefixIcon: Icon(icon, color: const Color(0xFF115D33)),
        filled: false,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF115D33), width: 1.5)),
      ),
    );
  }
}
